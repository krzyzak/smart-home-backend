class NetatmoReadout
  def call
    return unless readout

    data.each do |key, value|
      influx.write_point(key.to_s, values: { value: value })
    end
  end

  def data
    {
      co2: device.values[:co2].value,
      temperature_outside: outdoor_module.values[:temperature].value,
      temperature_inside: device.values[:temperature].value,
      humidity_outside: outdoor_module.values[:humidity].value,
      humidity_inside: device.values[:humidity].value,
      rainfall: rain_module.values[:rain].value
    }
  end

  private

  def client
    @client ||= Netatmo::Client.new do |config|
      config.client_id = ENV['NETATMO_CLIENT_ID']
      config.client_secret = ENV['NETATMO_CLIENT_SECRET']
      config.username = ENV['NETATMO_USERNAME']
      config.password = ENV['NETATMO_PASSWORD']
    end
  end

  def device
    readout.devices.first
  end

  def readout
    @readout ||= begin
      client.get_station_data
    rescue RuntimeError # client raises RuntimeError in case of unsuccessfull response :(
      nil
    end
  end

  def outdoor_module
    @outdoor_module ||= device.modules.find(&:outdoor_module?)
  end

  def rain_module
    @rain_module ||= device.modules.find(&:rain_gauge?)
  end

  def influx
    @influx ||= InfluxDB::Client.new('netatmo', host: ENV['INFLUXDB_HOST'])
  end
end
