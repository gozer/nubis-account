provider "aws" {
    profile = "${var.aws_profile}"
    region = "${var.aws_region}"
}

resource "atlas_artifact" "nubis-fluent-collector" {
  count = "${var.enabled}"
  name = "nubisproject/nubis-fluentd-collector"
  type = "amazon.image"

  lifecycle { create_before_destroy = true }

  metadata {
        project_version = "${var.nubis_version}"
    }
}

provider "consul" {
    alias = "admin"
    scheme = "https"
    address = "${element(split(",",var.consul_endpoints), 0)}"
    datacenter = ""
}

provider "consul" {
    alias = "prod"
    scheme = "https"
    address = "${element(split(",",var.consul_endpoints), 1)}"
    datacenter = ""
}

provider "consul" {
    alias = "stage"
    scheme = "https"
    address = "${element(split(",",var.consul_endpoints), 0)}"
    datacenter = ""
}

resource "consul_keys" "admin" {
  count = "${var.enabled}"
  provider = "consul.admin"
  key {
        name = "test"
        path = "test"
        default = "hello"
        value = "world"
    }
}
resource "consul_keys" "prod" {
  count = "${var.enabled}"
  provider = "consul.prod"
  key {
        name = "test"
        path = "test"
        default = "hello"
        value = "world"
    }
}
resource "consul_keys" "stage" {
  count = "${var.enabled}"
  provider = "consul.stage"

  key {
        name = "test"
        path = "test"
        default = "hello"
        value = "world"
    }
}

resource "aws_cloudformation_stack" "vpc" {
  count = "${var.enabled * 3}"
 
  name  = "fluent-collector-${element(split(",",var.environments), count.index)}"

  capabilities = [ "CAPABILITY_IAM" ]
  template_body = "${file("${path.module}/../../../fluent-collector/nubis/cloudformation/main.json")}"

  parameters = {
    ServiceName = "fluentd-collector"
    TechnicalOwner = "${var.technical_owner}"
    SSHKeyName    = "${var.key_name}"
    StacksVersion = "${var.nubis_version}"
    Environment = "${element(split(",",var.environments), count.index)}"
    # Fugly hack to work around limitations of TFs atlas provider, unfortunately, this is the only known
    # way to extract an AMI id by region from AWS, yuck
    AmiId = "${element(split(":", element(split(",", atlas_artifact.nubis-fluent-collector.id), lookup(var.atlas_region_map, var.aws_region))), 1)}"
  }
}
