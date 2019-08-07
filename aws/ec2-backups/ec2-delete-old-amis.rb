#!/usr/bin/env ruby

require File.expand_path('./instance-list.rb', File.dirname(__FILE__))

date=`date "+%Y%m%d-%H%M"`
output=""

$ec2ids.each do |id, reg|
  #Get amis with correct naming convention
  #Get amis timestamp
  #get list of amis that are older than x time
  #delete amis 



end
exit



#OLDCODE
  name=`aws ec2 describe-instances --instance-ids #{id} --region #{reg} --query "Reservations[*].Instances[*].Tags[?Key=='Name'].Value" --output text`
  command="aws ec2 create-image --instance-id #{id} --region #{reg} --name #{name.chomp}-backup-#{date.chomp} --no-reboot"
  puts "Creating AMI backup \n  instance id:#{id} \n  region:#{reg} \n  name:#{name}"
  puts "  Command: #{command}"
  output=`#{command}`
  puts "  Output: #{output}"
  puts " "
end
