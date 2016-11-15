variable account_name {}

variable aws_profile {
  default = "default"
}

variable atlas_token {
  default = "anonymous"
}

variable nubis_version {
  default = "v1.0.1-sec1"
}

variable environments {
  default = "admin,stage,prod"
}

variable environments_networks {}

variable admin_users {
  default = "gozer,limed,riweiss,jcrowe"
}

variable guest_users {
  default = "guest"
}

variable aws_regions {
  default = "us-east-1,us-west-2"
}

variable global_region {
  default = "eu-west-1"
}

variable consul {
  default = {
    master_acl_token = "00000000-0000-0000-0000-000000000000"
    secret           = "AAAAAAAAAAAAAAAAAAAAAA=="
  }
}

variable nubis_domain {
  default = "nubis.allizom.org"
}

variable technical_contact {
  default = "infra-aws@mozilla.com"
}

variable features {
  default = {
    vpc                    = 1
    consul                 = 1
    jumphost               = 0
    fluent                 = 0
    stack_compat           = 0
    mig                    = 0
    ci                     = 0
    vpn                    = 0
    nat                    = 1
    opsec                  = 0
    user_management_iam    = 0
    user_management_consul = 1
    monitoring             = 0
  }
}

variable state_uuid {
  default = ""
}

# Turn into features ?
variable datadog {
  default = {
    api_key = "unset"
  }
}

variable mig {
  default = {
    agent_cert     = "mig/agent.crt"
    agent_key      = "mig/agent.key"
    ca             = "mig/ca.crt"
    relay_password = "<unset>"
    relay_user     = "agent-it-nubis"
  }
}

variable cloudtrail {
  default = {
    bucket    = "mozilla-cloudtrail-logs"
    sns_topic = "arn:aws:sns:us-west-2:088944123687:MozillaCloudTrailLogs"
  }
}

variable my_ip {
  default = "127.0.0.1/32"
}

variable ci {
  default = {
    project                    = "skel"
    git_repo                   = "https://github.com/nubisproject/nubis-skel.git"
    github_oauth_client_secret = "AAA"
    github_oauth_client_id     = "BBB"
    admins                     = "gozer"
    slack_domain               = "nubisproject"
    slack_channel              = "#changes"
    slack_token                = ""
  }
}

variable monitoring {
  default = {
    slack_url             = ""
    slack_channel         = "#monitoring"
    notification_email    = "gozer+prometheus@mozilla.com"
    pagerduty_service_key = ""
  }
}

variable vpn {
  default = {
    ipsec_target  = "63.245.214.100"
    ipsec_network = "10.0.0.0/8"
    bgp_asn       = "65022"
  }
}

variable user_management {
  default = {
    smtp_from_address  = "nubis-team@mozilla.com"
    smtp_username      = "ABCDEFGHIJK"
    smtp_password      = "randomstringhere"
    smtp_host          = "email-smtp.us-west-2.amazonaws.com"
    smtp_port          = "587"
    ldap_server        = "ldap.mozilla.org"
    ldap_port          = "6363"
    ldap_base_dn       = "dc=mozilla"
    ldap_bind_user     = "cn=example,o=com"
    ldap_bind_password = "xxxxx"
    tls_cert           = "user_management.crt"
    tls_key            = "user_management.key"
    sudo_users         = "nubis_global_admins,nubis_sudo_users"
    users              = "nubis_users"
  }
}

variable jumphost {
  default = {
    sudo_groups = "nubis_global_admins"
    user_groups = ""
  }
}

variable fluentd {
  default = {
    sqs_queues      = ""
    sqs_access_keys = ""
    sqs_secret_keys = ""
    sqs_regions     = ""
  }
}
