namespace :apache do
  desc 'Configure Apache (httpd) and restart it'
  task :configure_and_start do
    invoke 'apache:configure'
    invoke 'apache:chkconfig_on'
    # invoke 'apache:restart'
    invoke 'apache:secure_apache' # This should go to Puppet
    invoke 'apache:create_symbolic_link'
  end

  desc 'Check that the user has write permissions in the Deploy and in Apache DocumentRoot folders'
  task :check_write_permissions do
    invoke 'apache:check_write_permissions_on_deploy'
    invoke 'apache:check_write_permissions_on_document_root'
  end

  desc 'Check that we have the right permission to the folder the app should be deployed to'
  task :check_write_permissions_on_deploy do
    on roles(:app) do |host|
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

  desc 'Configure Apache configuration files'
  task :configure do
    on roles(:app) do
      set :shared_path, "#{fetch(:deploy_to)}/shared"
      set :shared_apache_path, "#{fetch(:shared_path)}/apache"

      invoke 'apache:create_apache_shared_folder'
      invoke 'apache:configure_app_conf_file'
      invoke 'apache:configure_app_ssl_conf_file'

      if remote_file_exists?('/etc/httpd/conf.d/ssl.conf')
        execute "#{sudo_cmd} mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf_bck"
      end
    end
  end

  # desc 'Create Apache configuration files shared folder'
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

  # desc 'Configure (HTTP) Apache Application configuration files'
  task :configure_app_conf_file do
    on roles(:app) do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50
      debug 'Configure (HTTP) Apache Application configuration files'

      set :shared_apache_conf_file, "#{fetch(:shared_apache_path)}/app_#{fetch(:app_name_uri)}.conf"

      upload! StringIO.new(File.read('config/recipes/apache_http.conf')), "#{fetch(:shared_apache_conf_file)}"
      debug "chmod g+w #{fetch(:shared_apache_conf_file)}"
      execute "chmod g+w #{fetch(:shared_apache_conf_file)}"

      passenger_root = get_command_output('/usr/local/rvm/bin/rvm default do passenger-config --root')
      ruby_path = "/#{passenger_root.split('/')[1..5].join('/')}/wrappers/ruby"
      app_domain = fetch(:app_domain)
      server_name = app_domain.split('/')[2]

      debug "sed -i 's|<<PASSENGER_ROOT>>|#{passenger_root}|g' #{fetch(:shared_apache_conf_file)}"
      execute "sed -i 's|<<PASSENGER_ROOT>>|#{passenger_root}|g' #{fetch(:shared_apache_conf_file)}"

      execute "sed -i 's|<<RUBY_PATH>>|#{ruby_path}|g' #{fetch(:shared_apache_conf_file)}"
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

      upload! StringIO.new(File.read('config/recipes/apache_ssl.conf')), "#{fetch(:shared_apache_conf_ssl_file)}"
      debug "chmod g+w #{fetch(:shared_apache_conf_ssl_file)}"
      execute "chmod g+w #{fetch(:shared_apache_conf_ssl_file)}"

      execute "sed -i 's/<<APPLICATION_NAME>>/#{fetch(:app_name_uri)}/g' #{fetch(:shared_apache_conf_ssl_file)}"
      execute "sed -i 's/<<ENVIRONMENT>>/#{fetch(:environment)}/g' #{fetch(:shared_apache_conf_ssl_file)}"

      execute "#{sudo_cmd} ln -sfn #{fetch(:shared_apache_conf_ssl_file)} /etc/httpd/conf.d/"

      debug '#' * 50
    end
  end

  desc 'Configure Apache to start at bootup'
  task :chkconfig_on do
    on roles(:web) do
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

  desc 'Create symbolic link to application public folder in Apache DocumentRoot folder'
  task :create_symbolic_link do
    on roles(:web) do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      info '#' * 50
      info 'Creating application symbolic link'

      debug "ln -sfn #{fetch(:deploy_to)}/current/public #{fetch(:apache_deploy_symbolic_link)}"
      execute "#{sudo_cmd} ln -sfn #{fetch(:deploy_to)}/current/public #{fetch(:apache_deploy_symbolic_link)}"

      info '#' * 50
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

      # The ServerSignature directive allows the configuration of a trailing footer line under server-generated docs
      # Options:  On | Off | EMail
      # More details: http://httpd.apache.org/docs/current/mod/core.html#serversignature
      set :server_signature_off, get_num_occurrences_in_file(fetch(:httpd_conf_file), 'ServerSignature Off')

      if fetch(:server_signature_off) == 1
        info 'ServerSignature Off is already set'

      else
        set :num_replacements, 0
        %w(On Off EMail).each do |option|
          set :server_signature_option,
              get_num_occurrences_in_file(fetch(:httpd_conf_file), "ServerSignature #{option}")

          if fetch(:server_signature_option) == 1
            info "sed -i 's/ServerSignature #{option}/ServerSignature Off/g' #{fetch(:httpd_conf_file)}"
            execute "#{sudo_cmd} sed -i 's/ServerSignature #{option}/ServerSignature Off/g' #{fetch(:httpd_conf_file)}"
            set :num_replacements, fetch(:num_replacements) + 1
          end
        end

        error 'ServerSignature was not found' if fetch(:num_replacements) == 0
      end

      # Don't give away too much information about all the subcomponents we are running.
      #
      # Options: Major|Minor|Min[imal]|Prod[uctOnly]|OS|Full
      # More details: http://httpd.apache.org/docs/current/mod/core.html#servertokens
      set :server_token_prod, get_num_occurrences_in_file(fetch(:httpd_conf_file), 'ServerTokens Prod')
      if fetch(:server_token_prod) == 1
        info 'ServerTokens Prod is already set'
      else
        set :num_replacements, 0
        %w(Major Minor Minimal Min ProductOnly Prod OS Full).each do |option|
          set :server_token_option, get_num_occurrences_in_file(fetch(:httpd_conf_file), "ServerTokens #{option}")

          next unless fetch(:server_token_option) == 1

          # Then, only if fetch(:server_token_option) == 1
          info "sed -i 's/ServerTokens #{option}/ServerTokens Prod/g' #{fetch(:httpd_conf_file)}"
          execute "#{sudo_cmd} sed -i 's/ServerTokens #{option}/ServerTokens Prod/g' #{fetch(:httpd_conf_file)}"
          set :num_replacements, fetch(:num_replacements) + 1
        end

        error 'ServerTokens was not found' if fetch(:num_replacements) == 0
      end

      # Do not allow browsing outside the document root
      #
      # <Directory />
      #   Order Deny,Allow
      #   Deny from all
      #   Options None
      #   AllowOverride None
      # </Directory>
      #
      message_line_1 = '# Default Directory configuration changed via Capistrano.'

      set :server_dir_secure_configuration, get_num_occurrences_in_file(fetch(:httpd_conf_file), message_line_1)

      if fetch(:server_token_prod) == 1
        info 'The correct directory configuration is already correctly set'
      else

        set :tmp_dir_original_config, '/tmp/tmp_dir_original_config.conf'
        set :tmp_dir_original_commented_config, '/tmp/tmp_dir_original_commented_config.conf'
        set :tmp_dir_new_config, '/tmp/tmp_dir_new_config.conf'

        # Create a temporary copy of the Apache configuration file
        set :tmp_httpd_file, '/tmp/httpd.conf'
        execute :cp, '-f', "#{fetch(:httpd_conf_file)} #{fetch(:tmp_httpd_file)}"

        set :grep_for_directory, "grep -Pzo '^([ ]*<Directory />[ ]*)(\\n.*)+(\\n[ ]*</Directory>[ ]*)(\\n){1}$' "\
                                 "#{fetch(:tmp_httpd_file)}"

        # How many lines have the original configuration
        command = "#{fetch(:grep_for_directory)} | grep -n '</Directory>' | head -n 1 | cut -d ':' -f1"
        set :def_directory_num_lines, get_command_output(command).to_i
        debug "Original configuration has #{fetch(:def_directory_num_lines)} lines."

        # Saves to a file the original configuration
        command = "#{fetch(:grep_for_directory)} | "\
              "head -n #{fetch(:def_directory_num_lines)} > #{fetch(:tmp_dir_original_config)}"
        debug command
        execute command

        # Saves to a file the original configuration commented
        execute :cp, '-f', "#{fetch(:tmp_dir_original_config)} #{fetch(:tmp_dir_original_commented_config)}"
        execute "sed -e 's/^/#/' -i #{fetch(:tmp_dir_original_commented_config)}"

        # Save to a file the new desired configuration
        new_directory_configs = <<-EOF

#Do not allow browsing outside the document root
<Directory />
  Order Deny,Allow
  Deny from all
  Options None
  AllowOverride None
</Directory>

        EOF
        upload! StringIO.new(new_directory_configs), "#{fetch(:tmp_dir_new_config)}"

        # Update the new configuration file to have the original configuration commented
        debug "cat #{fetch(:tmp_dir_new_config)} >> #{fetch(:tmp_dir_original_commented_config)}"
        execute "cat #{fetch(:tmp_dir_new_config)} >> #{fetch(:tmp_dir_original_commented_config)}"
        execute "mv -f #{fetch(:tmp_dir_original_commented_config)} #{fetch(:tmp_dir_new_config)}"

        # Generates the special SED parameter: 'N;' per line that should be replaced
        special_sed_param = 'N;' * fetch(:def_directory_num_lines)
        debug "Special sed parameter is: ''#{special_sed_param}''"

        # Replace the old original directory configuration for a specific message (in the temporary file)
        message_complete = "#{message_line_1}\\n#\\n"
        command_to_replace = "out=$(sed -e :a -e '$!N;s/\\n/.*/;ta' #{fetch(:tmp_dir_original_config)} | "\
                             "sed -e :a -e '$!N;s/\//./;ta'); sed -i '/<Directory .>.*/ {#{special_sed_param} "\
                             "s/'$out'/#{message_complete}/g}' #{fetch(:tmp_httpd_file)}"
        debug command_to_replace
        execute command_to_replace

        # Search for the line where the message was inserted
        command = "grep -n '#{message_line_1}' #{fetch(:tmp_httpd_file)} | cut -d':' -f 1"
        debug command
        line_with_match = get_command_output(command).to_i
        next_line = line_with_match + 1
        debug "New configuration will be added to line #{next_line}"

        # Inserts the new directory configuration (with the old configuration commented)
        # in the line following the comment added before
        command = "sed '#{next_line}r #{fetch(:tmp_dir_new_config)}' < #{fetch(:tmp_httpd_file)} "\
                  '> tmp_httpd_new_conf_merge.conf'

        debug command
        execute command
        execute "mv -f tmp_httpd_new_conf_merge.conf #{fetch(:tmp_httpd_file)}"

        # Replace the original Apache configuration file
        execute "#{sudo_cmd} mv -f #{fetch(:tmp_httpd_file)} #{fetch(:httpd_conf_file)}"

        # Remove all created temporary files
        execute "rm -f #{fetch(:tmp_dir_original_config)} #{fetch(:tmp_dir_original_commented_config)} "\
                "#{fetch(:tmp_dir_new_config)} #{fetch(:tmp_httpd_file)}"
      end
    end
  end
end
