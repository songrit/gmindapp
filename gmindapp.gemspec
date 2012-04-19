# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "gmindapp/version"

Gem::Specification.new do |s|
  s.name        = "gmindapp"
  s.version     = Gmindapp::VERSION
  s.authors     = ["Songrit Leemakdej"]
  s.email       = ["songrit@gmail.com"]
  s.homepage    = "http://github.com/songrit/gmindapp"
  s.summary     = %q{Generate application from mind map.}
  s.description = %q{Generate application from mind map.}

  s.rubyforge_project = "gmindapp"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_runtime_dependency "rest-client"
  s.add_development_dependency 'rake'
  # s.add_development_dependency 'rspec', '~> 2.8.0'
  # s.add_development_dependency 'jasmine', '>= 1.1.1'
end
