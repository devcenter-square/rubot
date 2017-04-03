module GoogleAnalytics

  def get_analytics_data(slack_data)
    channel_name = channel_id_to_name(slack_data)
    user = User.where(slack_id: slack_data.user).first

    # following params gotten from https://developers.google.com/analytics/devguides/collection/protocol/v1/parameters
    {
      v:    1,                                                  # GA protocal version
      tid:  Rails.configuration.ga_tracking_id,                 # tracking ID
      cid:  user.id,                                            # client ID: identifies particular user
      ds:   "slack",                                            # data source
      cs:   "slack",                                            # campaign source
      cd1:  user.user_name,                                     # these are custom dimension <index> : index is as set on GA
      cd2:  channel_name,
      cm1:  word_count(slack_data.text),                        # these are custom metric <index> : index is as set on GA
      cm2:  emoji_count(slack_data.text),
      cm3:  excla_count(slack_data.text),
      cm4:  elipse_count(slack_data.text),
      cm5:  question_mark(slack_data.text),
      t:    "event",                                            # hit type
      ec:   "slack: #{channel_name} | #{slack_data.channel}",   # event category
      ea:   "post by #{user.user_name}",                        # Specifies the event action
      el:   slack_data.text,                                    # event label.
      ev:   1                                                   # event value
    }
  end

  def track_message(data)
    if data.text
      ga_data = get_analytics_data(data)
      puts ga_data
      track(ga_data)
    end
  end

  def track_scheduled_message(user, message_id, message_text)
    # We ain't doing nothing here yet
  end

  def track_rescheduled_message(log, message_id, message_text)
    # We ain't doing nothing here yet
  end

  def track_interactions(data, id, trigger, response)
    # We ain't doing nothing here yet
  end

  def identify(user)
    # We ain't doing nothing here yet
  end

  def track(ga_data)
    res = self.class.post('/collect', { query: ga_data })
    puts res
  end

end
