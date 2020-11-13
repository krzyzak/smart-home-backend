class PVReadoutJob
  include Sidekiq::Worker

  def perform
    PVReadout.new.call
  end
end
