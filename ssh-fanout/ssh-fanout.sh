#!/usr/bin/env ruby
require 'net/sftp'
require 'net/ssh'

user="user"

#get ips array
ips=File.readlines('ips.txt')

# for each ip in array
ips.each { |ip| 
  ip=ip.strip
  puts "sftp example.repo file"
  sftp = Net::SFTP.start(ip, user, keys: ["~/.ssh/id_rsa"])
  sftp.upload! "example.repo", "example.repo"

  puts "SSHing to #{ip}"
  Net::SSH.start(ip, user, keys: ["~/.ssh/id_rsa"]) do |ssh|
    commands=File.readlines('commands.txt')
    commands.each { |com|
                 
          ssh.open_channel do |channel|
            channel.request_pty do |ch , success|
              raise "I can't get pty rquest" unless success
              ch.exec(com)
              ch.on_data do |ch , data|
                data.inspect
                if data.inspect.include? "[sudo]"
                  channel.send_data(pass+"\n")
                  sleep 20
                else
                  data = data.strip
                  #com.data << data if data.size > 0
                end
                ch.wait
              end
              channel.on_eof do |ch|
                puts "Running: #{com}:\n"
              end
            end
          end
        ssh.loop
    }
  end
}
