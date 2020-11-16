class NetatmoReadoutJob
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    NetatmoReadout.new.call
  end
end
