class NetatmoReadoutJob
  include Sidekiq::Worker
  sidekiq_options retry: 0

  def perform
    NetatmoReadout.new.call
  end
end
