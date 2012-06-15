$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "vivi/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "vivi"
  s.version     = Vivi::VERSION
  s.authors     = ["Jason Williams"]
  s.email       = ["whodatforkin@gmail.com"]
  s.homepage    = "https://github.com/who-dat/vivi"
  s.summary     = "Vrrrrooommm."
  s.description = "Vrrrrooommm."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.1.1"
  s.add_dependency "jquery-rails"
  
  s.add_dependency "sqlite3"
  s.add_dependency "mysql2"
  
  s.add_dependency "nokogiri"
  s.add_dependency "acts-as-taggable-on"
  s.add_dependency "rmagick"
  s.add_dependency "rvideo"
  s.add_dependency "uuidtools" 
  s.add_dependency "rubyzip"
  s.add_dependency "delayed_job_active_record"
  
  s.add_dependency "paperclip"
  
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "capybara"
  
end
