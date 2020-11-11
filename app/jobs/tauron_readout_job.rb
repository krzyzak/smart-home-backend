class TauronReadoutJob
  include Sidekiq::Worker

  def perform
    TauronReadout.new.call
  end
end
