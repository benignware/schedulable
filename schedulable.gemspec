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

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 4.0.3"
  s.add_dependency "ice_cube"

end
