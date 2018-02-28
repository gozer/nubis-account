output "pagerduty_platform_critical_key" {
  value = "${module.platform_pagerduty.service_integration_key_critical}"
}

output "pagerduty_platform_non_critical_key" {
  value = "${module.platform_pagerduty.service_integration_key_non_critical}"
}

output "pagerduty_application_critical_key" {
  value = "${module.application_pagerduty.service_integration_key_critical}"
}

output "pagerduty_application_non_critical_key" {
  value = "${module.application_pagerduty.service_integration_key_non_critical}"
}
