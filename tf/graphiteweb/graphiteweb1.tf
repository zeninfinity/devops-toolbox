provider "aws" {
  access_key = "<access_key>"
  secret_key = "<secret_key>"
  region = "us-west-2"
}

resource "aws_instance" "graphiteweb1" {

  #ami = "ami-1234567890"
  ami = "ami-1234567890"
  instance_type = "m3.medium"
  subnet_id="subnet-1234567890"
  security_groups=["sg-1234567890"]
  key_name="key_name"
  iam_instance_profile = "graphite"

  tags {
    Name = "graphiteweb1"
    Environment = "stats"
  }

}

resource "aws_eip" "ip" {
  instance = "${aws_instance.graphiteweb1.id}"
  vpc = true
  connection {
    user = "ec2-user"
    host = "${aws_eip.ip.public_ip}"
    key_file = "~/.ssh/key_name.pem"
    timeout = "2m"
  }
  provisioner "file" {
    source = "configure.sh"
    destination = "configure.sh"
#    connection {
#      user = "ec2-user"
#      host = "${aws_eip.ip.public_ip}"
#      key_file = "~/.ssh/key_name.pem"
#      timeout = "2m"
#    }
  }
  provisioner "remote-exec" {
#    connection {
#      user = "ec2-user"
#      host = "${aws_eip.ip.public_ip}"
#      key_file = "~/.ssh/key_name.pem"
#      timeout = "2m"
#    }
    inline = [
      "chmod 700 configure.sh",
      "sudo -E ./configure.sh"
    ]
  }
}
