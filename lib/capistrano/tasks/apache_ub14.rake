# apache tasks specific to Ubuntu 14

namespace :apache do

  desc 'Configure Apache (httpd) and restart it'
  task :configure_and_start do
    invoke 'apache:configure'
    # invoke 'apache:restart'
    # invoke 'apache:secure_apache' # This should go to Puppet
    invoke 'apache:create_symbolic_link'
  end

  desc 'Restart Apache (apache2) service'
  task :restart do
    on roles(:web) do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50

      debug 'service apache2 stop'
      execute "#{sudo_cmd} service apache2 stop"

      debug 'pkill -9 apache2 || true'
      execute "#{sudo_cmd} pkill -9 apache2 || true"

      debug 'service apache2 start'
      execute "#{sudo_cmd} service apache2 start"

      info 'Restarted Apache (apache2) service'
      debug '#' * 50
    end
  end

  desc 'Configure Apache configuration files'
  task :configure do
    invoke 'apache:create_apache_shared_folder'
    invoke 'apache:configure_apache_modules'
    invoke 'apache:configure_app_conf_file'
  end

  desc 'Configure (HTTP) Apache modules'
  task :configure_apache_modules do
    on roles(:app) do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50
      debug 'Configure (HTTP) Apache Passenger module'

      set :shared_passenger_file, "#{fetch(:shared_apache_path)}/passenger.conf"
      passenger_file = File.expand_path('../recipes/ub14/passenger.conf', __dir__)

      upload! StringIO.new(File.read(passenger_file)), fetch(:shared_passenger_file).to_s

      debug "chmod g+w #{fetch(:shared_passenger_file)}"
      execute "chmod g+w #{fetch(:shared_passenger_file)}"

      passenger_root = get_command_output('/usr/local/rvm/bin/rvm default do passenger-config --root')
      ruby_path = "/#{passenger_root.split('/')[1..5].join('/')}/wrappers/ruby"

      debug "sed -i 's|<<PASSENGER_ROOT>>|#{passenger_root}|g' #{fetch(:shared_passenger_file)}"
      execute "sed -i 's|<<PASSENGER_ROOT>>|#{passenger_root}|g' #{fetch(:shared_passenger_file)}"
      execute "sed -i 's|<<RUBY_PATH>>|#{ruby_path}|g' #{fetch(:shared_passenger_file)}"

      execute "#{sudo_cmd} ln -sfn #{fetch(:shared_passenger_file)} /etc/apache2/mods-enabled/"

      debug '#' * 50
    end
  end

  # desc 'Configure (HTTP) Apache Application configuration files'
  task :configure_app_conf_file do
    on roles(:app), in: :sequence do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50
      debug 'Configure (HTTP) Apache Application configuration files'

      set :shared_apache_conf_file, "#{fetch(:shared_apache_path)}/app_#{fetch(:app_name_uri)}.conf"
      http_file = File.expand_path('../recipes/ub14/apache.conf', __dir__)
      upload! StringIO.new(File.read(http_file)), fetch(:shared_apache_conf_file).to_s

      debug "chmod g+w #{fetch(:shared_apache_conf_file)}"
      execute "chmod g+w #{fetch(:shared_apache_conf_file)}"

      execute "sed -i 's|<<APPLICATION_NAME>>|#{fetch(:app_name_uri)}|g' #{fetch(:shared_apache_conf_file)}"
      execute "sed -i 's/<<ENVIRONMENT>>/#{fetch(:environment)}/g' #{fetch(:shared_apache_conf_file)}"

      execute "#{sudo_cmd} ln -sfn #{fetch(:shared_apache_conf_file)} /etc/apache2/sites-enabled/"

      debug '#' * 50
    end
  end

  # desc 'Configure (HTTPS) Apache Application configuration files'
  # task :configure_app_ssl_conf_file do
  #   on roles(:app), in: :sequence do
  #     sudo_cmd = "echo #{fetch(:password)} | sudo -S"
  #
  #     debug '#' * 50
  #     debug 'Configure (HTTPS) Apache Application configuration files'
  #
  #     set :shared_apache_conf_ssl_file, "#{fetch(:shared_apache_path)}/app_#{fetch(:app_name_uri)}_ssl.conf"
  #     http_ssl_file = File.expand_path('../recipes/co7/apache_ssl.conf', __dir__)
  #     upload! StringIO.new(File.read(http_ssl_file)), fetch(:shared_apache_conf_ssl_file).to_s
  #
  #     debug "chmod g+w #{fetch(:shared_apache_conf_ssl_file)}"
  #     execute "chmod g+w #{fetch(:shared_apache_conf_ssl_file)}"
  #
  #     execute "sed -i 's/<<APPLICATION_NAME>>/#{fetch(:app_name_uri)}/g' #{fetch(:shared_apache_conf_ssl_file)}"
  #     execute "sed -i 's/<<ENVIRONMENT>>/#{fetch(:environment)}/g' #{fetch(:shared_apache_conf_ssl_file)}"
  #
  #     execute "#{sudo_cmd} ln -sfn #{fetch(:shared_apache_conf_ssl_file)} /etc/httpd/conf.d/"
  #
  #     debug '#' * 50
  #   end
  # end

end
