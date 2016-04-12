require 'rails'
require 'i18n'
module Schedulable
  class Railtie < ::Rails::Railtie
    
    railtie_name :schedulable
    
    # requires all dependencies
    Gem.loaded_specs['schedulable'].dependencies.each do |d|
     require d.name
    end
    
    # application configuration initializer
    config.schedulable = ActiveSupport::OrderedOptions.new # enable namespaced configuration in Rails environments
  
    initializer "schedulable.configure" do |app|
      Schedulable.configure do |config|
        
        # copy parameters from application configuration
        config.form_helper = app.config.schedulable[:form_helper]
        config.simple_form = app.config.schedulable[:simple_form]
        config.max_build_count = app.config.schedulable[:max_build_count]
        config.max_build_period = app.config.schedulable[:max_build_period]
        
      end
    end
   
    initializer "schedulable.view" do
      ActiveSupport.on_load :action_view do
        include Schedulable::FormHelper
      end
    end
    
    initializer "schedulable.locales" do
      
      Dir[File.join("#{File.dirname(__FILE__)}/../../config/locales/*.yml")].each do |locale|
        I18n.load_path.unshift(locale)
      end
   
    end
    
    # rake tasks
    rake_tasks do
      load "tasks/schedulable_tasks.rake"
    end
    
  end
end