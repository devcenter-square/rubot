# Be sure to restart your server when you modify this file.

Slack.configure do |config|
  config.token = ENV['SLACK_TOKEN']
  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger::WARN
  fail 'Missing ENV[SLACK_TOKEN]!' unless config.token
end
