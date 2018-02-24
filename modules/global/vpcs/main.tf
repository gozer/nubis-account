module "us-east-1" {
  source = "../../vpc"

  aws_region  = "us-east-1"
  aws_regions = "${var.aws_regions}"

  # Okay, somewhat nasty
  #  - take the list of regions, look for the one we care about and make it XXX
  #  - take the result, and make all non-Xes into Ys
  #  - take the result of that (should be either XXX or YYY...)
  #  - change XXX, if found into 1
  #  - change YYY... if found into 0
  #  Result, 1 if the region is found, 0 otherwise
  enabled = "${var.enable_vpc * replace(replace(replace(replace(var.aws_regions, "/.*,?us-east-1,?.*/", "XXX"), "/[^X]+/", "Y" ), "XXX", "1"),"/Y+/","0")}"

  enable_consul                 = "${var.enable_consul}"
  enable_jumphost               = "${var.enable_jumphost}"
  enable_fluent                 = "${var.enable_fluent}"
  enable_monitoring             = "${var.enable_monitoring}"
  enable_ci                     = "${var.enable_ci}"
  enable_opsec                  = "${var.enable_opsec}"
  enable_vpn                    = "${var.enable_vpn}"
  enable_nat                    = "${var.enable_nat}"
  enable_user_management_consul = "${var.enable_user_management_consul}"
  enable_user_management_iam    = "${var.enable_user_management_iam}"
  enable_sso                    = "${var.enable_sso}"

  technical_contact = "${var.technical_contact}"

  route53_delegation_set = "${var.route53_delegation_set}"
  route53_master_zone_id = "${var.route53_master_zone_id}"
  public_state_bucket    = "${var.public_state_bucket}"
  apps_state_bucket      = "${var.apps_state_bucket}"
  aws_state_region       = "${var.aws_state_region}"

  # This exists to force a dependency on the global module
  account_name    = "${var.account_name}"
  nubis_version   = "${var.nubis_version}"
  nubis_domain    = "${var.nubis_domain}"
  arenas          = "${var.arenas}"
  arenas_networks = "${var.arenas_networks}"

  ipsec_target = "${var.arenas_ipsec_target}"
  vpn_bgp_asn  = "${var.vpn_bgp_asn}"

  consul_secret           = "${var.consul_secret}"
  consul_master_acl_token = "${var.consul_master_acl_token}"
  consul_sudo_groups      = "${var.consul_sudo_groups}"
  consul_user_groups      = "${var.consul_user_groups}"
  consul_version          = "${var.consul_version}"

  # Jekins
  ci = "${var.ci}"

  # nat
  nat_sudo_groups = "${var.nat_sudo_groups}"
  nat_user_groups = "${var.nat_user_groups}"
  nat_version     = "${var.nat_version}"

  # monitoring
  monitoring_slack_url             = "${var.monitoring_slack_url}"
  monitoring_slack_channel         = "${var.monitoring_slack_channel}"
  monitoring_notification_email    = "${var.monitoring_notification_email}"
  monitoring_pagerduty_service_key = "${var.monitoring_pagerduty_service_key}"
  monitoring_sudo_groups           = "${var.monitoring_sudo_groups}"
  monitoring_user_groups           = "${var.monitoring_user_groups}"
  monitoring_password              = "${var.monitoring_password}"
  monitoring_version               = "${var.monitoring_version}"
  monitoring_instance_type         = "${var.monitoring_instance_type}"
  monitoring_swap_size_meg         = "${var.monitoring_swap_size_meg}"

  # Pagerduty
  monitoring_pagerduty_critical_platform_service_key          = "${var.monitoring_pagerduty_critical_platform_service_key}"
  monitoring_pagerduty_non_critical_platform_service_key      = "${var.monitoring_pagerduty_non_critical_platform_service_key}"
  monitoring_pagerduty_critical_application_service_key       = "${var.monitoring_pagerduty_critical_application_service_key}"
  monitoring_pagerduty_non_critical_application_service_key   = "${var.monitoring_pagerduty_non_critical_application_service_key}"

  # fluentd
  fluentd         = "${var.fluentd}"
  fluentd_version = "${var.fluentd_version}"

  # jumphost user groups
  jumphost_sudo_groups = "${var.jumphost_sudo_groups}"
  jumphost_user_groups = "${var.jumphost_user_groups}"
  jumphost_version     = "${var.jumphost_version}"

  # SSO
  sso_sudo_groups          = "${var.sso_sudo_groups}"
  sso_user_groups          = "${var.sso_user_groups}"
  sso_openid_client_id     = "${var.sso_openid_client_id}"
  sso_openid_client_secret = "${var.sso_openid_client_secret}"
  sso_version              = "${var.sso_version}"

  # user management
  user_management_smtp_from_address  = "${var.user_management_smtp_from_address}"
  user_management_smtp_username      = "${var.user_management_smtp_username}"
  user_management_smtp_password      = "${var.user_management_smtp_password}"
  user_management_smtp_host          = "${var.user_management_smtp_host}"
  user_management_smtp_port          = "${var.user_management_smtp_port}"
  user_management_ldap_server        = "${var.user_management_ldap_server}"
  user_management_ldap_port          = "${var.user_management_ldap_port}"
  user_management_ldap_base_dn       = "${var.user_management_ldap_base_dn}"
  user_management_ldap_bind_user     = "${var.user_management_ldap_bind_user}"
  user_management_ldap_bind_password = "${var.user_management_ldap_bind_password}"

  # user management
  user_management_smtp_from_address  = "${var.user_management_smtp_from_address}"
  user_management_smtp_username      = "${var.user_management_smtp_username}"
  user_management_smtp_password      = "${var.user_management_smtp_password}"
  user_management_smtp_host          = "${var.user_management_smtp_host}"
  user_management_smtp_port          = "${var.user_management_smtp_port}"
  user_management_ldap_server        = "${var.user_management_ldap_server}"
  user_management_ldap_port          = "${var.user_management_ldap_port}"
  user_management_ldap_base_dn       = "${var.user_management_ldap_base_dn}"
  user_management_ldap_bind_user     = "${var.user_management_ldap_bind_user}"
  user_management_ldap_bind_password = "${var.user_management_ldap_bind_password}"
  user_management_tls_cert           = "${var.user_management_tls_cert}"
  user_management_tls_key            = "${var.user_management_tls_key}"
  user_management_sudo_groups        = "${var.user_management_sudo_groups}"
  user_management_user_groups        = "${var.user_management_user_groups}"

  # MiG
  mig = "${var.mig}"

  # Instance MFA (DUO)
  instance_mfa = "${var.instance_mfa}"
}

# XXX: Yes, cut-n-paste, can't be helped at the moment
module "us-west-2" {
  source = "../../vpc"

  aws_region  = "us-west-2"
  aws_regions = "${var.aws_regions}"

  # Okay, somewhat nasty
  #  - take the list of regions, look for the one we care about and make it XXX
  #  - take the result, and make all non-Xes into Ys
  #  - take the result of that (should be either XXX or YYY...)
  #  - change XXX, if found into 1
  #  - change YYY... if found into 0
  #  Result, 1 if the region is found, 0 otherwise
  enabled = "${var.enable_vpc * replace(replace(replace(replace(var.aws_regions, "/.*,?us-west-2,?.*/", "XXX"), "/[^X]+/", "Y" ), "XXX", "1"),"/Y+/","0")}"

  enable_consul                 = "${var.enable_consul}"
  enable_jumphost               = "${var.enable_jumphost}"
  enable_fluent                 = "${var.enable_fluent}"
  enable_monitoring             = "${var.enable_monitoring}"
  enable_ci                     = "${var.enable_ci}"
  enable_opsec                  = "${var.enable_opsec}"
  enable_vpn                    = "${var.enable_vpn}"
  enable_nat                    = "${var.enable_nat}"
  enable_user_management_consul = "${var.enable_user_management_consul}"
  enable_user_management_iam    = "${var.enable_user_management_iam}"
  enable_sso                    = "${var.enable_sso}"

  technical_contact = "${var.technical_contact}"

  route53_delegation_set = "${var.route53_delegation_set}"
  route53_master_zone_id = "${var.route53_master_zone_id}"
  public_state_bucket    = "${var.public_state_bucket}"
  apps_state_bucket      = "${var.apps_state_bucket}"
  aws_state_region       = "${var.aws_state_region}"

  # This exists to force a dependency on the global module
  account_name    = "${var.account_name}"
  nubis_version   = "${var.nubis_version}"
  nubis_domain    = "${var.nubis_domain}"
  arenas          = "${var.arenas}"
  arenas_networks = "${var.arenas_networks}"

  ipsec_target = "${var.arenas_ipsec_target}"
  vpn_bgp_asn  = "${var.vpn_bgp_asn}"

  consul_secret           = "${var.consul_secret}"
  consul_master_acl_token = "${var.consul_master_acl_token}"
  consul_sudo_groups      = "${var.consul_sudo_groups}"
  consul_user_groups      = "${var.consul_user_groups}"
  consul_version          = "${var.consul_version}"

  # Jekins
  ci = "${var.ci}"

  # nat
  nat_sudo_groups = "${var.nat_sudo_groups}"
  nat_user_groups = "${var.nat_user_groups}"
  nat_version     = "${var.nat_version}"

  # monitoring
  monitoring_slack_url             = "${var.monitoring_slack_url}"
  monitoring_slack_channel         = "${var.monitoring_slack_channel}"
  monitoring_notification_email    = "${var.monitoring_notification_email}"
  monitoring_pagerduty_service_key = "${var.monitoring_pagerduty_service_key}"
  monitoring_sudo_groups           = "${var.monitoring_sudo_groups}"
  monitoring_user_groups           = "${var.monitoring_user_groups}"
  monitoring_password              = "${var.monitoring_password}"
  monitoring_version               = "${var.monitoring_version}"
  monitoring_instance_type         = "${var.monitoring_instance_type}"
  monitoring_swap_size_meg         = "${var.monitoring_swap_size_meg}"

  # Pagerduty
  monitoring_pagerduty_critical_platform_service_key          = "${var.monitoring_pagerduty_critical_platform_service_key}"
  monitoring_pagerduty_non_critical_platform_service_key      = "${var.monitoring_pagerduty_non_critical_platform_service_key}"
  monitoring_pagerduty_critical_application_service_key       = "${var.monitoring_pagerduty_critical_application_service_key}"
  monitoring_pagerduty_non_critical_application_service_key   = "${var.monitoring_pagerduty_non_critical_application_service_key}"

  # fluentd
  fluentd         = "${var.fluentd}"
  fluentd_version = "${var.fluentd_version}"

  # Jumphost user groups
  jumphost_sudo_groups = "${var.jumphost_sudo_groups}"
  jumphost_user_groups = "${var.jumphost_user_groups}"
  jumphost_version     = "${var.jumphost_version}"

  # SSO
  sso_sudo_groups          = "${var.sso_sudo_groups}"
  sso_user_groups          = "${var.sso_user_groups}"
  sso_openid_client_id     = "${var.sso_openid_client_id}"
  sso_openid_client_secret = "${var.sso_openid_client_secret}"
  sso_version              = "${var.sso_version}"

  # user management
  user_management_smtp_from_address  = "${var.user_management_smtp_from_address}"
  user_management_smtp_username      = "${var.user_management_smtp_username}"
  user_management_smtp_password      = "${var.user_management_smtp_password}"
  user_management_smtp_host          = "${var.user_management_smtp_host}"
  user_management_smtp_port          = "${var.user_management_smtp_port}"
  user_management_ldap_server        = "${var.user_management_ldap_server}"
  user_management_ldap_port          = "${var.user_management_ldap_port}"
  user_management_ldap_base_dn       = "${var.user_management_ldap_base_dn}"
  user_management_ldap_bind_user     = "${var.user_management_ldap_bind_user}"
  user_management_ldap_bind_password = "${var.user_management_ldap_bind_password}"
  user_management_tls_cert           = "${var.user_management_tls_cert}"
  user_management_tls_key            = "${var.user_management_tls_key}"
  user_management_sudo_groups        = "${var.user_management_sudo_groups}"
  user_management_user_groups        = "${var.user_management_user_groups}"

  # MiG
  mig = "${var.mig}"

  # Instance MFA (DUO)
  instance_mfa = "${var.instance_mfa}"
}
