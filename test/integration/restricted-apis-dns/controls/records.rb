# frozen_string_literal: true

require 'json'

EXPECTED_CNAME_RRS = ['restricted.googleapis.com.'].freeze
EXPECTED_A_RRS = ['199.36.153.4', '199.36.153.5', '199.36.153.6', '199.36.153.7'].freeze

control 'records' do
  title 'Ensure googleapis.com Cloud DNS zone has the correct records'
  impact 1.0
  name = input('input_name')
  project_id = input('input_project_id')

  describe google_dns_resource_record_set(project: project_id, name: '*.googleapis.com.', type: 'CNAME',
                                          managed_zone: "#{name}-googleapis") do
    it { should exist }
    its('ttl') { should eq 300 }
    its('target') { should cmp EXPECTED_CNAME_RRS }
  end

  describe google_dns_resource_record_set(project: project_id, name: 'restricted.googleapis.com.', type: 'A',
                                          managed_zone: "#{name}-googleapis") do
    it { should exist }
    its('ttl') { should eq 300 }
    its('target') { should cmp EXPECTED_A_RRS }
  end
end

control 'override-records' do
  title 'Ensure each additional Cloud DNS zone has the correct records'
  impact 1.0
  name = input('input_name')
  project_id = input('input_project_id')
  overrides = JSON.parse(input('output_overrides_json'), { symbolize_names: false })

  only_if('No override zones specified') do
    !overrides.empty?
  end

  zones = overrides.map do |n|
    { "#{name}-#{n.sub(/[^a-zA-Z0-9]/, '-')}" => n.delete_suffix('.') }
  end.reduce(:merge)
  zones.each do |zone, domain|
    describe google_dns_resource_record_set(project: project_id, name: "*.#{domain}.", type: 'CNAME',
                                            managed_zone: zone) do
      it { should exist }
      its('ttl') { should eq 300 }
      its('target') { should cmp EXPECTED_CNAME_RRS }
    end
    describe google_dns_resource_record_set(project: project_id, name: "#{domain}.", type: 'A', managed_zone: zone) do
      it { should exist }
      its('ttl') { should eq 300 }
      its('target') { should cmp EXPECTED_A_RRS }
    end
  end
end
