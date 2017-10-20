#!/usr/bin/env ruby
require 'pp'
require 'fileutils'
require 'json'


#VARS
collinsserver="collins-prod.domain.com"
port="8080"

curl="curl -s --basic -u `whoami` \"http://#{collinsserver}:#{port}/api/assets?size=10000\" | grep \"HOSTNAME\\|_0_ADDRESS\""

curljson=JSON.parse(`#{curl}`)
#puts JSON.pretty_generate(curljson)


curljson["data"]["Data"].each do |asset|
ip=""; hn=""; ipmi=""
  #Get IP
  address=asset["ADDRESSES"]
  unless address.empty? 
    address.each do |addinfo|
      ip=addinfo["ADDRESS"]
    end
  end

  #Get Hostname
  attribs=asset["ATTRIBS"]["0"]
  if attribs
    hn=asset["ATTRIBS"]["0"]["HOSTNAME"]
  end

  #Get IPMI Address
  ipmi=asset["IPMI"]["IPMI_ADDRESS"]

  
  #Send to nsupdate
  if !ip.empty? && !hn.empty? && !ipmi.empty?
    #ADD Host A Record
    puts "Adding host #{hn} with IP #{ip} and mgmt host #{hn}-mgmt with IP #{ipmi}"
    #puts "./nsupdate.rb -a -n #{hn}.domain.com -i #{ip}"
    `./nsupdate.rb -a -n #{hn}.domain.com -i #{ip}`

    #ADD mgmt A Record
    #puts "./nsupdate.rb -a -n #{hn}-mgmt.domain.com -i #{ipmi}\n\n"
    `./nsupdate.rb -a -n #{hn}-mgmt.domain.com -i #{ipmi}`
  end
end
