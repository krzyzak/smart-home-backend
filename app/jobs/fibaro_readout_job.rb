class FibaroReadoutJob
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    FibaroReadout.new.call
  end
end
