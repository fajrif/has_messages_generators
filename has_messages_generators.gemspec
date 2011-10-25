$:.push File.expand_path("../lib", __FILE__)

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "has_messages_generators"
  s.version     = "0.0.1"
  s.authors     = "Fajri Fachriansyah"
  s.email       = "fajri82@gmail.com"
  s.homepage    = "http://https://github.com/fajrif/has_messages"
  s.summary     = "Simple messaging generators for Rails 3.x"
  s.description = "This is just a simple messaging generators for Rails 3.x, enable user to sending messages across the app."

  s.files = Dir["lib/**/*"] + ["MIT-LICENSE", "README.mdown"]
  
  s.add_dependency('rails', '>= 3.0.0')
  
end
