class AirlyReadoutJob
  include Sidekiq::Worker

  def perform
    AirlyReadout.new.call
  end
end
