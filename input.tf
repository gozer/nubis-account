variable account_name {}

variable atlas_token {
  default = "anonymous"
}

variable nubis_version {
  default = "v1.0.1-sec1"
}

variable arenas {
  type    = "list"
  default = ["core"]
}

variable arenas_networks {
  type    = "list"
  default = ["172.16.0.0/16"]
}

variable admin_users {
  default = "gozer,limed,jcrowe"
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
    secret      = ""
    sudo_groups = "nubis_global_admins"
    user_groups = ""
    version     = ""
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
    mig                    = 0
    ci                     = 0
    vpn                    = 0
    nat                    = 1
    opsec                  = 0
    user_management_iam    = 0
    user_management_consul = 1
    monitoring             = 0
    sso                    = 1
    pagerduty              = 1
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

variable nat {
  default = {
    sudo_groups = "nubis_global_admins"
    user_groups = ""
    version     = ""
  }
}

variable ci {
  default = {
    project           = "skel"
    git_repo          = "https://github.com/nubisproject/nubis-skel.git"
    admins            = "gozer"
    slack_domain      = "nubisproject"
    slack_channel     = "#changes"
    slack_token       = "unset"
    sudo_groups       = "nubis_global_admins"
    user_groups       = ""
    version           = ""
    instance_type     = "t2.micro"
    root_storage_size = "0"
    newrelic_api_key  = ""
  }
}

variable pagerduty {
  default = {
    token                                      = ""
    enable_pagerduty                           = ""
    team_name                                  = ""
    platform_critical_escalation_policy        = "nubis"
    platform_non_critical_escalation_policy    = "nubis"
    application_critical_escalation_policy     = "nubis"
    application_non_critical_escalation_policy = "nubis"
  }
}

variable monitoring {
  default = {
    slack_url                                      = ""
    slack_channel                                  = "#monitoring"
    notification_email                             = "nubis-team@mozilla.com"
    sudo_groups                                    = "nubis_global_admins"
    user_groups                                    = ""
    password                                       = ""
    version                                        = ""
    instance_type                                  = "t2.small"
    swap_size_meg                                  = "2048"
    pagerduty_critical_platform_service_key        = ""
    pagerduty_non_critical_platform_service_key    = ""
    pagerduty_critical_application_service_key     = ""
    pagerduty_non_critical_application_service_key = ""
  }
}

variable vpn {
  default = {
    ipsec_target           = "63.245.214.100"
    destination_cidr_block = "10.0.0.0/8"
    bgp_asn                = "65022"
    output_config          = false
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
    sudo_groups        = "nubis_global_admins,nubis_sudo_users"
    user_groups        = "nubis_users"
  }
}

variable jumphost {
  default = {
    sudo_groups = "nubis_global_admins"
    user_groups = ""
    version     = ""
  }
}

variable sso {
  default = {
    openid_client_id     = ""
    openid_client_secret = ""
    sudo_groups          = "nubis_global_admins"
    user_groups          = ""
    version              = ""
  }
}

variable fluentd {
  default = {
    sqs_queues      = ""
    sqs_access_keys = ""
    sqs_secret_keys = ""
    sqs_regions     = ""
    instance_type   = ""
    sudo_groups     = "nubis_global_admins"
    user_groups     = ""
    version         = ""
  }
}

variable instance_mfa {
  default = {
    ikey     = ""
    skey     = ""
    host     = ""
    failmode = "secure"
  }
}
