# -*- encoding: utf-8 -*-
require File.expand_path('../lib/bernstein/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Anthony Plekhov"]
  gem.email         = ["anthony.plekhov@gmail.com"]
  gem.description   = gem.summary = "Ruby OSC message queue"
  gem.license       = "MIT"

  gem.executables   = ['bernstein']
  gem.files         = `git ls-files'`.split("\n")
  gem.test_files    = `git ls-files -- spec/*`.split("\n")
  gem.name          = "bernstein"
  gem.require_paths = ["lib"]
  gem.version       = Bernstein::VERSION
  gem.add_dependency                  'redis', '>= 3.1.0'
  gem.add_dependency                  'redis-namespace', '>= 1.5.1'
  gem.add_dependency                  'eventmachine', '>= 1.0.3'
  gem.add_dependency                  'json', '>= 1.8.1'
  gem.add_dependency                  'daemons', '>= 1.1.9'
  gem.add_dependency                  'ruby-osc', '>= 0.31.0'
  gem.add_development_dependency      'rspec', '>= 3.1.0'
end
