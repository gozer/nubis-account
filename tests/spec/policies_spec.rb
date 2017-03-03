require 'spec_helper'

account_name = Nubis.account_name

describe iam_policy('cloud_health_policy') do
  it { should exist }
  it { should be_attachable }

  its(:attachment_count) { should eq 1 }
  it { should_not be_attached_to_user }
  it { should_not be_attached_to_group }
  it { should     be_attached_to_role('cloud_health_role') }
end

describe iam_policy('mfa-access') do
  it { should exist }
  it { should be_attachable }

  its(:attachment_count) { should eq 1 }
  it { should_not be_attached_to_user }
  it { should     be_attached_to_group('Administrators') }
  it { should_not be_attached_to_role }
end

describe iam_policy('ReadOnlyAccess') do
  it { should exist }
  it { should be_attachable }
  its(:arn) { should eq 'arn:aws:iam::aws:policy/ReadOnlyAccess' }
  its(:attachment_count) { should eq 2 }
  it { should_not be_attached_to_user }
  it { should     be_attached_to_group('ReadOnlyUsers') }
  it { should     be_attached_to_role('readonly') }
end

describe iam_policy('AdministratorAccess') do
  it { should exist }
  it { should be_attachable }
  its(:arn) { should eq 'arn:aws:iam::aws:policy/AdministratorAccess' }
  it { should_not be_attached_to_user }
  it { should_not be_attached_to_group }
  it { should be_attached_to_role }
end

#for region in Nubis.regions
#  for environment in Nubis.environments
#
#    attached_roles = [
#        'consul-' + environment + '-' + region,
#	'fluent-collector-' + environment + '-' + region,
#	'prometheus-' + environment + '-' + region,
#	'nubis-nat-role-' + environment + '-' + region,
#	'user_management-' + region + '-' + environment,
#    ]
#    
#    if "admin" == environment
#      attached_roles << 'ci-' + environment + '-' + region
#    end
#
#    describe iam_policy('credstash-' + environment + '-' + region) do
#    
#      pp attached_roles
#    
#      it { should exist }
#      it { should be_attachable }
#      it { should_not be_attached_to_user }
#      it { should_not be_attached_to_group }
#    
#      its(:attachment_count) { should eq attached_roles.length }
#       
#       for role in attached_roles
#         it ("should be attached to #{role}") { should be_attached_to_role(role) }
#       end
#
#    end
#   
#  end
#end
#
