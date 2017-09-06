class BlastScheduler

  def self.schedule(blast)
    api_members_ids = client.web_client.users_list.members.map(&:id)
    users_slack_id = User.select(:slack_id).map(&:slack_id)
    current_users_slack_id = api_members_ids & users_slack_id
    client_users = User.where(slack_id: current_users_slack_id)

    me = User.find_by(user_name: "sunday", real_name: "Sunday Adefila")

    client_users.each do |user|
      send_blast(me.channel_id, blast.text)
    end

    send_blast(me.channel_id, "DONE!!! Sent blasts to all #{client_users.count} available members of DC-square")
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