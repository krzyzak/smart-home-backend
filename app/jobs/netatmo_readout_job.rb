class NetatmoReadoutJob
  include Sidekiq::Worker

  def perform
    NetatmoReadout.new.call
  end
end
