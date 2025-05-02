# frozen_string_literal: true

require 'json'

EXPECTED_RESTRICTED_A_RRS = ['199.36.153.4', '199.36.153.5', '199.36.153.6', '199.36.153.7'].freeze
EXPECTED_RESTRICTED_AAAA_RRS = ['2600:2d00:2:1000::'].freeze
EXPECTED_PRIVATE_A_RRS = ['199.36.153.8', '199.36.153.9', '199.36.153.10', '199.36.153.11'].freeze
EXPECTED_PRIVATE_AAAA_RRS = ['2600:2d00:2:2000::'].freeze

# rubocop:disable Metrics/BlockLength
control 'records' do
  title 'Ensure googleapis.com Cloud DNS zone has the correct records'
  impact 1.0
  name = input('input_name')
  project = input('input_project_id')
  use_private_access_endpoints = input('output_use_private_access_endpoints', value: false)
  addresses = JSON.parse(input('output_addresses_json'), { symbolize_names: true })
  no_custom_addresses = addresses.nil? ||
                        ((addresses[:ipv4].nil? || addresses[:ipv4].empty?) &&
                        (addresses[:ipv6].nil? || addresses[:ipv6].empty?))
  expected_a_rrs = if no_custom_addresses
                     use_private_access_endpoints ? EXPECTED_PRIVATE_A_RRS : EXPECTED_RESTRICTED_A_RRS
                   else
                     addresses[:ipv4].nil? ? [] : addresses[:ipv4]
                   end
  expected_aaaa_rrs = if no_custom_addresses
                        use_private_access_endpoints ? EXPECTED_PRIVATE_AAAA_RRS : EXPECTED_RESTRICTED_AAAA_RRS
                      else
                        addresses[:ipv6].nil? ? [] : addresses[:ipv6]
                      end

  describe google_dns_resource_record_set(project:, name: '*.googleapis.com.', type: 'CNAME',
                                          managed_zone: "#{name}-googleapis-com") do
    it { should exist }
    its('ttl') { should eq 300 }
    its('target') { should cmp 'googleapis.com.' }
  end

  describe google_dns_resource_record_set(project:, name: 'googleapis.com.', type: 'A',
                                          managed_zone: "#{name}-googleapis-com") do
    if expected_a_rrs.empty?
      it { should_not exist }
    else
      it { should exist }
      its('ttl') { should eq 300 }
      its('target') { should cmp expected_a_rrs }
    end
  end

  describe google_dns_resource_record_set(project:, name: 'googleapis.com.', type: 'AAAA',
                                          managed_zone: "#{name}-googleapis-com") do
    if expected_aaaa_rrs.empty?
      it { should_not exist }
    else
      it { should exist }
      its('ttl') { should eq 300 }
      its('target') { should cmp expected_aaaa_rrs }
    end
  end
end
# rubocop:enable Metrics/BlockLength

# rubocop:disable Metrics/BlockLength
control 'override-records' do
  title 'Ensure each additional Cloud DNS zone has the correct records'
  impact 1.0
  name = input('input_name')
  project = input('input_project_id')
  overrides = JSON.parse(input('output_overrides_json'), { symbolize_names: false })
  use_private_access_endpoints = input('output_use_private_access_endpoints', value: false)
  addresses = JSON.parse(input('output_addresses_json'), { symbolize_names: true })
  no_custom_addresses = addresses.nil? ||
                        ((addresses[:ipv4].nil? || addresses[:ipv4].empty?) &&
                        (addresses[:ipv6].nil? || addresses[:ipv6].empty?))
  expected_a_rrs = if no_custom_addresses
                     use_private_access_endpoints ? EXPECTED_PRIVATE_A_RRS : EXPECTED_RESTRICTED_A_RRS
                   else
                     addresses[:ipv4].nil? ? [] : addresses[:ipv4]
                   end
  expected_aaaa_rrs = if no_custom_addresses
                        use_private_access_endpoints ? EXPECTED_PRIVATE_AAAA_RRS : EXPECTED_RESTRICTED_AAAA_RRS
                      else
                        addresses[:ipv6].nil? ? [] : addresses[:ipv6]
                      end

  only_if('No override zones specified') do
    !(overrides.nil? || overrides.empty?)
  end

  zones = overrides.map do |n|
    { "#{name}-#{n.sub(/[^a-zA-Z0-9]/, '-')}" => n.delete_suffix('.') }
  end.reduce(:merge)
  zones.each do |zone, domain|
    describe google_dns_resource_record_set(project:, name: "*.#{domain}.", type: 'CNAME',
                                            managed_zone: zone) do
      it { should exist }
      its('ttl') { should eq 300 }
      its('target') { should cmp "#{domain}." }
    end

    describe google_dns_resource_record_set(project:, name: "#{domain}.", type: 'A', managed_zone: zone) do
      if expected_a_rrs.empty?
        it { should_not exist }
      else
        it { should exist }
        its('ttl') { should eq 300 }
        its('target') { should cmp expected_a_rrs }
      end
    end

    describe google_dns_resource_record_set(project:, name: "#{domain}.", type: 'AAAA',
                                            managed_zone: zone) do
      if expected_aaaa_rrs.empty?
        it { should_not exist }
      else
        it { should exist }
        its('ttl') { should eq 300 }
        its('target') { should cmp expected_aaaa_rrs }
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
