module Schedulable
  module Generators
    class LocaleGenerator < ::Rails::Generators::Base
      
      argument :locale, :type => :string, :default => "en"  
      
      source_root File.expand_path('../templates', __FILE__)
      
      def create_locale
        puts 'install locale'
        template "../../../../config/locales/#{locale}.yml", "config/locales/schedulable.#{locale}.yml"
      end
      
    end
  end
end