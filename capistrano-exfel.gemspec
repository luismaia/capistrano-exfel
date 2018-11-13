lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/exfel/version'

Gem::Specification.new do |spec|
  spec.name          = 'capistrano-exfel'
  spec.version       = Capistrano::Exfel::VERSION
  spec.authors       = ['Luis Maia', 'Maurizio Manetti']
  spec.email         = %w[luisgoncalo.maia@gmail.com maurizio.manetti@xfel.eu]
  spec.summary       = 'Deploy Ruby on Rails 4 and 5 Applications in EXFEL Virtual Machines'
  spec.description = 'Deployment of Ruby on Rails Applications in EXFEL Virtual Machines ' \
                        '(Scientific Linux / CentOS 7 / Ubuntu 14 + Apache + RVM + Phusion Passenger) ' \
                        'using Capistrano3 and LDAP'
  spec.homepage      = 'https://github.com/luismaia/capistrano-exfel'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'rake', '~> 12.0'
end
