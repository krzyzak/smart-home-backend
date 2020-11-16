class SpeedtestReadoutJob
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    SpeedtestReadout.new.call
  end
end
