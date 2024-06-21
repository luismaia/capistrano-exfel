# frozen_string_literal: true

# apache tasks

namespace :apache do
  desc 'Configure Apache (httpd) and restart it'
  task :configure_and_start do
    invoke 'apache:configure'
    invoke 'apache:replace_apache_defaults' # This task should go to Puppet or installation script
    invoke 'apache:create_symbolic_link'
  end

  desc 'Restart Apache (httpd) service'
  task :restart do
    on roles(:web) do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50

      debug 'systemctl stop apache2'
      execute "#{sudo_cmd} systemctl stop apache2"

      debug 'pkill -9 apache2 || true'
      execute "#{sudo_cmd} pkill -9 apache2 || true"

      debug 'systemctl start apache2'
      execute "#{sudo_cmd} systemctl start apache2"

      info 'Restarted Apache (apache2) service'
      debug '#' * 50
    end
  end

  desc 'Configure Apache configuration files'
  task :configure do
    invoke 'apache:create_apache_shared_folder'
    invoke 'apache:configure_app_ssl_conf_file'
  end

  desc 'Configure (HTTPS) Apache Application configuration files'
  task :configure_app_ssl_conf_file do
    on roles(:app), in: :sequence do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50
      debug 'Configure (HTTPS) Apache Application configuration files'

      set :shared_apache_conf_ssl_file, "#{fetch(:shared_apache_path)}/app_#{fetch(:app_name_uri)}_ssl.conf"
      http_ssl_file = File.expand_path('../recipes/apache/app_ssl.conf', __dir__)
      upload! StringIO.new(File.read(http_ssl_file)), fetch(:shared_apache_conf_ssl_file).to_s

      debug "chmod g+w #{fetch(:shared_apache_conf_ssl_file)}"
      execute "chmod g+w #{fetch(:shared_apache_conf_ssl_file)}"

      passenger_root = get_command_output("/usr/local/rvm/bin/rvm #{fetch(:rvm_ruby_version)} do passenger-config --root")
      ruby_path = "/#{passenger_root.split('/')[1..5].join('/')}/wrappers/ruby"

      execute "sed -i 's/<<APPLICATION_NAME>>/#{fetch(:app_name_uri)}/g' #{fetch(:shared_apache_conf_ssl_file)}"
      execute "sed -i 's/<<ENVIRONMENT>>/#{fetch(:environment)}/g' #{fetch(:shared_apache_conf_ssl_file)}"
      execute "sed -i 's|<<RUBY_PATH>>|#{ruby_path}|g' #{fetch(:shared_apache_conf_ssl_file)}"

      execute "#{sudo_cmd} a2ensite #{fetch(:shared_apache_conf_ssl_file)}"

      debug '#' * 50
    end
  end

  desc 'Check that the user has write permissions in the Deploy and in Apache DocumentRoot folders'
  task :check_write_permissions do
    invoke 'apache:check_write_permissions_on_deploy'
    invoke 'apache:check_write_permissions_on_document_root'
  end

  desc 'Check that we have the right permission to the folder the app should be deployed to'
  task :check_write_permissions_on_deploy do
    on roles(:app), in: :sequence do |host|
      debug '#' * 50
      debug "Checking folder '#{fetch(:deploy_to)}' (where the application has to be deployed) "\
            "for the right permissions on Host '#{host}'"

      if test("[ -w #{fetch(:deploy_to)} ]")
        info "#{fetch(:deploy_to)} is writable on #{host}"
      else
        error "#{fetch(:deploy_to)} is not writable on #{host}"
      end

      debug '#' * 50
    end
  end

  desc 'Check that we have the right permission to the Apache DocumentRoot folder'
  task :check_write_permissions_on_document_root do
    on roles(:web) do |host|
      debug '#' * 50
      debug "Checking Apache DocumentRoot folder (#{fetch(:apache_document_root)}) permissions on Host '#{host}'"

      if test("[ -w #{fetch(:apache_document_root)} ]")
        info "#{fetch(:apache_document_root)} is writable on #{host}"
      else
        info "#{fetch(:apache_document_root)} is not writable on #{host}"
      end

      debug '#' * 50
    end
  end

  desc 'Create Apache configuration files shared folder'
  task :create_apache_shared_folder do
    on roles(:app) do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50
      debug 'Create Apache configuration files shared folder'

      debug "mkdir -p #{fetch(:shared_apache_path)}"
      execute "#{sudo_cmd} mkdir -p #{fetch(:shared_apache_path)}"

      debug "chmod g+ws #{fetch(:shared_apache_path)}"
      execute "#{sudo_cmd} chmod g+ws #{fetch(:shared_apache_path)}"

      debug '#' * 50
    end
  end

  desc 'Create symbolic link to application public folder in Apache DocumentRoot folder'
  task :create_symbolic_link do
    on roles(:web), in: :sequence do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      info '#' * 50
      info 'Creating application symbolic link'

      debug "ln -sfn #{fetch(:deploy_to)}/current/public #{fetch(:apache_deploy_symbolic_link)}"
      execute "#{sudo_cmd} ln -sfn #{fetch(:deploy_to)}/current/public #{fetch(:apache_deploy_symbolic_link)}"

      info '#' * 50
    end
  end
end
