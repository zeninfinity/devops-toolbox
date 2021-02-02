module "instance_profile_label" {
  source  = "cloudposse/label/null"
  version = "0.22.1"

  #attributes = distinct(compact(concat(module.this.attributes, ["profile"])))

}

data "aws_iam_policy_document" "test" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "test" {
  name               = "aws_iam_role_test"
  assume_role_policy = data.aws_iam_policy_document.test.json
  tags               = module.instance_profile_label.tags
}

# https://github.com/hashicorp/terraform-guides/tree/master/infrastructure-as-code/terraform-0.13-examples/module-depends-on
resource "aws_iam_instance_profile" "test" {
  name = "aws_iam_instance_profile_test"
  role = aws_iam_role.test.name
}
