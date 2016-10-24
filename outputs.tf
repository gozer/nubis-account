output "admins_users" {
  value = "${module.global_admins.admins_users}"
}

output "admins_access_keys" {
  value = "${module.global_admins.admins_access_keys}"
}

output "admins_secret_keys" {
  value = "${module.global_admins.admins_secret_keys}"
}

output "guests_users" {
  value = "${module.global_admins.guests_users}"
}

output "guests_access_keys" {
  value = "${module.global_admins.guests_access_keys}"
}

output "guests_secret_keys" {
  value = "${module.global_admins.guests_secret_keys}"
}

output "admins_roles" {
  value = "${module.global_admins.admins_roles}"
}

output "readonly_role" {
  value = "${module.global_admins.readonly_role}"
}

output "account_id" {
  value = "${module.global_admins.account_id}"
}

output "datadog_access_key" {
  value = "${module.global_meta.datadog_access_key}"
}

output "datadog_secret_key" {
  value = "${module.global_meta.datadog_secret_key}"
}

output "nameservers" {
  value = "${module.global_meta.nameservers}"
}

output "zone_name" {
  value = "${module.global_meta.route53_master_zone_name}"
}

output "cloudhealth_assume_role_arn" {
  value = "${module.global_meta.cloudhealth_assume_role_arn}"
}

output "cloudhealth_assume_role_external_id" {
  value = "${module.global_meta.cloudhealth_assume_role_external_id}"
}
