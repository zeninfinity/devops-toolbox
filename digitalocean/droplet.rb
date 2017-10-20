#!/usr/bin/env ruby
require 'optparse'

##IMPORT VARS
dir=File.expand_path(File.dirname(__FILE__))
load "#{dir}/defaults.rb"

  $banner = "Example: \n
    Create Droplet:	droplet.rb -c -h <hostname>
    Delete Droplet:	droplet.rb -d -h <hostname>
    List Droplet:	droplet.rb -l\n\n"

#OPTIONS
options = {}
opts=OptionParser.new do |opts|
  opts.on("-c", "--create", "Create Droplet") do |v|
    options[:create] = v
  end

  opts.on("-d", "--delete", "Delete Droplet") do |v|
    options[:delete] = v
  end

  opts.on("-l", "--list", "List Droplets") do |v|
    options[:list] = v
  end

  opts.on("-h", "--hostname hostname", "Hostname") do |v|
    options[:host] = v
  end

  opts.on("-s", "--serverid serverid", "Server ID") do |v|
    options[:serverid] = v
  end

end.parse!

#CHECKVAR
if !options[:list] && !options[:create] && !options[:delete]
  puts $banner
  exit
end 

if options[:list]
  system("cd #{$chefdir}; knife digital_ocean droplet list")
end

if options[:create] 
  if !options[:host]
     puts"No Hostname Defined.  Exiting..."
     puts $banner
     exit
  else 
    hostname=options[:host]
    puts "cd #{$chefdir}; knife digital_ocean droplet create --server-name #{hostname} --image 10325922 --location sfo1 --size 512mb --ssh-keys 593191"
    system("cd #{$chefdir}; knife digital_ocean droplet create --server-name #{hostname} --image 10325922 --location sfo1 --size 512mb --ssh-keys 593191")
  end
end

if options[:delete] 
  if !options[:serverid]
     puts"No Server ID Defined.  Exiting..."
     puts $banner
     exit
  else 
    serverid=options[:serverid]
    system("cd #{$chefdir}; knife digital_ocean droplet destroy -S #{serverid}")
  end
end

#OpsParser
#-c=create
#-d=delete
#--size - 1=512bm, 2=1gb, ...    DEFAULT=512mb
#--server-name = NEEDED or exit
#--image - 1=6372321  ...  DEFAULT=6372321
#--location=sfo1 ... DEFAULT=sfo1
#--ssh-keys=593191  ... DEFAULT=593191
