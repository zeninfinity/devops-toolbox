#!/usr/bin/ruby

#REQ
require 'rubygems'
require 'rack'
require 's3'
require 'pp'

require File.expand_path('./vars.rb', File.dirname(__FILE__))

$access_key_id=open($envfile).grep(/AWSAccessKeyId=/)[0].split("=")[1].chomp
$secret_access_key=open($envfile).grep(/AWSSecretKey=/)[0].split("=")[1].chomp

#require File.expand_path('./auth_keys.rb', File.dirname(__FILE__))

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
    return "<html>\n<head><link rel=\"stylesheet\" type=\"text/css\" href=\"/css/img.css\"></head><body class=\"no-touch\">\n\n"
  end

  def html_body(share_bucket, pngs)
    html_out=""
    pngs.select{|check| check.key.downcase.include?"#{$ft}"}.each do |png|
      html_out+="    <div class=\"box\">
      <div class=\"boxInner\">
        <a href=\"#{$domain}/#{share_bucket.name}/#{png.key}\"><img src=\"#{$domain}/#{share_bucket.name}/#{png.key}\" /></a>
        <div class=\"titleBox\">#{png.key.split("/")[1]}</div>
      </div>
    </div>"
      html_out+="<script type=\"text/javascript\" src=\"http://code.jquery.com/jquery-1.8.3.js\"></script>
  <script type=\"text/javascript\">
  $(function(){
     // See if this is a touch device
     if ('ontouchstart' in window)
     {
        // Set the correct body class
        $('body').removeClass('no-touch').addClass('touch');
       
        // Add the touch toggle to show text
        $('div.boxInner img').click(function(){
           $(this).closest('.boxInner').toggleClass('touchFocus');
        });
     }
  });
  </script>
  
</body> 
</html>\n\n"
    end
    return html_out
  end

end

Rack::Handler::Thin.run(Rack::Builder.new {
use Rack::Auth::Basic, "Hello, World" do |username, password|
  'tv4life' == password
end
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
      :urls => ["/css/"], :root => "/"
      run ->env{[200, {},  File.open("#{$basedir}/img.css", File::RDONLY)]}
    end
}, Host: '0.0.0.0', Port: 9292)
