namespace :database do
  desc 'Seed default data (roles and common users) to the database'
  task :seed do
    on roles(:app), in: :sequence, wait: 5 do
      execute_rake_command('db:seed')
    end
  end

  desc 'Create MySQL specific database.yml in the shared path'
  task :configure_mysql do
    on roles(:app) do
      set :database_original_file_name, 'database_mysql.yml'
      invoke 'database:configure_database_file'
    end
  end

  desc 'Create PostgreSQL specific database.yml in the shared path'
  task :configure_postgresql do
    on roles(:app) do
      set :database_original_file_name, 'database_postgresql.yml'
      invoke 'database:configure_database_file'
    end
  end

  desc 'Create SQLite specific database.yml in the shared path'
  task :configure_sqlite do
    on roles(:app) do
      set :database_original_file_name, 'database_sqlite.yml'
      invoke 'database:configure_database_file'
    end
  end

  # desc 'Configure database.yml in the shared path'
  task :configure_database_file do
    on roles(:app) do
      set :database_original_file_path, "../../recipes/config/#{fetch(:database_original_file_name)}"
      set :database_file_path, "#{fetch(:shared_path)}/config/database.yml"

      invoke 'database:set_permissions_pre_update'
      invoke 'database:set_database_file'
      invoke 'database:set_permissions_post_update'
    end
  end

  # desc 'Set (create or replace) database.yml in the shared path'
  task :set_database_file do
    on roles(:app) do
      debug '#' * 50
      debug 'Create and configure database.yml file'

      default_host = '127.0.0.1'
      default_database = "#{fetch(:app_name)}_dev"
      default_username = "#{fetch(:app_name)}_dev"
      default_password = ''

      set :database_host, ask('Database host:', default_host)
      set :database_name, ask('Database Name:', default_database)
      set :database_username, ask('Database Username:', default_username)
      set :database_password, ask('Database Password:', default_password)

      upload! StringIO.new(File.read("#{fetch(:database_original_file_path)}")), "#{fetch(:database_file_path)}"

      execute "sed -i 's/<<database_name>>/#{fetch(:database_name)}/g' #{fetch(:database_file_path)}"
      execute "sed -i 's/<<database_username>>/#{fetch(:database_username)}/g' #{fetch(:database_file_path)}"
      execute "sed -i 's/<<database_password>>/#{fetch(:database_password)}/g' #{fetch(:database_file_path)}"
      execute "sed -i 's/<<database_host>>/#{fetch(:database_host)}/g' #{fetch(:database_file_path)}"

      debug '#' * 50
    end
  end

  # desc 'Correct database.yml file permissions before change the file'
  task :set_permissions_pre_update do
    on roles(:app) do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50

      chmod_command = "chmod -f 777 #{fetch(:database_file_path)} || true"
      debug chmod_command
      execute "#{sudo_cmd} #{chmod_command}"

      debug '#' * 50
    end
  end

  # desc 'Correct database.yml file permissions after change the file'
  task :set_permissions_post_update do
    on roles(:app) do
      sudo_cmd = "echo #{fetch(:password)} | sudo -S"

      debug '#' * 50

      # Update database.yml user and group owners
      chown_command = "chown nobody.#{fetch(:app_group_owner)} #{fetch(:database_file_path)}"
      debug chown_command
      execute "#{sudo_cmd} #{chown_command}"

      chmod_command = "chmod 440 #{fetch(:database_file_path)}"
      debug chmod_command
      execute "#{sudo_cmd} #{chmod_command}"

      debug '#' * 50
    end
  end
end
