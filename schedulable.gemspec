$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "schedulable/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "schedulable"
  s.version     = Schedulable::VERSION
  s.authors     = ["Rafael Nowrotek"]
  s.email       = ["mail@benignware.com"]
  s.homepage    = "http://github.com/benignware"
  s.summary     = "Handling recurring events in rails."
  s.description = "Handling recurring events in rails."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.required_ruby_version = '>= 3.0.0'

  s.add_dependency "rails", ">= 7.2.0"
  s.add_dependency "ice_cube", "~> 0.17.0"
  
  s.add_development_dependency "sqlite3", "~> 1.6"
  s.add_development_dependency "rspec-rails", "~> 6.0"
  s.add_development_dependency "factory_bot_rails", "~> 6.2"
  s.add_development_dependency "database_cleaner-active_record", "~> 2.1"
  s.add_development_dependency "mutex_m", "~> 0.2.0"
end
