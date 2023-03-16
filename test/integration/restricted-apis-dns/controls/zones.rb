# frozen_string_literal: true

require 'json'

control 'googleapis' do
  title 'Ensure Cloud DNS zone overriding googleapis.com meets expectations'
  impact 1.0
  name = input('input_name')
  project_id = input('input_project_id')
  network_self_link = input('output_network_self_link')
  labels = JSON.parse(input('output_labels_json'), { symbolize_names: false })

  describe google_dns_managed_zone(project: project_id, zone: "#{name}-googleapis") do
    it { should exist }
    its('name') { should cmp "#{name}-googleapis" }
    its('description') { should cmp 'Override googleapis.com domain to use restricted.googleapis.com endpoints' }
    its('dns_name') { should cmp 'googleapis.com.' }
    its('visibility') { should cmp 'private' }
    its('private_visibility_config') { should_not be_nil }
    its('private_visibility_config.networks') { should_not be_empty }
    its('private_visibility_config.networks.first.network_url') { should cmp network_self_link }
    its('labels') { should cmp labels }
  end
end

control 'overrides' do
  title 'Ensure additional Cloud DNS zone meets expectations'
  impact 1.0
  name = input('input_name')
  project_id = input('input_project_id')
  overrides = JSON.parse(input('output_overrides_json'), { symbolize_names: false })
  network_self_link = input('output_network_self_link')
  labels = JSON.parse(input('output_labels_json'), { symbolize_names: false })

  only_if('No override zones specified') do
    !overrides.empty?
  end

  zones = overrides.map do |n|
    { "#{name}-#{n.sub(/[^a-zA-Z0-9]/, '-')}" => n.delete_suffix('.') }
  end.reduce(:merge)
  zones.each do |zone, domain|
    describe google_dns_managed_zone(project: project_id, zone: zone) do
      it { should exist }
      its('description') { should cmp "Override #{domain} domain to use restricted.googleapis.com private endpoints" }
      its('dns_name') { should cmp "#{domain}." }
      its('visibility') { should cmp 'private' }
      its('private_visibility_config') { should_not be_nil }
      its('private_visibility_config.networks') { should_not be_empty }
      its('private_visibility_config.networks.first.network_url') { should cmp network_self_link }
      its('labels') { should cmp labels }
    end
  end
end
