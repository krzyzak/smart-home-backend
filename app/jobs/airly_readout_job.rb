class AirlyReadoutJob
  include Sidekiq::Worker
  sidekiq_options retry: 0

  def perform
    AirlyReadout.new.call
  end
end
