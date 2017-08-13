class Blast < ActiveRecord::Base

  def self.send_blast(channel_id, blast, client)
    client.web_client.chat_postMessage(
      channel: channel_id, 
      text: blast.text,
      as_user: true,
      unfurl_links: false,
      unfurl_media: false
      )
  end

  def self.schedule_blasts(client)
    blast = Blast.last

    # 5 seconds from now
    time = Time.now + 5
    api_members = client.web_client.users_list.members
    User.all.each do |user|
      if api_members.any? { |member| member.id == user.slack_id } && user.channel_id
        # members get blasts in 2 seconds interval... is this necessary?
        time += 2
        s = Rufus::Scheduler.new(:max_work_threads => 1000)
        s.at time do
          send_blast(user.channel_id, blast, client)
          puts "Sent BLAST FOR USER #{user.user_name} AT #{Time.now}"
        end
      end
    end
  end
end
