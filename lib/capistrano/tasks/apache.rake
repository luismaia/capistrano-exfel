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
