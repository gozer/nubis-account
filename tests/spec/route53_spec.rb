require 'spec_helper'
require 'pp'

top_zone_name = Nubis.account_name + '.' + Nubis.domain_name

describe route53_hosted_zone(top_zone_name) do
  it { should exist }
  its(:resource_record_set_count) { should eq 6 }

  its(:config) { should have_attributes(:private_zone => false) }
  
  it { should have_record_set('version.nubis.' + top_zone_name).txt('"' + Nubis.version + '"') }
  
  # Not sure how to reliably detect for this
  #it { should have_record_set('state.nubis.' + top_zone_name).alias('d3sp27okm1yibd.cloudfront.net.', 'Z2FDTNDATAQYW2') }
end

for region in Nubis.supported_regions
  describe route53_hosted_zone(region + '.' + top_zone_name) do
    it { should exist }
    its(:config) { should have_attributes(:private_zone => false) }
  end
end

for region in Nubis.regions
  for environment in Nubis.environments
    for service in [ "consul", "proxy" ]
      describe route53_hosted_zone(service + '.' + environment + '.' + region + '.' + top_zone_name) do
        it { should exist }
	its(:resource_record_set_count) { should eq 3 }
        its(:config) { should have_attributes(:private_zone => true) }
      end
    end
  end
end
