class SpeedtestReadout
  def call
    data.each do |key, value|
      influx.write_point(key.to_s, values: {value: value})
    end
  end

  def data
    {
      download: speedtest.download_rate / (1024 * 1024),
      upload: speedtest.upload_rate / (1024 * 1024),
      latency: speedtest.latency
    }
  end

  private

  def speedtest
    @speedtest ||= Speedtest::Test.new.run
  end

  def influx
    @influx ||= InfluxDB::Client.new('speedtest', host: ENV['INFLUXDB_HOST'])
  end
end
