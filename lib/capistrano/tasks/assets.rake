# avoid asset precompilation in dev environment

Rake::Task['deploy:compile_assets'].clear_actions
namespace :deploy do
  task compile_assets: [:set_rails_env] do
    if %w[production test].include?(fetch(:rails_env).to_s)
      invoke 'deploy:assets:precompile'
      invoke 'deploy:assets:backup_manifest'
    end
  end
end
