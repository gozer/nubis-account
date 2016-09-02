module "us-east-1" {
  source = "../../vpc"

  aws_region     = "us-east-1"
  aws_regions    = "${var.aws_regions}"
  aws_profile    = "${var.aws_profile}"
  aws_account_id = "${var.aws_account_id}"

  # Okay, somewhat nasty
  #  - take the list of regions, look for the one we care about and make it XXX
  #  - take the result, and make all non-Xes into Ys
  #  - take the result of that (should be either XXX or YYY...)
  #  - change XXX, if found into 1
  #  - change YYY... if found into 0
  #  Result, 1 if the region is found, 0 otherwise
  enabled = "${var.enable_vpc * replace(replace(replace(replace(var.aws_regions, "/.*,?us-east-1,?.*/", "XXX"), "/[^X]+/", "Y" ), "XXX", "1"),"/Y+/","0")}"

  enable_consul       = "${var.enable_consul}"
  enable_jumphost     = "${var.enable_jumphost}"
  enable_fluent       = "${var.enable_fluent}"
  enable_ci           = "${var.enable_ci}"
  enable_opsec        = "${var.enable_opsec}"
  enable_stack_compat = "${var.enable_stack_compat}"
  enable_vpn          = "${var.enable_vpn}"
  enable_nat          = "${var.enable_nat}"

  technical_contact = "${var.technical_contact}"

  route53_delegation_set = "${var.route53_delegation_set}"
  route53_master_zone_id = "${var.route53_master_zone_id}"
  public_state_bucket    = "${var.public_state_bucket}"
  aws_state_region       = "${var.aws_state_region}"

  my_ip = "${var.my_ip}"

  # This exists to force a dependency on the global module
  account_name          = "${var.account_name}"
  nubis_version         = "${var.nubis_version}"
  nubis_domain          = "${var.nubis_domain}"
  environments          = "${var.environments}"
  environments_networks = "${var.environments_networks}"

  # should convert over to just passing in environments_networks
  admin_network = "${element(split(",",var.environments_networks), 0)}"
  prod_network  = "${element(split(",",var.environments_networks), 1)}"
  stage_network = "${element(split(",",var.environments_networks), 2)}"

  ipsec_target = "${var.environments_ipsec_target}"
  vpn_bgp_asn   = "${var.vpn_bgp_asn}"

  consul_secret           = "${var.consul_secret}"
  consul_master_acl_token = "${var.consul_master_acl_token}"

  datadog_api_key = "${var.datadog_api_key}"

  ci_project                    = "${var.ci_project}"
  ci_git_repo                   = "${var.ci_git_repo}"
  ci_github_oauth_client_secret = "${var.ci_github_oauth_client_secret}"
  ci_github_oauth_client_id     = "${var.ci_github_oauth_client_id}"
  ci_admins                     = "${var.ci_admins}"
}

# XXX: Yes, cut-n-paste, can't be helped at the moment
module "us-west-2" {
  source = "../../vpc"

  aws_region     = "us-west-2"
  aws_regions    = "${var.aws_regions}"
  aws_profile    = "${var.aws_profile}"
  aws_account_id = "${var.aws_account_id}"

  # Okay, somewhat nasty
  #  - take the list of regions, look for the one we care about and make it XXX
  #  - take the result, and make all non-Xes into Ys
  #  - take the result of that (should be either XXX or YYY...)
  #  - change XXX, if found into 1
  #  - change YYY... if found into 0
  #  Result, 1 if the region is found, 0 otherwise
  enabled = "${var.enable_vpc * replace(replace(replace(replace(var.aws_regions, "/.*,?us-west-2,?.*/", "XXX"), "/[^X]+/", "Y" ), "XXX", "1"),"/Y+/","0")}"

  enable_consul       = "${var.enable_consul}"
  enable_jumphost     = "${var.enable_jumphost}"
  enable_fluent       = "${var.enable_fluent}"
  enable_ci           = "${var.enable_ci}"
  enable_opsec        = "${var.enable_opsec}"
  enable_stack_compat = "${var.enable_stack_compat}"
  enable_vpn          = "${var.enable_vpn}"
  enable_nat          = "${var.enable_nat}"

  technical_contact = "${var.technical_contact}"

  route53_delegation_set = "${var.route53_delegation_set}"
  route53_master_zone_id = "${var.route53_master_zone_id}"
  public_state_bucket    = "${var.public_state_bucket}"
  aws_state_region       = "${var.aws_state_region}"

  my_ip = "${var.my_ip}"

  # This exists to force a dependency on the global module
  account_name          = "${var.account_name}"
  nubis_version         = "${var.nubis_version}"
  nubis_domain          = "${var.nubis_domain}"
  environments          = "${var.environments}"
  environments_networks = "${var.environments_networks}"

  # should convert over to just passing in environments_networks
  admin_network = "${element(split(",",var.environments_networks), 0)}"
  prod_network  = "${element(split(",",var.environments_networks), 1)}"
  stage_network = "${element(split(",",var.environments_networks), 2)}"

  ipsec_target = "${var.environments_ipsec_target}"
  vpn_bgp_asn   = "${var.vpn_bgp_asn}"

  consul_secret           = "${var.consul_secret}"
  consul_master_acl_token = "${var.consul_master_acl_token}"

  datadog_api_key = "${var.datadog_api_key}"

  ci_project                    = "${var.ci_project}"
  ci_git_repo                   = "${var.ci_git_repo}"
  ci_github_oauth_client_secret = "${var.ci_github_oauth_client_secret}"
  ci_github_oauth_client_id     = "${var.ci_github_oauth_client_id}"
  ci_admins                     = "${var.ci_admins}"
}
