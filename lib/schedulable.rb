require 'schedulable/railtie.rb' if defined? ::Rails::Railtie
require 'schedulable/acts_as_schedulable.rb'
require 'schedulable/schedule_support.rb'
module Schedulable
  
  class Config
    attr_accessor :max_build_count, :max_build_period
  end

  def self.config
    @@config ||= Config.new
  end

  def self.configure
    yield self.config
  end

end
