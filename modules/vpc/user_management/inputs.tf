variable "enabled" {}

variable "region" {}

variable "version" {}

variable "credstash_key" {}

variable "credstash_db" {}

variable "account_name" {}

variable "rate" {
  default = "rate(15 minutes)"
}

variable user_management_smtp_from_address {
}

variable user_management_smtp_username {
}

variable user_management_smtp_password {
}

variable user_management_smtp_port {
}

variable user_management_smtp_host {
}

variable user_management_ldap_server {
}

variable user_management_ldap_port {
}

variable user_management_ldap_base_dn {
}

variable user_management_ldap_bind_user {
}

variable user_management_ldap_bind_password {
}

variable user_management_tls_cert {
}

variable user_management_tls_key {
}

variable user_management_global_admins {
}

variable user_management_sudo_users {
}

variable user_management_users {
}
