module Schedulable
  module Generators
    class SimpleFormGenerator < ::Rails::Generators::Base
      
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)
      
      def create_config
        puts 'install simple_form custom input'
        template 'inputs/schedule_input.rb', "app/inputs/schedule_input.rb"
      end
      
    end
  end
end