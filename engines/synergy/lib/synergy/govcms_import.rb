
require 'yaml'
require 'pry' if Rails.env.development? || Rails.env.test?

require 'synergy/adapters/gov_cms_adapter'

module Synergy
  class GovCMSImport
    ADAPTERS = {
      "GovCMS" => Synergy::Adapters::GovCMSAdapter
    }.freeze

    def self.run
      config_path = File.join(Rails.root, "config/synergy.yml")
      config = YAML.load_file(config_path)

      config["synergies"].each_pair do |source_name, source_config|
        adapter = ADAPTERS[source_config["type"]].new(
          source_name,
          source_config["url"]
        )
        ActiveRecord::Base.transaction(isolation: :read_committed) do
          adapter.log "deleting existing nodes"
          Synergy::Node.where(source_name: source_name).delete_all
          adapter.log "finished deleting existing nodes"

          adapter.run do |node_data|
            source_parts      = node_data[:path]
            destination_parts = source_config["destination_path"].split("/")
            parts             = destination_parts + source_parts

            parts.reduce(nil) do |parent_s_node,slug|
              Synergy::Node.find_or_create_by!(source_name: source_name, parent: parent_s_node, slug: slug) do |sn|
                sn.content    = node_data[:content]
                sn.title      = node_data[:title]
                sn.source_url = node_data[:source_url]
              end
            end
          end
        end
      end
    end
  end
end
