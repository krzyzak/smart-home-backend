class AirlyReadoutJob
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    AirlyReadout.new.call
  end
end
