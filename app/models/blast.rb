class Blast < ActiveRecord::Base

  after_create :schedule_for_broadcast

  def schedule_for_broadcast
    s = Rufus::Scheduler.new(max_work_threads: 2000)

    s.in '10s' do
      BlastScheduler.schedule(self)
    end
  end
end
