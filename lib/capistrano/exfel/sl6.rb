# Load DSL and Setup Up Stages
require 'capistrano/setup'

# Includes default deployment tasks
require 'capistrano/deploy'

# Includes tasks from other gems included in your Gemfile
require 'capistrano/rvm'

case fetch(:rails_env).to_s
when 'production'
when 'test'
  # We're going to use the full capistrano/rails since
  # it includes the asset compilation, DB migrations and bundler
  require 'capistrano/rails'
else #when 'development'
  # we avoid asset precompilation in dev environment
  require 'capistrano/bundler'
  require 'capistrano/rails/migrations'
end

load File.expand_path('../../tasks/apache.rake', __FILE__)
load File.expand_path('../../tasks/apache_sl6.rake', __FILE__)
load File.expand_path('../../tasks/app_home.rake', __FILE__)
load File.expand_path('../../tasks/application.rake', __FILE__)
load File.expand_path('../../tasks/database.rake', __FILE__)
load File.expand_path('../../tasks/secrets.rake', __FILE__)
load File.expand_path('../../tasks/util.rake', __FILE__)
