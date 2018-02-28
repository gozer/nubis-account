provider "pagerduty" {
  version = "~> 0.1"
  token   = "${var.pagerduty_token}"
}

module "platform_pagerduty" {
  source                         = "github.com/nubisproject/nubis-pagerduty//service?ref=develop"
  enable_pagerduty               = "${var.enable_pagerduty}"
  team_name                      = "${var.pagerduty_team_name}"
  service_name                   = "platform"
  escalation_policy_critical     = "${var.pagerduty_platform_critical_escalation_policy}"
  escalation_policy_non_critical = "${var.pagerduty_platform_non_critical_escalation_policy}"
}

module "application_pagerduty" {
  source                         = "github.com/nubisproject/nubis-pagerduty//service?ref=develop"
  enable_pagerduty               = "${var.enable_pagerduty}"
  team_name                      = "${var.pagerduty_team_name}"
  service_name                   = "application"
  escalation_policy_critical     = "${var.pagerduty_application_critical_escalation_policy}"
  escalation_policy_non_critical = "${var.pagerduty_application_non_critical_escalation_policy}"
}
