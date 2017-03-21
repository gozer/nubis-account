require 'spec_helper'

describe lambda('UUID') do
  it { should exist }
  its(:runtime) { should eq 'nodejs4.3' }
  its(:handler) { should eq 'index.handler' }
  its(:timeout) { should eq 10 }
  its(:memory_size) { should eq 128 }
end

for environment in Nubis.environments
  describe lambda('user_management-' + environment ) do
    it { should exist }
    its(:runtime) { should eq 'nodejs4.3' }
    its(:handler) { should eq 'index.handler' }
    its(:timeout) { should eq 30 }
    its(:memory_size) { should eq 128 }
  end
end


