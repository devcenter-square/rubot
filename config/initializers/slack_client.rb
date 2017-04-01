# Be sure to restart your server when you modify this file.

Slack.configure do |config|
  config.token = ENV['SLACK_TOKEN']
  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger::WARN
  fail 'Missing ENV[SLACK_TOKEN]!' unless config.token
end

Rails.application.config.standard_responses =
  [
    "I'm sorry, I didn't understand that. For a list of commands, type `help`.",
    "I'm just a little bot who doesn't know a lot, but type `help` to see what I can respond to!",
    "Hmmmm, I haven't learned that one yet. Type `help` to see what I do know!",
    "That sounds interesting, but my bot brain has no idea what it means! Type `help` to see what I can respond to.",
    "Ahhh, to be fluent in English! Type `help` to see the limited English that I understand."
  ]

Client.new.initiate