#!/bin/bash
#
# This is a generic userdata script that can be attached to a launch configuration of an autoscaling group. It handles 
# tagging the instance, creating any required disks (encrypted), and installing/running puppet.
#
# This is currently untested and will likely require tweaks over time. Please improve as a base launch config as you see fit
#
# Author: Matthew Knox

##################################
#SET THIS IN THE LAUNCH CONFIG!!!#
##################################
ENVIRONMENT=`/opt/aws/bin/ec2-describe-tags --region $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone  | sed -e "s/.$//") --filter resource-id=$(curl --silent http://169.254.169.254/latest/meta-data/instance-id) | grep Environment | awk {'print $5'}`
SERVERROLE=`/opt/aws/bin/ec2-describe-tags --region $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone  | sed -e "s/.$//") --filter resource-id=$(curl --silent http://169.254.169.254/latest/meta-data/instance-id) | grep Name | awk {'print $5'}`
#dataDisk=("xvdf" "100" "ext4" "/data")
#DISKS=(dataDisk mediaDisk)

#################################
# Functions for disk creation   #
#################################
function checkMountAttached
{
    mountPoint=$1
    volStatus=`ec2-describe-volumes --region ${REGION} --filter "attachment.instance-id=${INSTANCE_ID}"|grep ${mountPoint}|awk {'print $5'}`
    while [ $volStatus != "attached" ]; do
        echo "Volume status ($mountPoint): $volStatus "
        volStatus=`ec2-describe-volumes --region ${REGION} --filter "attachment.instance-id=${INSTANCE_ID}"|grep ${mountPoint}|awk {'print $5'}`
        sleep 1
    done
    echo "Volume ${mountPoint} attached, continuing..."
}

function checkVolumeAvailable
{
    checkVolumeID=$1
    volStatus=`ec2-describe-volumes --region ${REGION}|grep ${checkVolumeID}|grep VOLUME|awk {'print $5'}`
    while [ $volStatus != "available" ]; do
        echo "Volume status ($checkVolumeID): $volStatus "
        volStatus=`ec2-describe-volumes --region ${REGION}|grep ${checkVolumeID}|grep VOLUME|awk {'print $5'}`
        sleep 1
    done
    echo "Volume ${checkVolumeID} available, continuing..."
}

function checkVolumeDetached
{
    checkVolumeID=$1
    volStatus=`ec2-describe-volumes --region ${REGION}|grep ${checkVolumeID}|grep VOLUME|awk {'print $6'}`
    while [ $volStatus != "available" ]; do
        echo "Volume status: $volStatus "
        volStatus=`ec2-describe-volumes --region ${REGION}|grep ${checkVolumeID}|grep VOLUME|awk {'print $6'}`
        sleep 1
    done
    echo "Volume ${checkVolumeID} detached, continuing..."
}

#########################
#         MAIN          #
#########################
echo "Starting at `date`"

#Create the gettags.sh script
cat > /root/gettags.sh <<'EOS'
#!/bin/bash
source /etc/profile.d/aws-apitools-common.sh
instanceid=$1
region=$2
/opt/aws/bin/ec2dtag --filter resource-id="$instanceid" --region "$region" | /bin/cut -f 4-|/bin/awk 'BEGIN{FS=" ";OFS="|"} {$1=$1; print $0}'
EOS
chmod a+x /root/gettags.sh

#make sure the latest version of aws tools are installed
#some commands rely on a later version than what is
#installed on some AMIs
yum update aws-apitools* aws-cli* -y
. /etc/profile.d/aws-apitools-common.sh

#Gather some basic information about the machine that was launched from the AWS apis
INSTANCE_ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
INSTANCE_ID_SANS_I=`curl -s http://169.254.169.254/latest/meta-data/instance-id|awk -F '-' {'print $2'}`
REGION=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}'`
AZ=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document|grep availabilityZone|awk -F\" '{print $4}'`
INTERNAL_IP=`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`
ORIGNAME=`/opt/aws/bin/ec2-describe-tags --region $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone  | sed -e "s/.$//") --filter resource-id=$(curl --silent http://169.254.169.254/latest/meta-data/instance-id) | grep Name | awk {'print $5'}`

#Determine the short AZ name for the AZ that this machine is in
SHORTAZ=`echo $AZ  | sed 's/us-\(.\).*-\(.*\)/\1\2/g'`

#Set some tags on the newly created machine
NEWHOSTNAME="${ENVIRONMENT}-${SERVERROLE}-${SHORTAZ}-${INSTANCE_ID_SANS_I}"
rootVolumeID=`ec2-describe-volumes --region ${REGION}|grep ${INSTANCE_ID} |grep xvda|awk {'print $2'}`
echo "Setting tags..."
ec2-create-tags ${INSTANCE_ID} --region ${REGION}  -t "Name=${NEWHOSTNAME}" -t "ServerRole=${SERVERROLE}"
ec2-create-tags --region ${REGION} ${rootVolumeID} --tag "Name=root_${INSTANCE_ID}"

#Set the hostname
echo "Setting the hostname..."
hostname ${NEWHOSTNAME}
sed -i -e "s/HOSTNAME=.*/HOSTNAME=${NEWHOSTNAME}.${REGION}.compute.internal/" /etc/sysconfig/network
echo "127.0.0.1 localhost localhost.localdomain ${NEWHOSTNAME}" > /etc/hosts


#Configure any disks that are defined.
#TODO: Config validation?
for disk_id in `seq 0 $(( ${#DISKS[@]} - 1 ))`
do
   disk=`eval echo "\${DISKS[$disk_id]}"`
   device=$(eval echo "\${${disk}[0]}")
   size=$(eval echo "\${${disk}[1]}")
   fs=$(eval echo "\${${disk}[2]}")
   mntpnt=$(eval echo "\${${disk}[3]}")

   volumeID=`ec2-create-volume -s $size -t gp2 --encrypted -z ${AZ} --region ${REGION}|awk {'print $2'}`
   checkVolumeAvailable ${volumeID}
   ec2-attach-volume ${volumeID} -i ${INSTANCE_ID} -d $device --region ${REGION}
   checkMountAttached $device

   #TODO: Handle other filesystem types
   fs="ext4"
   mkfs.ext4 /dev/$device

   mkdir -fp  $mntpnt
   echo "/dev/$device  $mntpnt        $fs     nobarrier,noatime 0 2" >>/etc/fstab
   mount $mntpnt
done


#Configure and start puppet
yum install -y puppet3 facter2

cat > /etc/puppet/puppet.conf<<"EOC"
[main]
    logdir  = /var/log/puppet
    rundir  = /var/run/puppet
    ssldir  = $vardir/ssl
    reports = none

[agent]
    classfile = $vardir/classes.txt
    localconfig = $vardir/localconfig
    server = PUPPETSERVER
    environment = PUPPETENV
EOC

PUPPET_MASTER="puppetmaster3.company.com"
PUPPET_ENV="dev3"
case "$ENVIRONMENT" in
	'ci' | 'tst' | 'stats' )
		PUPPET_ENV="dev3"
	;;
	'qa' )
		PUPPET_ENV="qa3"
	;;
	'beta' )
		PUPPET_ENV="prod3"
	;;
	'stg' )
		PUPPET_ENV="prod3"
	;;
	'prd' | 'prod' )
		PUPPET_ENV="prod3"
		PUPPET_MASTER="puppetmaster3.company.com"
	;;
esac

sed -i -e "s/PUPPETSERVER/$PUPPET_MASTER/g" /etc/puppet/puppet.conf
sed -i -e "s/PUPPETENV/$PUPPET_ENV/g" /etc/puppet/puppet.conf

puppet agent -t
wget -q --no-check-certificate -O - "https://$PUPPET_MASTER:3400/sethostname.php?awsid=${INSTANCE_ID}&avzo=${AZ}&currenthost=${NEWHOSTNAME}&secretToken=12312312312312321l"
sleep 60

chkconfig puppet on
service puppet start

echo "Killing ec2-user processes, othewise puppet will fail."
killall -u ec2-user
