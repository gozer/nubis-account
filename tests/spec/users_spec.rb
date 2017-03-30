require 'spec_helper'

account_id = Nubis.account_id

describe iam_user('datadog') do
  it { should exist }
  its(:arn) { should eq 'arn:aws:iam::' + account_id + ':user/nubis/datadog/datadog' }

  it { should have_inline_policy('datadog-readonly').policy_document(' 
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "autoscaling:Describe*",
        "cloudtrail:DescribeTrails",
        "cloudtrail:GetTrailStatus",
        "cloudwatch:Describe*",
        "cloudwatch:Get*",
        "cloudwatch:List*",
        "dynamodb:list*",
        "dynamodb:describe*",
        "ec2:Describe*",
        "ec2:Get*",
        "ecs:Describe*",
        "ecs:List*",
        "elasticache:Describe*",
        "elasticache:List*",
        "elasticloadbalancing:Describe*",
        "elasticmapreduce:List*",
        "elasticmapreduce:Describe*",
        "kinesis:List*",
        "kinesis:Describe*",
        "logs:Get*",
        "logs:Describe*",
        "logs:FilterLogEvents",
        "logs:TestMetricFilter",
        "rds:Describe*",
        "rds:List*",
        "route53:List*",
        "ses:Get*",
        "sns:List*",
        "sns:Publish",
        "sqs:GetQueueAttributes",
        "sqs:ListQueues",
        "sqs:ReceiveMessage",
        "support:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
') }
end

for admin_user in Nubis.admin_users
  describe iam_user(admin_user) do
    user_arn = 'arn:aws:iam::' + account_id + ':user/nubis/admin/' + admin_user

    it { should exist }
    it { should belong_to_iam_group("Administrators") }
    it { should_not belong_to_iam_group("ReadOnlyUsers") }
    its(:arn) { should eq user_arn }

    describe 'permission checks' do

      it { should_not be_allowed_action('ec2:*') }
      
      it { should_not be_allowed_action('iam:ChangePassword') }
      it { should_not be_allowed_action('s3:ListBucket') }
      
      it { should be_allowed_action('iam:ListVirtualMFADevices') }

      it { should be_allowed_action('iam:CreateVirtualMFADevice').resource_arn("arn:aws:iam::#{account_id}:mfa/#{admin_user}").context_entries([
        { context_key_name: 'aws:username', context_key_values: [ admin_user ], context_key_type: 'string' },
      ]) }

      it { should_not be_allowed_action('iam:CreateVirtualMFADevice').resource_arn("arn:aws:iam::#{account_id}:mfa/bob").context_entries([
        { context_key_name: 'aws:username', context_key_values: [ admin_user ], context_key_type: 'string' },
      ]) }
    
      it { should_not be_allowed_action('iam:ChangePassword').resource_arn(user_arn).context_entries([
        { context_key_name: 'aws:username', context_key_values: [ admin_user ], context_key_type: 'string' },
      ]) }

      it { should_not be_allowed_action('iam:DeactivateMFADevice').context_entries([
        { context_key_name: 'aws:MultiFactorAuthPresent', context_key_values: ["true"], context_key_type: 'boolean' }])
      }
      
      it { should_not be_allowed_action('iam:DeactivateMFADevice') }
      
      it { should be_allowed_action('iam:EnableMFADevice').resource_arn("arn:aws:iam::#{account_id}:user/nubis/admin/#{admin_user}").context_entries([
        { context_key_name: 'aws:username', context_key_values: [ admin_user ], context_key_type: 'string' },
      ]) }

      it { should_not be_allowed_action('iam:EnableMFADevice').resource_arn("arn:aws:iam::#{account_id}:user/nubis/admin/bob").context_entries([
        { context_key_name: 'aws:username', context_key_values: [ admin_user ], context_key_type: 'string' },
      ]) }

      it { should be_allowed_action('iam:ResyncMFADevice').resource_arn("arn:aws:iam::#{account_id}:user/nubis/admin/#{admin_user}").context_entries([
        { context_key_name: 'aws:username', context_key_values: [ admin_user ], context_key_type: 'string' },
      ]) }

      it { should_not be_allowed_action('iam:ResyncMFADevice').resource_arn("arn:aws:iam::#{account_id}:user/nubis/admin/bob").context_entries([
        { context_key_name: 'aws:username', context_key_values: [ admin_user ], context_key_type: 'string' },
      ]) }
      
    # Should be able to assume readonly role with MFA
    it { should be_allowed_action('sts:AssumeRole').resource_arn("arn:aws:iam::#{account_id}:role/nubis/readonly").context_entries([
      { context_key_name: 'aws:username', context_key_values: [admin_user], context_key_type: 'string' },
      { context_key_name: 'aws:MultiFactorAuthPresent', context_key_values: ["true"], context_key_type: 'boolean' }]) }

    # Should not be able to assume readonly role without MFA
    it { should_not be_allowed_action('sts:AssumeRole').resource_arn("arn:aws:iam::#{account_id}:role/nubis/readonly").context_entries([
      { context_key_name: 'aws:username', context_key_values: [admin_user], context_key_type: 'string' },
      { context_key_name: 'aws:MultiFactorAuthPresent', context_key_values: ["false"], context_key_type: 'boolean' }]) }

    # Should be able to assume its admin role with MFA
    it { should be_allowed_action('sts:AssumeRole').resource_arn("arn:aws:iam::#{account_id}:role/nubis/admin/#{admin_user}").context_entries([
      { context_key_name: 'aws:username', context_key_values: [admin_user], context_key_type: 'string' },
      { context_key_name: 'aws:MultiFactorAuthPresent', context_key_values: ["true"], context_key_type: 'boolean' }]) }

    # Should not be able to assume its admin role without MFA
    it { should_not be_allowed_action('sts:AssumeRole').resource_arn("arn:aws:iam::#{account_id}:role/nubis/admin/#{admin_user}").context_entries([
      { context_key_name: 'aws:username', context_key_values: [admin_user], context_key_type: 'string' },
      { context_key_name: 'aws:MultiFactorAuthPresent', context_key_values: ["false"], context_key_type: 'boolean' }]) }

    describe 'Shouldnt be able to assume arbitrary roles' do

      # With MFA
      it { should_not be_allowed_action('sts:AssumeRole').resource_arn("arn:aws:iam::#{account_id}:role/nubis/admin/bob").context_entries([
        { context_key_name: 'aws:username', context_key_values: [admin_user], context_key_type: 'string' },
        { context_key_name: 'aws:MultiFactorAuthPresent', context_key_values: ["false"], context_key_type: 'boolean' }]) }

      # Or without
      it { should_not be_allowed_action('sts:AssumeRole').resource_arn("arn:aws:iam::#{account_id}:role/nubis/admin/bob").context_entries([
        { context_key_name: 'aws:username', context_key_values: [admin_user], context_key_type: 'string' },
        { context_key_name: 'aws:MultiFactorAuthPresent', context_key_values: ["true"], context_key_type: 'boolean' }]) }
    end    

   end
  end
end

describe iam_user('guest') do
  it { should exist }
  it { should belong_to_iam_group("ReadOnlyUsers") }
  it { should_not belong_to_iam_group("Administrators") }
  its(:arn) { should eq 'arn:aws:iam::' + account_id + ':user/nubis/guest/guest' }

  # Permission checks
  it { should be_allowed_action('ec2:DescribeInstances') }
  it { should_not be_allowed_action('ec2:TerminateInstances') }
end

describe iam_user('nubis-bootstrap') do
  it { should exist }
  its(:arn) { should eq 'arn:aws:iam::' + account_id + ':user/nubis-bootstrap' }
  it { should have_inline_policy('nubis-admin-user').policy_document('{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"*","Resource":"*"}]}') }
end
