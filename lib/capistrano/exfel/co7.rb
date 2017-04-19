# Load DSL and Setup Up Stages
require 'capistrano/setup'

# Includes default deployment tasks
require 'capistrano/deploy'

# Includes tasks from other gems included in your Gemfile
require 'capistrano/rvm'

# We're going to use the full capistrano/rails since
# it includes the asset compilation, DB migrations and bundler
require 'capistrano/rails'

load File.expand_path('../../tasks/apache.rake', __FILE__)
load File.expand_path('../../tasks/apache_co7.rake', __FILE__)
load File.expand_path('../../tasks/app_home.rake', __FILE__)
load File.expand_path('../../tasks/application.rake', __FILE__)
load File.expand_path('../../tasks/database.rake', __FILE__)
load File.expand_path('../../tasks/secrets.rake', __FILE__)
load File.expand_path('../../tasks/util.rake', __FILE__)
