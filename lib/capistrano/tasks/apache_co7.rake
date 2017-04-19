namespace :apache do

  desc 'Configure Apache configuration files'
  task :configure do
    on roles(:app) do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      set :shared_path, "#{fetch(:deploy_to)}/shared"
      set :shared_apache_path, "#{fetch(:shared_path)}/apache"

      invoke 'apache:create_apache_shared_folder'
      invoke 'apache:configure_apache_modules'
      invoke 'apache:configure_app_conf_file'
      invoke 'apache:configure_app_ssl_conf_file'

      if remote_file_exists?('/etc/httpd/conf.d/ssl.conf')
        execute "#{sudo_cmd} mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf_bck"
      end
    end
  end

  desc 'Configure (HTTP) Apache modules'
  task :configure_apache_modules do
    on roles(:app) do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50
      debug 'Configure (HTTP) Apache Passenger module'

      set :shared_passenger_file, "#{fetch(:shared_apache_path)}/00-passenger.conf"
      passenger_file = File.expand_path('../../recipes/co7/00-passenger.conf', __FILE__)
      upload! StringIO.new(File.read(passenger_file)), fetch(:shared_apache_conf_file).to_s

      debug "chmod g+w #{fetch(:shared_passenger_file)}"
      execute "chmod g+w #{fetch(:shared_passenger_file)}"

      passenger_root = get_command_output('/usr/local/rvm/bin/rvm default do passenger-config --root')
      ruby_path = "/#{passenger_root.split('/')[1..5].join('/')}/wrappers/ruby"

      debug "sed -i 's|<<PASSENGER_ROOT>>|#{passenger_root}|g' #{fetch(:shared_apache_conf_file)}"
      execute "sed -i 's|<<PASSENGER_ROOT>>|#{passenger_root}|g' #{fetch(:shared_apache_conf_file)}"
      execute "sed -i 's|<<RUBY_PATH>>|#{ruby_path}|g' #{fetch(:shared_apache_conf_file)}"

      execute "#{sudo_cmd} ln -sfn #{fetch(:shared_passenger_file)} /etc/httpd/conf.modules.d/"

      debug '#' * 50
      debug 'Deactivate unnecessary Apache modules'
      %w[00-dav.conf 00-lua.conf 00-proxy.conf 01-cgi.conf].each do |file|
        if remote_file_exists?("/etc/httpd/conf.modules.d/#{file}")
          execute "#{sudo_cmd} mv /etc/httpd/conf.modules.d/#{file} /etc/httpd/conf.modules.d/#{file}_bck"
        end
      end
      debug '#' * 50

    end
  end

  # desc 'Configure (HTTP) Apache Application configuration files'
  task :configure_app_conf_file do
    on roles(:app) do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50
      debug 'Configure (HTTP) Apache Application configuration files'

      set :shared_apache_conf_file, "#{fetch(:shared_apache_path)}/app_#{fetch(:app_name_uri)}.conf"
      http_file = File.expand_path('../../recipes/co7/apache_http.conf', __FILE__)
      upload! StringIO.new(File.read(http_file)), fetch(:shared_apache_conf_file).to_s

      debug "chmod g+w #{fetch(:shared_apache_conf_file)}"
      execute "chmod g+w #{fetch(:shared_apache_conf_file)}"

      app_domain = fetch(:app_domain)
      server_name = app_domain.split('/')[2]

      execute "sed -i 's|<<APP_DOMAIN>>|#{app_domain}|g' #{fetch(:shared_apache_conf_file)}"
      execute "sed -i 's|<<SERVER_NAME>>|#{server_name}|g' #{fetch(:shared_apache_conf_file)}"

      execute "#{sudo_cmd} ln -sfn #{fetch(:shared_apache_conf_file)} /etc/httpd/conf.d/"

      debug '#' * 50
    end
  end

  # desc 'Configure (HTTPS) Apache Application configuration files'
  task :configure_app_ssl_conf_file do
    on roles(:app) do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50
      debug 'Configure (HTTPS) Apache Application configuration files'

      set :shared_apache_conf_ssl_file, "#{fetch(:shared_apache_path)}/app_#{fetch(:app_name_uri)}_ssl.conf"
      http_ssl_file = File.expand_path('../../recipes/co7/apache_ssl.conf', __FILE__)
      upload! StringIO.new(File.read(http_ssl_file)), fetch(:shared_apache_conf_ssl_file).to_s

      debug "chmod g+w #{fetch(:shared_apache_conf_ssl_file)}"
      execute "chmod g+w #{fetch(:shared_apache_conf_ssl_file)}"

      execute "sed -i 's/<<APPLICATION_NAME>>/#{fetch(:app_name_uri)}/g' #{fetch(:shared_apache_conf_ssl_file)}"
      execute "sed -i 's/<<ENVIRONMENT>>/#{fetch(:environment)}/g' #{fetch(:shared_apache_conf_ssl_file)}"

      execute "#{sudo_cmd} ln -sfn #{fetch(:shared_apache_conf_ssl_file)} /etc/httpd/conf.d/"

      debug '#' * 50
    end
  end

  desc 'Update httpd.conf to secure apache server'
  task :secure_apache do
    on roles(:web) do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50
      debug 'Update httpd.conf to secure apache server'

      set :httpd_conf_file, '/etc/httpd/conf/httpd.conf'

      # Replace the original Apache configuration file
      if remote_file_exists?('/etc/httpd/conf/httpd.conf_bck')
        info 'Apache original configuration file already backed up at: /etc/httpd/conf/httpd.conf_bck'
      else
        execute "#{sudo_cmd} cp -f #{fetch(:httpd_conf_file)} /etc/httpd/conf/httpd.conf_bck"
        info 'Apache original configuration file backed up at: /etc/httpd/conf/httpd.conf_bck'
      end

      httpd_safe_file = File.expand_path('../../recipes/co7/httpd.conf', __FILE__)
      upload! StringIO.new(File.read(httpd_safe_file)), fetch(:httpd_conf_file).to_s

    end
  end
end
