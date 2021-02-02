provider "aws" {

  access_key = "<access_key>"
  secret_key = "<secret_key"
  region = "us-west-2"

}

resource "aws_instance" "graphitecache1" {

  ami = "ami-12345678990"
  instance_type = "m4.large"
  subnet_id="subnet-1234567890"
  security_groups=["sg-12345678900"]
  key_name="key_name"
  iam_instance_profile = "graphite"

  tags {
    Name = "graphitecache1"
    Environment = "stats"
  }
}

resource "aws_eip" "ip" {

  instance = "${aws_instance.graphitecache1.id}"
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
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 700 configure.sh",
      "sudo -E ./configure.sh"
    ]
  }
}

resource "aws_instance" "graphitecache2" {

  ami = "ami-1234567890"
  instance_type = "m4.large"
  subnet_id="subnet-1234567890"
  security_groups=["sg-1234567890"]
  key_name="key_name"
  iam_instance_profile = "graphite"

  tags {
    Name = "graphitecache2"
    Environment = "stats"
  }
}

resource "aws_eip" "ip2" {

  instance = "${aws_instance.graphitecache2.id}"
  vpc = true

  connection {
    user = "ec2-user"
    host = "${aws_eip.ip2.public_ip}"
    key_file = "~/.ssh/key_name.pem"
    timeout = "2m"
  }

  provisioner "file" {
    source = "configure.sh"
    destination = "configure.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 700 configure.sh",
      "sudo -E ./configure.sh"
    ]
  }
}
