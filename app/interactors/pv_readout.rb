require 'hanami/utils/hash'

class PVReadout
  def call
    readout.each do |key, value|
      influx.write_point(key.to_s, values: { value: value })
    end
  end

  private

  def readout
    {
      day_energy: data.dig(:DAY_ENERGY, :Values, :"1") || 0,
      current_energy: data.dig(:PAC, :Values, :"1") || 0,
      total_energy: data.dig(:TOTAL_ENERGY, :Values, :"1") || 0,
      year_energy: data.dig(:YEAR_ENERGY, :Values, :"1") || 0
    }.transform_values(&:to_f)
  end

  def data
    @data ||= begin
      body.dig(:Body, :Data)
              rescue HTTP::ConnectionError, HTTP::TimeoutError
                {}
    end
  end

  def body
    @body ||= Hanami::Utils::Hash.deep_symbolize(request.parse)
  end

  def request
    @request ||= HTTP
                 .timeout(3)
                 .get(
                   url,
                   params: { Scope: :System }
                 )
  end

  def url
    "#{ENV['INVERTER_URI']}/solar_api/v1/GetInverterRealtimeData.cgi"
  end

  def influx
    @influx ||= InfluxDB::Client.new('pv', host: ENV['INFLUXDB_HOST'])
  end
end
