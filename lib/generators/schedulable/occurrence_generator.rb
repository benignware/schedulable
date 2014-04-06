require 'active_support/core_ext/module/introspection'
require 'rails/generators/base'
require 'rails/generators/generated_attribute'

module Schedulable
  module Generators
    class OccurrenceGenerator < ::Rails::Generators::NamedBase
      
      argument :attributes, type: :array, default: [], banner: "field[:type][:index] field[:type][:index]"
      
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)
      
      def self.next_migration_number(path)
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      end
      
      def create_migrations
        puts 'create schedulable occurrence model'
        migration_template 'migrations/create_occurrences.erb', "db/migrate/create_#{name.tableize}.rb", {name: self.name, attributes: self.attributes}
        template 'models/occurrence.erb', "app/models/#{name.tableize.singularize}.rb", {name: self.name, attributes: self.attributes}
      end
      
      
    end
  end
end