# frozen_string_literal: true

# apache tasks

namespace :apache do
  desc 'Configure Apache (httpd) and restart it'
  task :configure_and_start do
    invoke 'apache:configure'
    invoke 'apache:chkconfig_on' # This task should go to Puppet or installation script
    invoke 'apache:replace_apache_defaults' # This task should go to Puppet or installation script
    invoke 'apache:create_symbolic_link'
  end

  # This task should be moved into Puppet or the installation script
  desc 'Configure Apache to start at bootup'
  task :chkconfig_on do
    on roles(:web) do
      info 'In task apache:chkconfig_on'

      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50

      debug 'chkconfig httpd on'
      execute "#{sudo_cmd} chkconfig httpd on"

      info 'Configured Apache to start at bootup'
      debug '#' * 50
    end
  end

  desc 'Restart Apache (httpd) service'
  task :restart do
    on roles(:web) do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50

      debug 'service httpd stop'
      execute "#{sudo_cmd} service httpd stop"

      debug 'pkill -9 httpd || true'
      execute "#{sudo_cmd} pkill -9 httpd || true"

      debug 'service httpd start'
      execute "#{sudo_cmd} service httpd start"

      info 'Restarted Apache (httpd) service'
      debug '#' * 50
    end
  end

  desc 'Configure Apache configuration files'
  task :configure do
    invoke 'apache:create_apache_shared_folder'
    invoke 'apache:create_apache_sites_folder'
    invoke 'apache:configure_apache_modules'
    invoke 'apache:configure_app_ssl_conf_file'
  end

  # This task should be moved into Puppet or the installation script
  desc 'Create Apache multi-site configuration folder'
  task :create_apache_sites_folder do
    on roles(:app) do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50
      debug 'Create Apache multi-site configuration folder'

      debug 'mkdir -p /etc/httpd/sites.d'
      execute "#{sudo_cmd} mkdir -p /etc/httpd/sites.d"

      debug '#' * 50
    end
  end

  # This task should be moved into Puppet or the installation script
  desc 'Configure Apache modules'
  task :configure_apache_modules do
    on roles(:app) do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50
      debug 'Configure (HTTP) Apache Passenger module'

      set :shared_passenger_file, '/etc/httpd/conf.modules.d/00-passenger.conf'
      passenger_file = File.expand_path('../recipes/apache/00-passenger.conf', __dir__)

      # Create a temporary copy of the passenger module file
      set :tmp_passenger_file, '/tmp/00-passenger.conf'

      upload! StringIO.new(File.read(passenger_file)), fetch(:tmp_passenger_file).to_s

      passenger_root = get_command_output("/usr/local/rvm/bin/rvm #{fetch(:rvm_ruby_version)} do passenger-config --root")
      ruby_path = "/#{passenger_root.split('/')[1..5].join('/')}/wrappers/ruby"

      debug "sed -i 's|<<PASSENGER_ROOT>>|#{passenger_root}|g' #{fetch(:tmp_passenger_file)}"
      execute "sed -i 's|<<PASSENGER_ROOT>>|#{passenger_root}|g' #{fetch(:tmp_passenger_file)}"
      execute "sed -i 's|<<RUBY_PATH>>|#{ruby_path}|g' #{fetch(:tmp_passenger_file)}"

      # Replace the passenger module file
      execute "#{sudo_cmd} mv -f #{fetch(:tmp_passenger_file)} #{fetch(:shared_passenger_file)}"
      execute "#{sudo_cmd} chown root.root #{fetch(:shared_passenger_file)}"

      debug '#' * 50
      debug 'Deactivate unnecessary Apache modules'
      %w[00-dav.conf 00-lua.conf 00-proxy.conf 01-cgi.conf].each do |file|
        if remote_file_exists?("/etc/httpd/conf.modules.d/#{file}")
          # only perform backup of Apache modules files unless already done
          unless remote_file_exists?("/etc/httpd/conf.modules.d/#{file}_bck")
            execute "#{sudo_cmd} cp /etc/httpd/conf.modules.d/#{file} /etc/httpd/conf.modules.d/#{file}_bck"
          end
          execute "#{sudo_cmd} truncate -s 0 /etc/httpd/conf.modules.d/#{file}"
        end
      end
      debug '#' * 50
    end
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

      execute "#{sudo_cmd} ln -sfn #{fetch(:shared_apache_conf_ssl_file)} /etc/httpd/sites.d/"

      debug '#' * 50
    end
  end

  # This task should be moved into Puppet or the installation script
  desc 'Replace CentOS 7 default httpd.conf and ssl.conf file with our version'
  task :replace_apache_defaults do
    on roles(:web) do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50
      debug 'Update httpd.conf and ssl.conf'

      set :httpd_conf_file, '/etc/httpd/conf/httpd.conf'

      # Replace the original Apache configuration file
      if remote_file_exists?('/etc/httpd/conf/httpd.conf_bck')
        info 'Apache original configuration file already backed up at: /etc/httpd/conf/httpd.conf_bck'
      else
        execute "#{sudo_cmd} cp -f #{fetch(:httpd_conf_file)} /etc/httpd/conf/httpd.conf_bck"
        info 'Apache original configuration file backed up at: /etc/httpd/conf/httpd.conf_bck'
      end

      # Create a temporary copy of the Apache configuration file
      set :tmp_httpd_file, '/tmp/httpd.conf'
      httpd_safe_file = File.expand_path('../recipes/apache/httpd.conf', __dir__)

      upload! StringIO.new(File.read(httpd_safe_file)), fetch(:tmp_httpd_file).to_s

      # Replace the original Apache configuration file
      execute "#{sudo_cmd} mv -f #{fetch(:tmp_httpd_file)} #{fetch(:httpd_conf_file)}"

      set :ssl_conf_file, '/etc/httpd/conf.d/ssl.conf'

      # Replace the original Apache ssl configuration file
      if remote_file_exists?('/etc/httpd/conf.d/ssl.conf_bck')
        info 'Apache original ssl configuration file already backed up at: /etc/httpd/conf.d/ssl.conf_bck'
      else
        execute "#{sudo_cmd} cp -f #{fetch(:ssl_conf_file)} /etc/httpd/conf.d/ssl.conf_bck"
        info 'Apache original ssl configuration file backed up at: /etc/httpd/conf.d/ssl.conf_bck'
      end

      # Create a temporary copy of the Apache ssl configuration file
      set :tmp_ssl_file, '/tmp/ssl.conf'
      ssl_safe_file = File.expand_path('../recipes/apache/ssl.conf', __dir__)

      upload! StringIO.new(File.read(ssl_safe_file)), fetch(:tmp_ssl_file).to_s

      # Replace the original Apache ssl configuration file
      execute "#{sudo_cmd} mv -f #{fetch(:tmp_ssl_file)} #{fetch(:ssl_conf_file)}"
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
