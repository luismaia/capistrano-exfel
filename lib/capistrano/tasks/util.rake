# frozen_string_literal: true

def remote_file_exists?(full_path)
  get_command_output("if [ -e #{full_path} ]; then echo 'true'; fi") == 'true'
end

def get_num_occurrences_in_file(file_path, string)
  get_command_output("cat #{file_path} | grep '#{string}' | wc -l").to_i
end

def get_command_output(command)
  capture(command.to_s).strip
end

def rails_default_app_name
  return fetch(:app_name).to_s if get_rails_env_abbr == 'prod'

  "#{get_rails_env_abbr}_#{fetch(:app_name)}"
end

def rails_default_db_name
  "#{fetch(:app_name)}_#{get_rails_env_abbr}"
end

def get_rails_env_abbr(rails_env_abbr = nil)
  return rails_env_abbr unless rails_env_abbr.nil?

  case fetch(:rails_env).to_s
  when 'development'
    'dev'
  when 'test'
    'test'
  else
    'prod'
  end
end

def execute_rake_command(task)
  within release_path do
    execute :rake, task, "RAILS_ENV=#{fetch(:environment)}"
  end
end

def string_between_markers(complete_str, marker1, marker2)
  complete_str[/#{Regexp.escape(marker1)}(.*?)#{Regexp.escape(marker2)}/m, 1]
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
