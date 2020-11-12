class FibaroReadoutJob
  include Sidekiq::Worker

  def perform
    FibaroReadout.new.call
  end
end
