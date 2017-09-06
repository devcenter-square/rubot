class BlastScheduler

  def self.schedule(blast)
    api_members_ids = client.web_client.users_list.members.map(&:id)
    users_slack_id = User.select(:slack_id).map(&:slack_id)
    current_users_slack_id = api_members_ids & users_slack_id
    client_users = User.where(slack_id: current_users_slack_id)

    time = Time.now + 5
    rs = Rufus::Scheduler.new(max_work_threads: 1000)

    client_users.each do |user|
      # DO NOT SPAM!!! send message at 2sec intervals. https://api.slack.com/docs/rate-limits
      time += 2
      rs.at time do
        send_blast(user.channel_id, blast.text)
      end
    end

    # TODO: Just for debugging, remove this soon
    me = User.find_by(user_name: "sunday", real_name: "Sunday Adefila")
    time += 2
    rs.at time do
      send_blast(me.channel_id, "DONE!!! Sent blasts to all #{client_users.count} available members of DC-square")
    end

  end

  def self.send_blast(channel_id, text)
    client.web_client.chat_postMessage(
      channel: channel_id,
      text: text,
      as_user: true,
      unfurl_links: false,
      unfurl_media: false
    )
  end

  private
  def self.client
    @client ||= Rails.application.config.client
  end
end