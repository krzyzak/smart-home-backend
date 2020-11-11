class SpeedtestReadoutJob
  include Sidekiq::Worker

  def perform
    SpeedtestReadout.new.call
  end
end
