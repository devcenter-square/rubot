workers  5
threads  1, 1 # relying on many workers for thread-unsafe apps

environment ENV['RACK_ENV'] || 'production'
daemonize   true

bind "unix:///var/run/puma/my_app.sock"
pidfile "/var/run/puma/my_app.sock"
