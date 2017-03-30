require 'awspec'
require 'rhcl'
require 'pp'


class Nubis
  @@hcl = Rhcl.parse(File.read(ENV['NUBIS_ACCOUNT_VARS']))
  
  #pp @@hcl

  def self.account_id
    @@sts ||= Aws::STS::Client.new()
    @@aws_identity ||= @@sts.get_caller_identity({})
    @@aws_identity.account
  end

  def self.account_name
    @@hcl['account_name']
  end
  
  def self.admin_users
    @@hcl['admin_users'].split(',').sort()
  end
  
  def self.supported_regions
    [ "us-west-2", "us-east-1" ]
  end
  
  def self.version
    @@hcl['nubis_version']
  end
  
  def self.environments
    @@hcl['environments'].split(',')
  end

  def self.regions
    @@hcl['aws_regions'].split(',')
  end
  
  def self.hcl
    @@hcl
  end
  
  def self.domain_name
    "nubis.allizom.org."
  end
end
