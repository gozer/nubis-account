variable technical_contact {}

variable aws_regions {}

variable account_name {}

variable nubis_version {}

variable nubis_domain {}

variable arenas {
  type = "list"
}

variable arenas_networks {
  type = "list"
}

variable arenas_ipsec_target {}

variable consul_secret {}

variable consul_master_acl_token {}

variable consul_sudo_groups {}

variable consul_user_groups {}

variable consul_version {}

variable enable_vpc {}

variable enable_jumphost {}

variable enable_fluent {}

variable enable_monitoring {}

variable enable_ci {}

variable enable_consul {}

variable enable_opsec {}

variable enable_vpn {}

variable enable_nat {}

variable enable_user_management_iam {}

variable enable_user_management_consul {}

variable enable_sso {}

variable vpn_bgp_asn {}

variable monitoring_slack_url {}

variable monitoring_slack_channel {}

variable monitoring_notification_email {}

variable monitoring_sudo_groups {}

variable monitoring_user_groups {}
variable monitoring_password {}

variable monitoring_version {}
variable monitoring_instance_type {}
variable monitoring_swap_size_meg {}

variable monitoring_pagerduty_critical_platform_service_key {}
variable monitoring_pagerduty_non_critical_platform_service_key {}
variable monitoring_pagerduty_critical_application_service_key {}
variable monitoring_pagerduty_non_critical_application_service_key {}

variable ci {
  type = "map"
}

variable route53_delegation_set {}

variable route53_master_zone_id {}

variable public_state_bucket {}

variable apps_state_bucket {}

variable aws_state_region {}

variable user_management_smtp_from_address {}

variable user_management_smtp_username {}

variable user_management_smtp_password {}

variable user_management_smtp_host {}

variable user_management_smtp_port {}

variable user_management_ldap_server {}

variable user_management_ldap_port {}

variable user_management_ldap_base_dn {}

variable user_management_ldap_bind_user {}

variable user_management_ldap_bind_password {}

variable user_management_tls_cert {}

variable user_management_tls_key {}

variable user_management_sudo_groups {}

variable user_management_user_groups {}

variable fluentd {
  type = "map"
}

variable fluentd_version {}

variable jumphost_sudo_groups {}
variable jumphost_user_groups {}
variable jumphost_version {}

variable sso_sudo_groups {}
variable sso_user_groups {}
variable sso_openid_client_id {}
variable sso_openid_client_secret {}
variable sso_version {}

variable nat_sudo_groups {}
variable nat_user_groups {}
variable nat_version {}

variable mig {
  type = "map"
}

variable instance_mfa {
  type = "map"
}
