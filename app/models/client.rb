class Client < ActiveRecord::Base

  include HTTParty
  include GoogleAnalytics
  include ClientUser

  base_uri 'google-analytics.com'

  require 'pp'

  def initiate

    client = Slack::RealTime::Client.new

    client.on :hello do
      puts "Successfully connected, welcome '#{client.self.name}' to the '#{client.team.name}' team at https://#{client.team.domain}.slack.com."
      get_bot_user(client)
    end

    client.on :message do |data|
      track_message(data)
      respond_to_message(data: data, client: client)
    end

    client.on :team_join do |data|
      send_scheduled_messages(client: client, data: data)
      add_new_user(data)
    end

    client.on :user_change do |data|
      update_user(data)
    end

    client.on :close do |_data|
      puts 'Connection closing, exiting.'
      initiate_another_client
    end

    client.on :closed do |_data|
      puts 'Connection has been disconnected.'
    end

    # Other setups we need
    set_channel_info(client)
    set_channel_id(client)
    reschedule_messages(client)
    update_user_list(client) #todo: maybe put this in a rake file

    Rails.application.config.client = client

    client.start_async
  end

  def channel_id_to_name(data)
    channel = nil
    if @@channel_list
      channel = @@channel_list.select {|channel| channel.id == data.channel}.first
    end
    channel != nil ? channel.name : "nil"
  end

  private
  def add_new_user(data)
    get_users
    unless @users.any? { |person| person.slack_id == data.user.id }
      @user = User.new(
        user_name:  data.user.name,
        real_name:  data.user.profile.real_name,
        slack_id:   data.user.id,
        email:      data.user.profile.email,
        pic:        data.user.profile.image_192,
        channel_id: client.web_client.im_open(user: data.user.id).channel.id
      )
      @user.save
      # identify(@user)
    end
  end

  def update_user(data)
    puts "A user changed! (And I'm still running. Yay!)"
    set_user(data)
    @user.user_name = data.user.name
    @user.real_name = data.user.profile.real_name
    @user.slack_id =  data.user.id
    @user.email =     data.user.profile.email
    @user.pic =       data.user.profile.image_192
    @user.save
    # identify(@user)
  end

  def get_bot_user(client)
    get_users
    puts "Bot name: #{client.self.name}"
    bot = @users.select { |bot| bot.user_name == client.self.name }.first
    #Set global to be used for health check and "respond_to_messages"
    Rails.application.config.bot_id = bot.slack_id
    puts "Bot ID: #{Rails.application.config.bot_id}"
  end

  def send_message(channel, text, client)
    client.web_client.chat_postMessage(
      channel: channel,
      text: text,
      as_user: true,
      unfurl_links: false,
      unfurl_media: false
    )
  end

  def create_log(user, message)
    #message_number is "delay" in seconds.
    delivery_time = Time.now + message.message_number
    @log = Log.new(
      channel_id: user.channel_id,
      message_id: message.id,
      delivery_time: delivery_time
    )
    @log.save
  end

  def send_scheduled_messages(client:, data:)
    sleep(2)
    set_user(data)
    @messages = Message.all.sort
    @messages.each do |message|
      create_log(@user, message)
      s = Rufus::Scheduler.new(:max_work_threads => 200)
      s.in message.delay do
        ActiveRecord::Base.connection_pool.with_connection do
          send_message(@user.channel_id, message.text, client)
          track_scheduled_message(@user, message.id, message.text)
          message.reach += 1
          message.save
          Log.where(message_id: message.id).first.delete
        end
      end
    end
  end

  def respond_to_message(data:, client:)
    return if data.user == Rails.application.config.bot_id
    channel = data.channel

    if channel[0] == "D" && data.text
      if interaction = Interaction.where(user_input: data.text.downcase).first
        text = interaction.response
        track_interactions(data, interaction.id, interaction.user_input, text)
        interaction.hits += 1
        interaction.save
      else
        text = get_response_for_data(data)
        track_interactions(data, 0, "no trigger", "standard_response")
      end

      send_message(channel, text, client)
    end
  end

  def get_response_for_data(data)
    feedback_resp = "To give us a feedback, use `feedback:`... eg: `feedback: You are awesome!!!`"

    case data.text
      when "help", "Help"
        if Interaction.any?
          interactions = Interaction.all.map{ |i| "`#{i.user_input}`" }
          interactions << feedback_resp
          interactions.join("\n")
        else
          "Nothing configured at the moment, do check back later."
        end
      when /^feedback:/
        post_feedback(data)
        "Thank you for the feedback, it has been logged, and will be addressed"
      else
        <<~RESPONSE
          Hi <@#{data.user}>!, sorry, I do not have response for this message...,
          For a list of possible interactions, type `help`
          #{feedback_resp}
        RESPONSE
    end
  end

  def post_feedback(data)
    client = Rails.application.config.client
    channel = User.find_by(user_name: ENV['FEEDBACKS_TO']).channel_id
    text = ">#{data.text.gsub('feedback:', '').strip}\nFrom: <@#{data.user}>"

    send_message(channel, text, client)
  end

  #Grabs the channel data from slack's api
  #to be used by "channel_id_to_name" method
  def set_channel_info(client)
    @@channel_list = nil
    s = Rufus::Scheduler.new(:max_work_threads => 200)
    #Wait 5s so that the client is setup before trying to run.
    s.in '5s' do
      @@channel_list = client.web_client.channels_list.channels
    end
    s = Rufus::Scheduler.new(:max_work_threads => 200)
    s.every '15m' do
      @@channel_list = client.web_client.channels_list.channels || @@channel_list
    end
  end

  def reschedule_messages(client)
    Log.all.each do |log|
      if log.delivery_time > Time.now
        s = Rufus::Scheduler.new(:max_work_threads => 200)
        s.at log.delivery_time do
          ActiveRecord::Base.connection_pool.with_connection do
            message = Message.find(log.message_id)
            send_message(log.channel_id, message.text, client)
            track_rescheduled_message(log, log.message_id, message.text)
            message.reach += 1
            message.save
            log.delete
          end
        end
      end
    end
  end

  def initiate_another_client
    Client.new.initiate
  end

  # ######################################################################################################################
  # # STUFFS WE WANT TRACKED
  # ######################################################################################################################

  def word_count(text)
    return '0' unless text.is_a? String
    text.split.count
  end

  def emoji_count(text)
    return '0' unless text.is_a? String
    text.scan(/:[a-z_0-9]*:/m).count
  end

  def excla_count(text)
    return '0' unless text.is_a? String
    text.count('!')
  end

  def elipse_count(text)
    return '0' unless text.is_a? String
    text.scan(/\.\.\./m).count
  end

  def question_mark(text)
    return '0' unless text.is_a? String
    text.count('?')
  end

  # ######################################################################################################################

end
