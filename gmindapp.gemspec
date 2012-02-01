Gem::Specification.new do |s|
  s.name        = "gmindapp"
  s.version     = "0.0.1"
  s.author      = "Songrit Leemakdej"
  s.email       = "songrit@gmail.com"
  s.homepage    = "http://github.com/songrit/gmindapp"
  s.summary     = "Generate app from mind map."
  s.description = "Generate application from mind map."

  s.files        = Dir["{app,lib,spec}/**/*", "[A-Z]*", "init.rb"] - ["Gemfile.lock"]
  s.require_path = "lib"

  # s.add_dependency 'faye'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 2.8.0'
  # s.add_development_dependency 'jasmine', '>= 1.1.1'

  s.rubyforge_project = s.name
  s.required_rubygems_version = ">= 1.3.4"
end
