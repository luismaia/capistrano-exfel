# avoid asset precompilation in dev environment

Rake::Task['deploy:assets:precompile'].clear_actions
namespace :deploy do
  namespace :assets do
    task :precompile do
      on release_roles(fetch(:assets_roles)) do
        within release_path do
          with rails_env: fetch(:rails_env), rails_groups: fetch(:rails_assets_groups) do
            if %w[production test].include?(fetch(:rails_env).to_s)
              execute :rake, 'assets:precompile'
            else
              info 'Skipping asset pre-compilation in dev environment'
            end
          end
        end
      end
    end
  end
end
