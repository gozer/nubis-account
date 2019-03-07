terraform {
  backend "s3" {}
}

provider "aws" {
  version = "~> 1.60"
}

module "global_admins" {
  source = "./modules/global/admins"

  aws_region = "${element(split(",",var.aws_regions),0)}"

  admin_users = "${var.admin_users}"
  guest_users = "${var.guest_users}"

  account_name  = "${var.account_name}"
  nubis_version = "${var.nubis_version}"

  technical_contact = "${var.technical_contact}"
}

module "global_meta" {
  source = "./modules/global/meta"

  aws_region = "${var.global_region}"

  account_name  = "${var.account_name}"
  nubis_version = "${var.nubis_version}"
  nubis_domain  = "${var.nubis_domain}"

  technical_contact = "${var.technical_contact}"
}

module "global_opsec" {
  source = "./modules/global/opsec"

  enabled = "${lookup(var.features,"opsec")}"

  aws_region = "${element(split(",",var.aws_regions),0)}"

  cloudtrail_bucket    = "${lookup(var.cloudtrail, "bucket")}"
  cloudtrail_sns_topic = "${lookup(var.cloudtrail, "sns_topic")}"
}

module "pagerduty" {
  source = "./modules/global/pagerduty"

  pagerduty_token                                      = "${lookup(var.pagerduty, "token")}"
  enable_pagerduty                                     = "${lookup(var.features, "pagerduty") * lookup(var.features, "vpc") * lookup(var.features, "monitoring")}"
  pagerduty_team_name                                  = "${coalesce(lookup(var.pagerduty, "team_name"), var.account_name)}"
  pagerduty_platform_critical_escalation_policy        = "${lookup(var.pagerduty, "platform_critical_escalation_policy")}"
  pagerduty_platform_non_critical_escalation_policy    = "${lookup(var.pagerduty, "platform_non_critical_escalation_policy")}"
  pagerduty_application_critical_escalation_policy     = "${lookup(var.pagerduty, "application_critical_escalation_policy")}"
  pagerduty_application_non_critical_escalation_policy = "${lookup(var.pagerduty, "application_non_critical_escalation_policy")}"
}

module "vpcs" {
  source = "./modules/global/vpcs"

  enable_vpc                    = "${lookup(var.features,"vpc")}"
  enable_consul                 = "${lookup(var.features,"consul")}"
  enable_jumphost               = "${lookup(var.features,"jumphost")}"
  enable_fluent                 = "${lookup(var.features,"fluent")}"
  enable_monitoring             = "${lookup(var.features,"monitoring")}"
  enable_ci                     = "${lookup(var.features,"ci")}"
  enable_opsec                  = "${lookup(var.features,"opsec")}"
  enable_vpn                    = "${lookup(var.features,"vpn")}"
  enable_nat                    = "${lookup(var.features,"nat")}"
  enable_user_management_iam    = "${lookup(var.features, "user_management_iam")}"
  enable_user_management_consul = "${lookup(var.features,"user_management_consul")}"
  enable_sso                    = "${lookup(var.features,"sso")}"
  enable_kubernetes             = "${lookup(var.features, "kubernetes")}"

  technical_contact = "${var.technical_contact}"

  route53_delegation_set = "${module.global_meta.route53_delegation_set}"
  route53_master_zone_id = "${module.global_meta.route53_master_zone_id}"
  public_state_bucket    = "${module.global_meta.public_state_bucket}"
  apps_state_bucket      = "${module.global_meta.apps_state_bucket}"

  aws_regions      = "${var.aws_regions}"
  aws_state_region = "${var.global_region}"

  # This exists to force a dependency on the global admins module
  account_name = "${module.global_admins.account_name}"

  nubis_version              = "${var.nubis_version}"
  nubis_domain               = "${var.nubis_domain}"
  arenas                     = "${var.arenas}"
  arenas_networks            = "${var.arenas_networks}"
  arenas_ipsec_target        = "${lookup(var.vpn, "ipsec_target")}"
  vpn_destination_cidr_block = "${lookup(var.vpn, "destination_cidr_block")}"
  vpn_bgp_asn                = "${lookup(var.vpn, "bgp_asn")}"
  vpn_output_config          = "${lookup(var.vpn, "output_config")}"

  consul_secret           = "${lookup(var.consul, "secret")}"
  consul_master_acl_token = "${lookup(var.consul, "master_acl_token")}"
  consul_sudo_groups      = "${lookup(var.consul, "sudo_groups")}"
  consul_user_groups      = "${lookup(var.consul, "user_groups")}"
  consul_version          = "${lookup(var.consul, "version")}"

  flow_logs = "${lookup(var.vpc, "flow_logs")}"

  # Jenkins
  ci = "${var.ci}"

  # nat
  nat_sudo_groups = "${lookup(var.nat, "sudo_groups")}"
  nat_user_groups = "${lookup(var.nat, "user_groups")}"
  nat_version     = "${lookup(var.nat, "version")}"

  # monitoring
  monitoring_slack_url          = "${lookup(var.monitoring, "slack_url")}"
  monitoring_slack_channel      = "${lookup(var.monitoring, "slack_channel")}"
  monitoring_notification_email = "${lookup(var.monitoring, "notification_email")}"
  monitoring_sudo_groups        = "${lookup(var.monitoring, "sudo_groups")}"
  monitoring_user_groups        = "${lookup(var.monitoring, "user_groups")}"
  monitoring_password           = "${lookup(var.monitoring, "password")}"
  monitoring_version            = "${lookup(var.monitoring, "version")}"
  monitoring_instance_type      = "${lookup(var.monitoring, "instance_type")}"
  monitoring_swap_size_meg      = "${lookup(var.monitoring, "swap_size_meg")}"

  # Pagerduty
  monitoring_pagerduty_critical_platform_service_key        = "${module.pagerduty.pagerduty_platform_critical_key}"
  monitoring_pagerduty_non_critical_platform_service_key    = "${module.pagerduty.pagerduty_platform_non_critical_key}"
  monitoring_pagerduty_critical_application_service_key     = "${module.pagerduty.pagerduty_application_critical_key}"
  monitoring_pagerduty_non_critical_application_service_key = "${module.pagerduty.pagerduty_application_non_critical_key}"

  # fluentd
  fluentd         = "${var.fluentd}"
  fluentd_version = "${lookup(var.fluentd, "version")}"

  # jumphost groups
  jumphost_sudo_groups = "${lookup(var.jumphost, "sudo_groups")}"
  jumphost_user_groups = "${lookup(var.jumphost, "user_groups")}"
  jumphost_version     = "${lookup(var.jumphost, "version")}"

  # sso
  sso_openid_client_id     = "${lookup(var.sso, "openid_client_id")}"
  sso_openid_client_secret = "${lookup(var.sso, "openid_client_secret")}"
  sso_sudo_groups          = "${lookup(var.sso, "sudo_groups")}"
  sso_user_groups          = "${lookup(var.sso, "user_groups")}"
  sso_version              = "${lookup(var.sso, "version")}"

  # user management
  user_management_smtp_from_address  = "${lookup(var.user_management, "smtp_from_address")}"
  user_management_smtp_username      = "${lookup(var.user_management, "smtp_username")}"
  user_management_smtp_password      = "${lookup(var.user_management, "smtp_password")}"
  user_management_smtp_host          = "${lookup(var.user_management, "smtp_host")}"
  user_management_smtp_port          = "${lookup(var.user_management, "smtp_port")}"
  user_management_ldap_server        = "${lookup(var.user_management, "ldap_server")}"
  user_management_ldap_port          = "${lookup(var.user_management, "ldap_port")}"
  user_management_ldap_base_dn       = "${lookup(var.user_management, "ldap_base_dn")}"
  user_management_ldap_bind_user     = "${lookup(var.user_management, "ldap_bind_user")}"
  user_management_ldap_bind_password = "${lookup(var.user_management, "ldap_bind_password")}"
  user_management_tls_cert           = "${lookup(var.user_management, "tls_cert")}"
  user_management_tls_key            = "${lookup(var.user_management, "tls_key")}"
  user_management_sudo_groups        = "${lookup(var.user_management, "sudo_groups")}"
  user_management_user_groups        = "${lookup(var.user_management, "user_groups")}"

  # kubernetes
  kubernetes_image_version = "${lookup(var.kubernetes, "image_version")}"
  kubernetes_master_type   = "${lookup(var.kubernetes, "master_type")}"
  kubernetes_node_type     = "${lookup(var.kubernetes, "node_type")}"
  kubernetes_node_minimum  = "${lookup(var.kubernetes, "node_minimum")}"

  # MiG
  mig = "${var.mig}"

  # Instance MFA (DUO)
  instance_mfa = "${var.instance_mfa}"
}
