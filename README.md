# Capistrano::Exfel

Deploys Ruby on Rails Applications in EXFEL VMs using Capistrano3 throw username/password authentication.
The standard EXFEL VMs consist of Scientific Linux 6 with Apache.
Installation of Phusion Passenger and RVM are also required to this gem.

## Installation

Add these lines to your application's Gemfile:

    # Use Capistrano for deployment
    gem 'capistrano', '~> 3.4.0'
    gem 'capistrano-rails', '~> 1.1.2'
    gem 'capistrano-rvm', '~> 0.1.2'
    gem 'capistrano-exfel', '~> 0.0.12'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capistrano-exfel

## Usage

Add this line to your `Capfile`:

    # Load Capistrano Exfel Scientific Linux 6 tasks
    require 'capistrano/exfel/sl6'

This gem will reuse `capistrano-rails` and `capistrano-rvm` tasks to build the following tasks:

Task **application:deploy_first_time**:

    # Task 'application:deploy_first_time' deploys an application for the first time in the configured server(s).
    # This task besides deploying the application also make all the necessary configurations
    # Description: Configures Apache and deploys the Application for the first time in the configured server(s)
    # with the right permissions:
    cap application:deploy_first_time

Task **application:deploy**:

    # Task 'application:deploy' deploys a new version of the application in the configured server(s)
    # Description: Re-deploys existent Application in the configured server(s):
    cap application:deploy

Task **application:restart**:

    # Description: 'Restarts the application, including reloading server cache'
    cap application:restart

Task **application:reconfigure_apache**:

    # Description: 'Re-deploys apache configuration files and restart it'
    cap application:reconfigure_apache

Task **application:show_variables**:

    # Description: 'Shows variables values generated without deploying anything'
    cap application:show_variables

Additional Tasks:

    # See all the additional available tasks using the command:
    cap -T

The most important configurable options and their defaults:options can be added to the `deploy.rb` file:

    # Set username and password
    set :username, ask('username', 'maial') # If not specified will ask for it proposing the current user
    set :password, ask('password', nil, echo: false) # If not specified will ask for it

    # Application Name
    set :app_name, 'my_app_name' # If not specified will ask for it

    # Set application related information
    # set :app_domain, 'https://domain.com/'
    # set :app_name_uri, 'my_app_uri'

    # Set git repository information
    set :repo_url, 'exfl_git_server:/my_app_repo_path' # 'git@example.com:me/my_repo.git'

    # Default branch is :master
    # ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

    # Default value for :scm is :git
    # set :scm, :git

    # Default value for :format is :pretty
    # set :format, :pretty

    # Default value for :log_level is :debug
    # set :log_level, :info

    # Default value for :linked_files is []
    # set :linked_files, %w(config/database.yml config/secrets.yml)

    # Default value for linked_dirs is []
    # set :linked_dirs, %w(bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system)

    # Default value for keep_releases is 5
    # set :keep_releases, 5

    # RVM related information
    # set :rvm_type, :system
    set :rvm_ruby_version, '2.1.5' # If not specified will ask for it
    # set :rvm_roles, [:app, :web]

## Contributing

1. Fork it ( https://github.com/luismaia/capistrano-exfel/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
