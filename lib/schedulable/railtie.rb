require 'rails'
module Schedulable
  class Railtie < ::Rails::Railtie
    
    railtie_name :schedulable
    
    # application configuration initializer
    config.schedulable = ActiveSupport::OrderedOptions.new # enable namespaced configuration in Rails environments
  
    initializer "schedulable.configure" do |app|
      Schedulable.configure do |config|
        
        # copy parameters from application configuration
        config.max_build_count = app.config.schedulable[:max_build_count]
        config.max_build_period = app.config.schedulable[:max_build_period]
      end
    end
    
    
    # rake tasks
    rake_tasks do
      load "tasks/schedulable_tasks.rake"
    end
    
  end
end