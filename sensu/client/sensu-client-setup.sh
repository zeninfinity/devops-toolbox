#!/bin/bash

#Vars
ENV="staging"
INSTANCE_ID=`curl -sS http://169.254.169.254/latest/meta-data/instance-id | awk -F "-" {'print $2'}`
SENSUHOSTNAME="host-${ENV}-${INSTANCE_ID}"
ADDRESS=`curl http://169.254.169.254/latest/meta-data/local-ipv4`

#Install sensu and dependencies
echo '[sensu]
name=sensu
baseurl=https://sensu.global.ssl.fastly.net/yum/6/x86_64/
gpgkey=https://repositories.sensuapp.org/yum/pubkey.gpg
gpgcheck=1
enabled=1' | sudo tee /etc/yum.repos.d/sensu.repo
sudo yum -y install sensu
sudo chown -R sensu:sensu /opt/sensu
sudo -u sensu sensu-install -p cpu-checks
sudo -u sensu sensu-install -p uptime-checks
sudo -u sensu sensu-install -p process-checks
sudo -u sensu sensu-install -p http
sudo -u sensu sensu-install -p filesystem-checks
sudo -u sensu sensu-install -p memory-checks
sudo -u sensu sensu-install -p disk-checks
sudo -u sensu sensu-install -p load-checks
sudo -u sensu sensu-install -p network-checks
sudo mkdir /etc/sensu/conf.d

#Setup client.json
echo "{
  \"client\": {
    \"name\": \"$SENSUHOSTNAME\",
    \"address\": \"$ADDRESS\",
    \"environment\": \"$ENV\",
    \"subscriptions\": [
      \"$ENV\"
    ]
  }
}" | sudo tee /etc/sensu/conf.d/client.json

#Setup transport.json
echo "
{
    \"transport\": {
        \"name\": \"rabbitmq\",
        \"reconnect_on_error\": true
    }
}
"| sudo tee /etc/sensu/conf.d/transport.json

#Setup rabbit.json
echo "
{
  \"rabbitmq\": {
    \"host\": \"SENSUHOSTIP\",
    \"port\": 5672,
    \"vhost\": \"/sensu\",
    \"user\": \"sensu\",
    \"password\": \"SECRET\",
    \"heartbeat\": 30,
    \"prefetch\": 50
  }
}" | sudo tee /etc/sensu/conf.d/rabbitmq.json

sudo chown -R sensu:sensu /etc/sensu/conf.d
sudo chkconfig sensu-client on
sudo service sensu-client restart
