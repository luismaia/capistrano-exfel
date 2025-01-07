# frozen_string_literal: true

namespace :env do
  desc 'Create .env in shared path'
  task :configure do
    set :env_file_path, "#{fetch(:shared_path)}/.env"

    invoke 'env:set_permissions_pre_update'
    invoke 'env:set_env_file'
    invoke 'env:replace_token'
    invoke 'env:set_permissions_post_update'
  end

  desc 'Update Application secret in file .env'
  task :update_app_secret do
    set :env_file_path, "#{fetch(:shared_path)}/.env"

    invoke 'env:set_permissions_pre_update'
    invoke 'env:replace_token'
    invoke 'env:set_permissions_post_update'
  end

  # desc 'Set (create or replace) .env in the shared path'
  task :set_env_file do
    on roles(:app), in: :sequence do
      debug '#' * 50
      debug 'Create and configure .env file'
      env_file_path = fetch(:env_file_path).to_s

      set :env_original_file_path, File.expand_path('../recipes/config/.env.example', __dir__)

      unless remote_file_exists?(env_file_path)
        upload! StringIO.new(File.read(fetch(:env_original_file_path).to_s)), fetch(:env_file_path).to_s
      end

      debug '#' * 50
    end
  end

  # desc 'Replace the secure secret key in your .env'
  task :replace_token do
    on roles(:app), in: :sequence do
      debug '#' * 50

      pattern = 'SECRET_KEY_BASE=.*'
      new_secret = "SECRET_KEY_BASE=#{fetch(:secrets_key_base)}"
      env_file_path = fetch(:env_file_path).to_s

      if remote_file_exists?(env_file_path)
        num_occurrences = get_num_occurrences_in_file(env_file_path, pattern)

        if num_occurrences.zero?
          error "no secret token found in #{env_file_path}"
          exit 1
        end
      else
        error "file #{env_file_path} not found"
        exit 1
      end

      command = "sed -i -e \"s/#{pattern}/#{new_secret}/g\" #{env_file_path}"
      debug command
      execute command

      debug 'Secret token successfully replaced'
      debug '#' * 50
    end
  end

  # desc 'Correct .env file permissions before change the file'
  task :set_permissions_pre_update do
    on roles(:app) do
      sudo_cmd = "echo '#{fetch(:password)}' | sudo -S"

      debug '#' * 50

      chmod_command = "chmod -f 777 #{fetch(:env_file_path)} || true"
      debug chmod_command
      execute "#{sudo_cmd} #{chmod_command}"

      debug '#' * 50
    end
  end

  # desc 'Correct .env file permissions after change the file'
  task :set_permissions_post_update do
    on roles(:app) do
      sudo_cmd = "echo '#{fetch(:password)}' | sudo -S"

      debug '#' * 50

      # Update database.yml user and group owners
      chown_command = "chown #{fetch(:app_user_owner)}.#{fetch(:app_group_owner)} #{fetch(:env_file_path)}"
      debug chown_command
      execute "#{sudo_cmd} #{chown_command}"

      chmod_command = "chmod 440 #{fetch(:env_file_path)}"
      debug chmod_command
      execute "#{sudo_cmd} #{chmod_command}"

      debug '#' * 50
    end
  end
end
