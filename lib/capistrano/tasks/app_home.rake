namespace :app_home do
  desc 'Create on server the necessary placeholders for storing the Application'
  task :create_all do
    invoke 'app_home:create_deploy_folder'
    invoke 'app_home:create_shared_folder'
    invoke 'app_home:create_revisions_file'
  end

  desc 'Create application deploy folders on server and give it the correct permissions'
  task :create_deploy_folder do
    on roles(:app) do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50

      debug "mkdir -p #{fetch(:deploy_to)}"
      execute "#{sudo_cmd} mkdir -p #{fetch(:deploy_to)}"

      debug "chgrp #{fetch(:app_group_owner)} #{fetch(:deploy_to)}"
      execute "#{sudo_cmd} chgrp #{fetch(:app_group_owner)} #{fetch(:deploy_to)}"

      debug "chmod g+ws #{fetch(:deploy_to)}"
      execute "#{sudo_cmd} chmod g+ws #{fetch(:deploy_to)}"

      debug '#' * 50
    end
  end

  desc 'Create shared folder on server DEPLOY folder and give it the correct permissions'
  task :create_shared_folder do
    on roles(:app) do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50

      debug "mkdir -p #{fetch(:shared_path)}"
      execute "#{sudo_cmd} mkdir -p #{fetch(:shared_path)}"

      debug "chmod g+ws #{fetch(:shared_path)}"
      execute "#{sudo_cmd} chmod g+ws #{fetch(:shared_path)}"

      set :shared_config_path, "#{fetch(:shared_path)}/config"

      debug "mkdir -p #{fetch(:shared_config_path)}"
      execute "#{sudo_cmd} mkdir -p #{fetch(:shared_config_path)}"

      debug "chmod g+ws #{fetch(:shared_config_path)}"
      execute "#{sudo_cmd} chmod g+ws #{fetch(:shared_config_path)}"

      debug '#' * 50
    end
  end

  desc 'create revisions.log file on server DEPLOY folder and give it the correct permissions'
  task :create_revisions_file do
    on roles(:app) do
      debug '#' * 50

      set :revisions_log_file_path, "#{fetch(:deploy_to)}/revisions.log"

      debug "touch #{fetch(:revisions_log_file_path)}"
      execute :touch, fetch(:revisions_log_file_path)

      debug "chmod g+w #{fetch(:revisions_log_file_path)}"
      execute "chmod g+w #{fetch(:revisions_log_file_path)}"

      debug '#' * 50
    end
  end

  desc 'Correct shared folder permissions'
  task :correct_shared_permissions do
    on roles(:app), in: :sequence, wait: 5 do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50

      # Needs access to the folder due to the first write and log rotation
      debug "chown -R nobody.#{fetch(:app_group_owner)} #{fetch(:shared_path)}/log"
      execute "#{sudo_cmd} chown -R nobody.#{fetch(:app_group_owner)} #{fetch(:shared_path)}/log"

      # Needs write permissions
      debug "chown -R nobody.#{fetch(:app_group_owner)} #{fetch(:shared_path)}/tmp/"
      execute "#{sudo_cmd} chown -R nobody.#{fetch(:app_group_owner)} #{fetch(:shared_path)}/tmp/"

      debug '#' * 50
    end
  end

  desc 'Correct public folder permissions'
  task :correct_public_folder_permissions do
    on roles(:app) do
      within release_path do
        sudo_cmd = "echo #{fetch(:password)} | sudo -S"

        debug '#' * 50
        set :public_folder_path, "#{release_path}/public"

        debug '#' * 50
        chown_command = "chown -Rf nobody.#{fetch(:app_group_owner)} #{fetch(:public_folder_path)}/*"
        debug chown_command
        execute "#{sudo_cmd} #{chown_command}"

        debug '#' * 50
      end
    end
  end

  task :reload_server_cache do
    on roles(:app), in: :sequence, wait: 5 do
      debug '#' * 100
      debug 'rake tmp:clear'
      execute_rake_command('tmp:clear')

      debug '#' * 100
      debug "wget -v -p --spider https://in.xfel.eu/#{fetch(:app_name_uri)}"
      execute :wget, "-v -p --spider https://in.xfel.eu/#{fetch(:app_name_uri)}"
      debug 'Application visited successfully...'
      debug '#' * 100
    end
  end

  task :deploy_success_msg do
    on roles(:app), in: :sequence, wait: 5 do
      info '#' * 100
      info '#' * 10 + ' => Application Successfully deployed...'
      info '#' * 100
      info '#' * 10 + " => visit: https://in.xfel.eu/#{fetch(:app_name_uri)}"
      info '#' * 100
    end
  end

  ###
  # This task doesn't look to be working:
  # desc 'Restart application'
  ###
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      info '#' * 10 + ' Touching restart.txt...'
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end
end
