namespace :secrets do
  desc 'Create secrets.yml in shared path'
  task :configure do
    on roles(:app) do
      set :secrets_file_path, "#{fetch(:shared_path)}/config/secrets.yml"

      invoke 'secrets:set_permissions_pre_update'
      invoke 'secrets:set_secrets_file'
      invoke 'secrets:replace_token'
      invoke 'secrets:set_permissions_post_update'
    end
  end

  desc 'Update Application secret in file secrets.yml'
  task :update_app_secret do
    on roles(:app) do
      set :secrets_file_path, "#{fetch(:shared_path)}/config/secrets.yml"

      invoke 'secrets:set_permissions_pre_update'
      invoke 'secrets:replace_token'
      invoke 'secrets:set_permissions_post_update'
    end
  end

  # desc 'Set (create or replace) secrets.yml in the shared path'
  task :set_secrets_file do
    on roles(:app) do
      debug '#' * 50
      debug 'Create and configure secrets.yml file'
      secrets_file_path = "#{fetch(:secrets_file_path)}"

      set :secrets_original_file_path, 'config/recipes/config/secrets_example.yml'

      unless remote_file_exists?(secrets_file_path)
        upload! StringIO.new(File.read("#{fetch(:secrets_original_file_path)}")), "#{fetch(:secrets_file_path)}"
      end

      debug '#' * 50
    end
  end

  # desc 'Replace the secure secret key in your secrets.yml'
  task :replace_token do
    on roles(:app) do
      debug '#' * 50

      pattern = 'secret_key_base:.*'
      new_secret = "secret_key_base: '#{SecureRandom.hex(64)}'"
      secrets_file_path = "#{fetch(:secrets_file_path)}"

      if remote_file_exists?(secrets_file_path)
        num_occurrences = get_num_occurrences_in_file(secrets_file_path, pattern)

        if num_occurrences == 0
          error "no secret token found in #{secrets_file_path}"
          exit 1
        end
      else
        error "file #{secrets_file_path} not found"
        exit 1
      end

      command = "sed -i -e \"s/#{pattern}/#{new_secret}/g\" #{secrets_file_path}"
      debug command
      execute command

      debug 'Secret token successfully replaced'
      debug '#' * 50
    end
  end

  # desc 'Correct secrets.yml file permissions before change the file'
  task :set_permissions_pre_update do
    on roles(:app) do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50

      chmod_command = "chmod -f 777 #{fetch(:secrets_file_path)} || true"
      debug chmod_command
      execute "#{sudo_cmd} #{chmod_command}"

      debug '#' * 50
    end
  end

  # desc 'Correct secrets.yml file permissions after change the file'
  task :set_permissions_post_update do
    on roles(:app) do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50

      # Update database.yml user and group owners
      chown_command = "chown nobody.#{fetch(:app_group_owner)} #{fetch(:secrets_file_path)}"
      debug chown_command
      execute "#{sudo_cmd} #{chown_command}"

      chmod_command = "chmod 440 #{fetch(:secrets_file_path)}"
      debug chmod_command
      execute "#{sudo_cmd} #{chmod_command}"

      debug '#' * 50
    end
  end
end
