module "global_admins" {
  source = "modules/global/admins"

  aws_profile = "${var.aws_profile}"
  aws_region  = "us-east-1"

  admin_users = "${var.admin_users}"
  guest_users = "${var.guest_users}"

  account_name  = "${var.account_name}"
  nubis_version = "${var.nubis_version}"

  technical_contact = "${var.technical_contact}"
}

module "global_meta" {
  source = "modules/global/meta"

  aws_profile = "${var.aws_profile}"
  aws_region  = "us-east-1"

  account_name  = "${var.account_name}"
  nubis_version = "${var.nubis_version}"

  state_uuid = "${var.state_uuid}"

  technical_contact = "${var.technical_contact}"
}

module "global_opsec" {
  source = "modules/global/opsec"

  enabled = "${lookup(var.features,"opsec")}"

  aws_profile = "${var.aws_profile}"
  aws_region  = "us-east-1"

  cloudtrail_bucket    = "${lookup(var.cloudtrail, "bucket")}"
  cloudtrail_sns_topic = "${lookup(var.cloudtrail, "sns_topic")}"
}

module "vpcs" {
  source = "modules/global/vpcs"

  enable_consul       = "${lookup(var.features,"consul")}"
  enable_jumphost     = "${lookup(var.features,"jumphost")}"
  enable_fluent       = "${lookup(var.features,"fluent")}"
  enable_ci           = "${lookup(var.features,"ci")}"
  enable_opsec        = "${lookup(var.features,"opsec")}"
  enable_stack_compat = "${lookup(var.features,"stack_compat")}"
  enable_vpn          = "${lookup(var.features,"vpn")}"

  technical_contact = "${var.technical_contact}"

  route53_delegation_set = "${module.global_meta.route53_delegation_set}"

  my_ip = "${var.my_ip}"

  aws_regions    = "${var.aws_regions}"
  aws_profile    = "${var.aws_profile}"
  aws_account_id = "${module.global_admins.account_id}"

  # This exists to force a dependency on the global admins module
  account_name = "${module.global_admins.account_name}"

  nubis_version              = "${var.nubis_version}"
  nubis_domain               = "${var.nubis_domain}"
  environments               = "${var.environments}"
  environments_networks      = "${var.environments_networks}"
  environments_ipsec_targets = "${lookup(var.vpn, "ipsec_targets")}"
  vpn_bgp_asn                = "${lookup(var.vpn, "bgp_asn")}"

  consul_secret           = "${lookup(var.consul, "secret")}"
  consul_master_acl_token = "${lookup(var.consul, "master_acl_token")}"

  datadog_api_key = "${lookup(var.datadog, "api_key")}"

  ci_project                    = "${lookup(var.ci, "project")}"
  ci_git_repo                   = "${lookup(var.ci, "git_repo")}"
  ci_github_oauth_client_secret = "${lookup(var.ci, "github_oauth_client_secret")}"
  ci_github_oauth_client_id     = "${lookup(var.ci, "github_oauth_client_id")}"
  ci_admins                     = "${lookup(var.ci, "admins")}"
}
