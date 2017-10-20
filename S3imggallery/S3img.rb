#!/usr/bin/ruby

#REQ
require 'rubygems'
require 'rack'
require 's3'
require 'pp'
require File.expand_path('./auth_keys.rb', File.dirname(__FILE__))
require File.expand_path('./vars.rb', File.dirname(__FILE__))
require 'benchmark'

#CLASS
class AWS_S3

  def s3_connect()
    s3conn = S3::Service.new(:access_key_id => $access_key_id, :secret_access_key => $secret_access_key)
    return s3conn
  end

  def find_bucket(s3conn, bucket)
    share_bucket=s3conn.buckets.find(bucket)
    return share_bucket
  end

  def get_pngs(s3conn, bucket, prefix)
    share_bucket=s3conn.buckets.find(bucket)
    pngs=share_bucket.objects(prefix:prefix).sort_by( &:last_modified).reverse
    return pngs
  end

end

class HTMLOutput

  def html_head()
    return "<html>\n<head><link rel=\"stylesheet\" type=\"text/css\" href=\"/css/img.css\"></head><body>\n\n"
  end

  def html_body(share_bucket, pngs)
    html_out=""
    pngs.select{|check| check.key.downcase.include?"#{$ft}"}.each do |png|
      html_out+="<div class=\"img\"><a href=\"#{$domain}/#{share_bucket.name}/#{png.key}\"><img src=\"#{$domain}/#{share_bucket.name}/#{png.key}\"></a><div class=\"desc\"><a href=\"#{$domain}/#{share_bucket.name}/#{png.key}\">#{png.key}</a></div></div>\n\n"
    end
    return html_out
  end

end

Rack::Handler::Thin.run(Rack::Builder.new {
    map "/" do
      #connect to S3
      s3conn=AWS_S3.new.s3_connect
      share_bucket=AWS_S3.new.find_bucket(s3conn, "#{$bucket}")
      pngs=AWS_S3.new.get_pngs(s3conn, "#{$bucket}", "#{$folder}") #Slow Process
      $html=HTMLOutput.new.html_head
      $html+=HTMLOutput.new.html_body(share_bucket, pngs)
      run ->env{[200, {}, ["#{$html}"]]}
    end
    map "/css/" do
      use Rack::Static, 
      :urls => [""], :root => "."
      run ->env{[200, {}, [File.read("img.css")]]}  #ugly, I know.
    end
}, Port: 9292)
