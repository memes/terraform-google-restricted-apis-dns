# frozen_string_literal: true

require 'json'
require 'rspec/expectations'

RSpec::Matchers.define :be_a_superset_of do |subset|
  match do |superset|
    superset >= subset
  end
end

control 'googleapis' do
  title 'Ensure Cloud DNS zone overriding googleapis.com meets expectations'
  impact 1.0
  name = input('input_name')
  project = input('input_project_id')
  network_self_links = JSON.parse(input('output_network_self_links_json'), { symbolize_names: false }).sort
  labels = JSON.parse(input('output_labels_json'), { symbolize_names: false })

  resource = google_dns_managed_zone(project:, zone: "#{name}-googleapis")
  describe resource do
    it { should exist }
    its('name') { should cmp "#{name}-googleapis" }
    its('description') { should cmp 'Override googleapis.com domain to use restricted.googleapis.com endpoints' }
    its('dns_name') { should cmp 'googleapis.com.' }
    its('visibility') { should cmp 'private' }
    its('labels') { should be_a_superset_of(labels) }
    its('private_visibility_config') { should_not be_nil }
    if network_self_links.count.positive?
      describe resource.private_visibility_config.networks.map(&:network_url).sort do
        it { should cmp network_self_links }
      end
    else
      describe resource.private_visibility_config do
        its('networks') { should be_nil }
      end
    end
  end
end

# rubocop:disable Metrics/BlockLength
control 'overrides' do
  title 'Ensure additional Cloud DNS zone meets expectations'
  impact 1.0
  name = input('input_name')
  project = input('input_project_id')
  overrides = JSON.parse(input('output_overrides_json'), { symbolize_names: false })
  network_self_links = JSON.parse(input('output_network_self_links_json'), { symbolize_names: false }).sort
  labels = JSON.parse(input('output_labels_json'), { symbolize_names: false })

  only_if('No override zones specified') do
    !overrides.empty?
  end

  zones = overrides.map do |n|
    { "#{name}-#{n.sub(/[^a-zA-Z0-9]/, '-')}" => n.delete_suffix('.') }
  end.reduce(:merge)
  zones.each do |zone, domain|
    resource = google_dns_managed_zone(project:, zone:)
    describe resource do
      it { should exist }
      its('description') { should cmp "Override #{domain} domain to use restricted.googleapis.com private endpoints" }
      its('dns_name') { should cmp "#{domain}." }
      its('visibility') { should cmp 'private' }
      its('labels') { should be_a_superset_of(labels) }
      its('private_visibility_config') { should_not be_nil }
      if network_self_links.count.positive?
        describe resource.private_visibility_config.networks.map(&:network_url).sort do
          it { should cmp network_self_links }
        end
      else
        describe resource.private_visibility_config do
          its('networks') { should be_nil }
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
