module Schedulable
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      
      # TODO: skip-migration
      
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)
      
      def self.next_migration_number(path)
        unless @prev_migration_nr
          @prev_migration_nr = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
        else
          @prev_migration_nr += 1
        end
        @prev_migration_nr.to_s
      end
      
      def create_migrations
        puts 'install schedulable'
        migration_template 'migrations/create_schedules.rb', "db/migrate/create_schedules.rb"
        template 'models/schedule.rb', "app/models/schedule.rb"
      end
      
    end
  end
end