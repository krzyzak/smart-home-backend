class SpeedtestReadoutJob
  include Sidekiq::Worker
  sidekiq_options retry: 0

  def perform
    SpeedtestReadout.new.call
  end
end
