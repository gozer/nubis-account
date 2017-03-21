require 'spec_helper'

describe "vpcs" do
  Nubis.regions.each do |region|
    Nubis.environments.each do |environment|
      describe vpc("#{region}-#{environment}-vpc") do
        it { should exist }
        it { should be_available }
	
	#its(:cidr_block) { should eq '10.164.27.0/24' }
	
        it { should have_route_table("PrivateRoute-#{environment}-AZ1") }
        it { should have_route_table("PrivateRoute-#{environment}-AZ2") }
        it { should have_route_table("PrivateRoute-#{environment}-AZ3") }
	
	it { should have_route_table("PublicRoute-#{environment}") }

        #it { should have_route_table('rtb-75b20712') }
        #it { should have_network_acl('acl-d52de6b2') }
      end
    end
  end
end
