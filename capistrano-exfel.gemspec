# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/exfel/version'

Gem::Specification.new do |spec|
  spec.name                  = 'capistrano-exfel'
  spec.version               = Capistrano::Exfel::VERSION
  spec.authors               = ['Luis Maia', 'Maurizio Manetti']
  spec.email                 = %w[luisgoncalo.maia@gmail.com maurizio.manetti@xfel.eu]
  spec.summary               = 'Deploy Ruby on Rails 4, 5, 6 and 7 Applications in EuXFEL Virtual Machines'
  spec.description           = 'Deployment of Ruby on Rails Applications in EuXFEL Virtual Machines ' \
                                '(Ubuntu 22.04 + Apache + RVM + Phusion Passenger) ' \
                                'using Capistrano3 and LDAP'
  spec.homepage              = 'https://github.com/luismaia/capistrano-exfel'
  spec.license               = 'MIT'

  spec.files                 = `git ls-files -z`.split("\x0")
  spec.executables           = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files            = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths         = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
end
