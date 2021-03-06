workers 3

# Min and Max threads per worker
threads 1, 3 # relying on more workers

# Default to production
rails_env = ENV['RAILS_ENV'] || "production"
if rails_env == 'production'
  environment rails_env
  daemonize   true

  app_dir = File.expand_path("../..", __FILE__)

  bind "unix:///var/run/puma/my_app.sock"
  pidfile "/var/run/puma/my_app.sock"

  on_worker_boot do
    require "active_record"
    ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
    ActiveRecord::Base.establish_connection(YAML.load_file("#{app_dir}/config/database.yml")[rails_env])
  end
end
