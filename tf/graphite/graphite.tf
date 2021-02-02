provider "aws" {
  access_key = "<access_key>"
  secret_key = "<secret_key>"
  region = "us-west-2"
}

resource "aws_instance" "graphite-server" {
  ami = "ami-12345678"
  instance_type = "m3.large"
  subnet_id="subnet-1234567890"
  security_groups=["sg-1234567890"]
  key_name="key_name"
  iam_instance_profile = "graphite"
  tags {
    Name = "graphite"
    Environment = "stats"
  }
}

resource "aws_eip" "ip" {
    instance = "${aws_instance.graphite-server.id}"
    vpc = true
}
