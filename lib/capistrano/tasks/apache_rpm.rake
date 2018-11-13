# apache tasks common to RPM-based distros (CentOS and Scientific Linux)

namespace :apache do
  desc 'Configure Apache (httpd) and restart it'
  task :configure_and_start do
    invoke 'apache:configure'
    invoke 'apache:chkconfig_on'
    # invoke 'apache:restart'
    invoke 'apache:secure_apache' # This should go to Puppet
    invoke 'apache:create_symbolic_link'
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
end
