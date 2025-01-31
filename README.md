# Capistrano::Exfel

Deploys Ruby on Rails Applications in EuXFEL VMs using Capistrano3 throw username/password authentication.
The standard EuXFEL VMs for web applications is Ubuntu 22.04 with Apache web server.
Installation of Phusion Passenger and RVM are also required to this gem.

## Installation

Add these lines to your application's Gemfile:

    # Use Capistrano for deployment
    gem 'capistrano', '3.18.1', require: false
    gem 'capistrano-exfel', '0.5.1', require: false
    gem 'capistrano-rails', '1.6.3', require: false
    gem 'capistrano-rvm', '0.1.2', require: false

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install capistrano-exfel
```

## Usage

Add this line to your `Capfile` for Ubuntu 22.04 machines:

    # Load Ubuntu 22.04 tasks
    require 'capistrano/exfel/ubuntu22'

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

```ruby
# Set username and password
set :username, ask('username', proc { `whoami`.chomp }.call) # If not specified will ask for it proposing the current user
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

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :info
# set :log_level, :debug

# Default value for :linked_files is []
# set :linked_files, %w(config/database.yml)

# Define value for linked_dirs
append :linked_dirs, 'log', 'files',
       'tmp/pids', 'tmp/cache', 'tmp/sockets',
       'vendor/bundle', '.bundle',
       'public/system', 'public/uploads'
# append :linked_files, 'config/database.yml', 'config/secrets.yml'

# Default value for keep_releases is 5
# set :keep_releases, 5

# RVM related information
set :rvm_type, :system
set :rvm_ruby_version, '3.3.0' # If not specified will ask for it
# set :rvm_roles, [:app, :web]
# set :rvm_custom_path, '~/.myveryownrvm'  # only needed if not detected

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }
# set :default_env, { rvm_bin_path: '/usr/local/rvm/bin'}

# Defaults to nil (no asset cleanup is performed)
# If you use Rails 4+ and you'd like to clean up old assets after each deploy,
# set this to the number of versions to keep
set :keep_assets, 5
```

As an example, to configure GIT plugin, add the following to the Capfile:

    require 'capistrano/scm/git'
    install_plugin Capistrano::SCM::Git

## Contributing

1. Fork it ( https://github.com/luismaia/capistrano-exfel/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
