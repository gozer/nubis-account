provider "atlas" {
    token = "${var.atlas_token}"
}

module "global_admins" {
  source = "modules/global/admins"

  aws_profile = "${var.aws_profile}"
  aws_region  = "${element(split(",",var.aws_regions),0)}"

  admin_users = "${var.admin_users}"
  guest_users = "${var.guest_users}"

  account_name  = "${var.account_name}"
  nubis_version = "${var.nubis_version}"

  technical_contact = "${var.technical_contact}"
  create_users      = "${(lookup(var.features, "user_management") + 1) % 2 }"
}

module "global_meta" {
  source = "modules/global/meta"

  aws_profile = "${var.aws_profile}"
  aws_region  = "${var.global_region}"

  account_name  = "${var.account_name}"
  nubis_version = "${var.nubis_version}"
  nubis_domain  = "${var.nubis_domain}"

  state_uuid = "${var.state_uuid}"

  technical_contact = "${var.technical_contact}"
}

module "global_opsec" {
  source = "modules/global/opsec"

  enabled = "${lookup(var.features,"opsec")}"

  aws_profile = "${var.aws_profile}"
  aws_region  = "${element(split(",",var.aws_regions),0)}"

  cloudtrail_bucket    = "${lookup(var.cloudtrail, "bucket")}"
  cloudtrail_sns_topic = "${lookup(var.cloudtrail, "sns_topic")}"
}

module "vpcs" {
  source = "modules/global/vpcs"

  enable_vpc          = "${lookup(var.features,"vpc")}"
  enable_consul       = "${lookup(var.features,"consul")}"
  enable_jumphost     = "${lookup(var.features,"jumphost")}"
  enable_fluent       = "${lookup(var.features,"fluent")}"
  enable_monitoring   = "${lookup(var.features,"monitoring")}"
  enable_ci           = "${lookup(var.features,"ci")}"
  enable_opsec        = "${lookup(var.features,"opsec")}"
  enable_stack_compat = "${lookup(var.features,"stack_compat")}"
  enable_vpn          = "${lookup(var.features,"vpn")}"
  enable_nat          = "${lookup(var.features,"nat")}"
  enable_user_management = "${lookup(var.features,"user_management")}"

  technical_contact = "${var.technical_contact}"

  route53_delegation_set = "${module.global_meta.route53_delegation_set}"
  route53_master_zone_id = "${module.global_meta.route53_master_zone_id}"
  public_state_bucket    = "${module.global_meta.public_state_bucket}"

  my_ip = "${var.my_ip}"

  aws_regions    = "${var.aws_regions}"
  aws_profile    = "${var.aws_profile}"
  aws_account_id = "${module.global_admins.account_id}"

  aws_state_region = "${var.global_region}"

  # This exists to force a dependency on the global admins module
  account_name = "${module.global_admins.account_name}"

  nubis_version              = "${var.nubis_version}"
  nubis_domain               = "${var.nubis_domain}"
  environments               = "${var.environments}"
  environments_networks      = "${var.environments_networks}"
  environments_ipsec_target = "${lookup(var.vpn, "ipsec_target")}"
  vpn_bgp_asn                = "${lookup(var.vpn, "bgp_asn")}"

  consul_secret           = "${lookup(var.consul, "secret")}"
  consul_master_acl_token = "${lookup(var.consul, "master_acl_token")}"

  datadog_api_key = "${lookup(var.datadog, "api_key")}"

  ci_project                    = "${lookup(var.ci, "project")}"
  ci_git_repo                   = "${lookup(var.ci, "git_repo")}"
  ci_github_oauth_client_secret = "${lookup(var.ci, "github_oauth_client_secret")}"
  ci_github_oauth_client_id     = "${lookup(var.ci, "github_oauth_client_id")}"
  ci_admins                     = "${lookup(var.ci, "admins")}"

  # user management
  user_management_smtp_from_address     = "${lookup(var.user_management, "smtp_from_address")}"
  user_management_smtp_username         = "${lookup(var.user_management, "smtp_username")}"
  user_management_smtp_password         = "${lookup(var.user_management, "smtp_password")}"
  user_management_smtp_host             = "${lookup(var.user_management, "smtp_host")}"
  user_management_smtp_port             = "${lookup(var.user_management, "smtp_port")}"
  user_management_ldap_server           = "${lookup(var.user_management, "ldap_server")}"
  user_management_ldap_port             = "${lookup(var.user_management, "ldap_port")}"
  user_management_ldap_base_dn          = "${lookup(var.user_management, "ldap_base_dn")}"
  user_management_ldap_bind_user        = "${lookup(var.user_management, "ldap_bind_user")}"
  user_management_ldap_bind_password    = "${lookup(var.user_management, "ldap_bind_password")}"
  user_management_tls_cert              = "${lookup(var.user_management, "tls_cert")}"
  user_management_tls_key               = "${lookup(var.user_management, "tls_key")}"
  user_management_global_admins         = "${lookup(var.user_management, "global_admins")}"
  user_management_sudo_users            = "${lookup(var.user_management, "sudo_users")}"
  user_management_users                 = "${lookup(var.user_management, "users")}"

}
