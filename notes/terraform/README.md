# Terraform
Location for terraform notes.

## Security Group issue

Adding create_before_destroy and name_prefix allows security groups to not conflict with current security group. 

```
resource "aws_security_group" "example" {
  name_prefix = "example-"
  // other stuff

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "example" {
  vpc_security_group_ids = ["${aws_security_group.example.id}"]
  // other stuff
}
```

Then the new SG gets created, swapped out on the ENI for the EC2 instance and then the old SG can be deleted.
