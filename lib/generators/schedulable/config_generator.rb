module Schedulable
  module Generators
    class ConfigGenerator < ::Rails::Generators::Base
      
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)
      
      def create_config
        puts 'install schedulable config'
        template 'config/schedulable.rb', "config/initializers/schedulable.rb"
      end
      
    end
  end
end