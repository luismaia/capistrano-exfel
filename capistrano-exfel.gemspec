# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/exfel/version'

Gem::Specification.new do |spec|
  spec.name          = 'capistrano-exfel'
  spec.version       = Capistrano::Exfel::VERSION
  spec.authors       = ['Luis Maia']
  spec.email         = ['luisgoncalo.maia@gmail.com']
  spec.summary       = 'Deploy Ruby on Rails 4 Applications in European-XFEL Virtual Machines'
  spec.description   = 'Deployment of Ruby on Rails 4 Applications in European-XFEL Virtual Machines ' \
                        '(Scientific Linux + Apache + RVM + Phusion Passenger) using Capistrano3 and Kerberos'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
end
