provider "aws" {
  profile = "${var.aws_profile}"
  region  = "${var.aws_region}"
}

output "account_name" {
  value = "${var.account_name}"
}

output "technical_contact" {
  value = "${var.technical_contact}"
}

output "ssh_key_name" {
  value = "${var.ssh_key_name}"
}

resource "aws_iam_user" "admin" {
  count = "${length(split(",",var.admin_users))}"
  path  = "/nubis/admin/"
  name  = "${element(split(",",var.admin_users), count.index)}"

  provisioner "local-exec" {
    command = "sleep 10"
  }
}

resource "aws_iam_user" "guest" {
  count = "${length(split(",",var.guest_users))}"
  path  = "/nubis/guest/"
  name  = "${element(split(",",var.guest_users), count.index)}"
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

resource "aws_iam_role_policy" "admin" {
  count = "${length(split(",",var.admin_users))}"
  name  = "${element(split(",",var.admin_users), count.index)}"

  role = "${element(aws_iam_role.admin.*.id, count.index)}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "*",
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "admin" {
  count = "${length(split(",",var.admin_users))}"
  path  = "/nubis/admin/"
  name  = "${element(split(",",var.admin_users), count.index)}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal" : { "AWS" : "${element(aws_iam_user.admin.*.arn, count.index)}" },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role" "readonly" {
    count = 1
    path  = "/nubis/"
    name = "readonly"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal" : { "AWS" : [ ${join(",", formatlist("\"%s\"", concat(aws_iam_user.admin.*.arn, aws_iam_user.guest.*.arn)))} ]},
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_access_key" "admins" {
  count = "${length(split(",",var.admin_users))}"
  user  = "${element(aws_iam_user.admin.*.name, count.index)}"
}

resource "aws_iam_access_key" "guests" {
  count = "${length(split(",",var.guest_users))}"
  user  = "${element(aws_iam_user.guest.*.name, count.index)}"
}

resource "aws_iam_group" "admins" {
  name = "Administrators"
  path = "/nubis/admin/"
}

resource "aws_iam_group" "nacl_admins" {
  name = "NACLAdministrators"
  path = "/nubis/"
}

resource "aws_iam_group" "read_only_users" {
  name = "ReadOnlyUsers"
  path = "/nubis/"
}

resource "aws_iam_policy_attachment" "read_only" {
  name       = "read-only-attachments"
  groups     = ["${aws_iam_group.read_only_users.name}"]
  roles      = ["${aws_iam_role.readonly.name}"]
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_policy_attachment" "admins" {
  name       = "admins"
  groups     = ["${aws_iam_group.admins.name}"]
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group_policy" "nacl_admins" {
  name  = "nacl_admins_policy"
  group = "${aws_iam_group.nacl_admins.id}"

  policy = <<POLICY
{
              "Version": "2012-10-17",
              "Statement": [
                {
                  "Action": [
                    "ec2:CreateNetworkAclEntry",
                    "ec2:DeleteNetworkAclEntry",
                    "ec2:DescribeNetworkAcls",
                    "ec2:ReplaceNetworkAclEntry",
                    "ec2:DescribeVpcAttribute",
                    "ec2:DescribeVpcs"
                  ],
                  "Effect": "Allow",
                  "Resource": "*"
                }
              ]
            }
POLICY
}

resource "aws_iam_group_membership" "admins" {
  name = "admins-group-membership"

  users = [
    "${aws_iam_user.admin.*.name}",
  ]

  group = "${aws_iam_group.admins.name}"
}

resource "aws_iam_group_membership" "guest" {
  count = "${length(split(",",var.guest_users))}"
  name = "guest-group-membership"

  users = [
    "${aws_iam_user.guest.*.name}",
  ]

  group = "${aws_iam_group.read_only_users.name}"
}
