# XFEL application specific tasks
namespace :application do
  # Task 'application:deploy_first_time' deploys an application for the first time in the configured server(s).
  # This task besides deploying the application also make all the necessary configurations
  desc 'Configures Apache and deploys the Application for the first time in the configured server(s) ' \
       'with the right permissions'
  task :deploy_first_time do
    on roles(:app, :web) do
      info '#' * 100
      info '#' * 10 + ' => Start Application first time deployment...'
      info '#' * 100

      invoke 'app_home:create_all'
      invoke 'database:configure_mysql'
      invoke 'secrets:configure'
      invoke 'apache:configure_and_start'
      invoke 'apache:check_write_permissions'
      invoke :deploy
      invoke 'app_home:correct_shared_permissions'
      invoke 'application:restart'
    end
  end

  # Task 'application:deploy' deploys a new version of the application in the configured server(s)
  desc 'Re-deploys existent Application in the configured server(s)'
  task :deploy do
    on roles(:app, :web) do
      info '#' * 100
      info '#' * 10 + ' => Start Application re-deployment...'
      info '#' * 100

      # This is advisable to kill users cookies after the upgrade.
      # The consequence is that users will be logged out automatically from the Application after the upgrade.
      # This is important to avoid errors with old validity_token in forms
      invoke 'secrets:update_app_secret'

      invoke :deploy
      invoke 'application:restart'
    end
  end

  desc 'Restarts the application, including reloading server cache'
  task :restart do
    # invoke 'app_home:restart'
    invoke 'apache:restart'
    invoke 'app_home:reload_server_cache'
    invoke 'app_home:deploy_success_msg'
  end

  desc 'Re-deploys apache configuration files and restart it'
  task :reconfigure_apache do
    invoke 'apache:configure'
    invoke 'application:restart'
  end

  desc 'Shows variables values generated without deploying anything'
  task :show_variables do
    on roles(:app, :web) do
      info '#' * 100
      info "username => #{fetch(:username)}"
      info 'password => **********'
      info "rails_env => #{fetch(:rails_env)}"
      info "app_name => #{fetch(:app_name)}"
      info "app_domain => #{fetch(:app_domain)}"
      info "default_app_uri => #{fetch(:default_app_uri)}"
      info "app_name_uri => #{fetch(:app_name_uri)}"
      info "app_full_url => #{fetch(:app_full_url)}"
      info "deploy_to => #{fetch(:deploy_to)}"
      info "shared_path => #{fetch(:shared_path)}"
      info "repo_url => #{fetch(:repo_url)}"
      info "branch => #{fetch(:branch)}"
      info "scm => #{fetch(:scm)}"
      info "format => #{fetch(:format)}"
      info "log_level => #{fetch(:log_level)}"
      info "pty => #{fetch(:pty)}"
      info "linked_files => #{fetch(:linked_files)}"
      info "linked_dirs => #{fetch(:linked_dirs)}"
      info "keep_releases => #{fetch(:keep_releases)}"
      info "use_sudo => #{fetch(:use_sudo)}"
      info "app_group_owner => #{fetch(:app_group_owner)}"
      info "apache_document_root => #{fetch(:apache_document_root)}"
      info "apache_deploy_symbolic_link => #{fetch(:apache_deploy_symbolic_link)}"
      info "tmp_dir => #{fetch(:tmp_dir)}"
      info '#' * 100
    end
  end
end

namespace :load do
  task :defaults do
    # Set username and password
    ask :username, proc { `whoami`.chomp }.call
    set :password, -> { ask('password', nil, echo: false) }

    # Application Name
    set :app_name, -> { ask('Please specify the application name (i.e. my_app)', 'my_app') }

    # Set application related information
    set :app_domain, -> do
      ask('Please specify the application domain (i.e. https://in.xfel.eu/)', 'https://in.xfel.eu/')
    end

    # Build default application URI
    set :default_app_uri, -> { "#{get_rails_env_abbr}_#{fetch(:app_name)}" }

    set :app_name_uri, -> do
      ask("Please specify the application URI (i.e. #{fetch(:default_app_uri)})", fetch(:default_app_uri))
    end

    set :app_full_url, -> { "#{fetch(:app_domain)}#{fetch(:app_name_uri)}" }

    # Default deploy_to directory value is /var/www/
    set :deploy_to, -> { File.join('/data', fetch(:app_name_uri)) }

    # Shared folder inside deployment directory
    set :shared_path, -> { File.join(fetch(:deploy_to), 'shared') }

    # Set git repository information
    set :repo_url, -> { '' }

    # Default branch is :master
    ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

    # Default value for :scm is :git
    set :scm, -> { :git }

    # Default value for :format is :pretty
    set :format, -> { :pretty }

    # Default value for :log_level is :debug
    set :log_level, -> { :info }

    # Default value for :pty is false
    set :pty, -> { true }

    # Default value for :linked_files is []
    set :linked_files, -> { %w(config/database.yml config/secrets.yml) }

    # Default value for linked_dirs is []
    set :linked_dirs, -> { %w(bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system) }

    # Default value for keep_releases is 5
    set :keep_releases, -> { 5 }

    # Sudo related information
    set :use_sudo, -> { true }
    set :app_group_owner, -> { 'exfl_itdm' }

    # Capistrano::Rails
    #
    # Defaults to 'assets' this should match config.assets.prefix in your rails config/application.rb
    # set :assets_prefix, 'prepackaged-assets'
    #
    # set :assets_roles, [:web, :app] # Defaults to [:web]
    #
    # If you need to touch public/images, public/javascripts and public/stylesheets on each deploy:
    # set :normalize_asset_timestamps, %{public/images public/javascripts public/stylesheets}

    # Bundle
    # set :bundle_flags, '--quiet' # '--deployment --quiet' is the default

    # RVM related information
    set :rvm_type, -> { :system }
    set :rvm_ruby_version, -> { ask('Please specify the Ruby version (i.e. 2.1.5)', '') }
    set :rvm_roles, [:app, :web]
    # set :rvm_custom_path, '~/.myveryownrvm'  # only needed if not detected

    # Apache related information
    set :apache_document_root, -> { '/var/www/html/' }
    set :apache_deploy_symbolic_link, -> { "#{fetch(:apache_document_root)}#{fetch(:app_name_uri)}" }

    # set :tmp_dir, '/home/dh_user_name/tmp'
    set :tmp_dir, -> { File.join('/tmp', fetch(:username)) }

    # Set umask for remote commands
    SSHKit.config.umask = '0002'

    # Map commands
    SSHKit.config.command_map[:rake] = 'bundle exec rake'
    SSHKit.config.command_map[:rails] = 'bundle exec rails'
  end
end
