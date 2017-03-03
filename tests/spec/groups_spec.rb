require 'spec_helper'

account_id = Nubis.account_id

describe iam_group('Administrators') do
  it { should exist }
  its(:arn) { should eq 'arn:aws:iam::' + account_id + ':group/nubis/admin/Administrators' }
  it { should have_iam_policy('mfa-access') }
  it { should_not have_iam_policy('AdministratorAccess') }
end

describe iam_group('NACLAdministrators') do
  it { should exist }
  its(:arn) { should eq 'arn:aws:iam::' + account_id + ':group/nubis/NACLAdministrators' }
  it { should have_inline_policy('nacl_admins_policy').policy_document('
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:CreateNetworkAclEntry",
        "ec2:DeleteNetworkAclEntry",
        "ec2:DescribeNetworkAcls",
        "ec2:ReplaceNetworkAclEntry",
        "ec2:DescribeVpcAttribute",
        "ec2:DescribeVpcs"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
') }
end

describe iam_group('ReadOnlyUsers') do
  it { should exist }
  its(:arn) { should eq 'arn:aws:iam::' + account_id + ':group/nubis/ReadOnlyUsers' }
  it { should have_iam_policy('ReadOnlyAccess') }
end
