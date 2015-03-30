def remote_file_exists?(full_path)
  'true' == get_command_output("if [ -e #{full_path} ]; then echo 'true'; fi")
end

def get_num_occurrences_in_file(file_path, string)
  get_command_output("less #{file_path} | grep '#{string}' | wc -l").to_i
end

def get_command_output(command)
  capture("#{command}").strip
end

def execute_rake_command(task)
  within release_path do
    execute :rake, task, "RAILS_ENV=#{fetch(:environment)}"
  end
end

namespace :util do
  desc 'Report Server Uptimes'
  task :uptime do
    on roles(:all) do |host|
      info "Host #{host} (#{host.roles.to_a.join(', ')}):\t#{get_command_output(:uptime)}"
    end
  end

  desc 'Run rake command'
  task :runrake do
    # Usage: cap [development|test|production] util:runrake task=secret
    on roles(:all), in: :sequence, wait: 5 do
      execute_rake_command(ENV['task'])
    end
  end

  desc 'Report Server klist (Kerberos Tickets)'
  task :klist do
    on roles(:app, :web) do
      info '#' * 100
      info '#' * 10 + ' ===> KLIST <=== '
      info '#' * 10 + execute_rake_command('klist').to_s
      info '#' * 100
    end
  end

  task :query_interactive do
    on roles(:web) do
      info execute_rake_command("[[ $- == *i* ]] && echo 'Interactive' || echo 'Not interactive'")
    end
  end

  task :query_login do
    on roles(:web) do
      info execute_rake_command("shopt -q login_shell && echo 'Login shell' || echo 'Not login shell'")
    end
  end
end
