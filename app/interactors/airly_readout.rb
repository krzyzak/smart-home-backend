# frozen_string_literal: true

class AirlyReadout
  def call
    return if data.values.none?

    data.each do |key, value|
      influx.write_point(key.to_s, values: { value: value })
    end
  end

  def data
    @data ||= {
      pm1: find_readout('pm1'),
      pm10: find_readout('pm10'),
      pm25: find_readout('pm25'),
      humidity: find_readout('humidity'),
      pressure: find_readout('pressure'),
      temperature: find_readout('temperature'),
      caqi: find_index('airly_caqi')
    }
  end

  private

  def find_readout(name)
    readout['values'].find(-> { {} }) { |r| r['name'] == name.upcase }['value']
  end

  def find_index(name)
    readout['indexes'].find(-> { {} }) { |r| r['name'] == name.upcase }['value']
  end

  def date
    from..to
  end

  def from
    DateTime.parse(readout['fromDateTime']).utc
  end

  def to
    DateTime.parse(readout['tillDateTime']).utc
  end

  def readout
    @readout ||= JSON.parse(request.body)['current']
  end

  def request
    @request ||= HTTP
                 .headers(apikey: ENV['AIRLY_API_KEY'])
                 .get(
                   'https://airapi.airly.eu/v2/measurements/point',
                   params: { lat: ENV['AIRLY_LAT'], lng: ENV['AIRLY_LNG'] }
                 )
  end

  def influx
    @influx ||= InfluxDB::Client.new('airly', host: ENV['INFLUXDB_HOST'])
  end
end
