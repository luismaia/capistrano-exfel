# Load DSL and Setup Up Stages
require 'capistrano/setup'

# Includes default deployment tasks
require 'capistrano/deploy'

# Includes tasks from other gems included in your Gemfile
require 'capistrano/rvm'

# Includes tasks for rails
require 'capistrano/rails'

load File.expand_path('../tasks/apache.rake', __dir__)
load File.expand_path('../tasks/app_home.rake', __dir__)
load File.expand_path('../tasks/assets.rake', __dir__)
load File.expand_path('../tasks/application.rake', __dir__)
load File.expand_path('../tasks/database.rake', __dir__)
load File.expand_path('../tasks/secrets.rake', __dir__)
load File.expand_path('../tasks/util.rake', __dir__)
