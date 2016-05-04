provider "aws" {
  profile = "${var.aws_profile}"
  region  = "${var.aws_region}"
}

resource "aws_cloudformation_stack" "opsec" {
  count = "${var.enabled}"

  name = "opsec"

  capabilities = [
    "CAPABILITY_IAM",
  ]

  template_body = "${file("${path.module}/audit.json")}"

  parameters = {}
}
