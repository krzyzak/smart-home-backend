# frozen_string_literal: true

class TauronReadout
  TAURON_URL = 'https://elicznik.tauron-dystrybucja.pl'

  def initialize(date = Date.today.prev_day)
    @date = date
  end

  def call
    return unless readouts

    data.each do |key, points|
      points.each do |point|
        influx.write_point(key.to_s, point)
      end
    end
  end

  def data
    {
      generation: generation,
      consumption: consumption,
      delta: delta,
      balance: balance
    }
  end

  private

  attr_reader :date

  def generation
    readouts.dig('dane', 'OZE').map do |_, readout|
      {
        values: { value: readout['EC'].to_f },
        timestamp: (Date.parse(readout['Date']).to_time + (60 * 60 * readout['Hour'].to_i)).to_i
      }
    end
  end

  def consumption
    readouts.dig('dane', 'chart').map do |readout|
      {
        values: { value: readout['EC'].to_f },
        timestamp: (Date.parse(readout['Date']).to_time + (60 * 60 * readout['Hour'].to_i)).to_i
      }
    end
  end

  def delta
    generation.zip(consumption).map do |(generation, consumption)|
      value = generation.dig(:values, :value) - consumption.dig(:values, :value)

      {
        values: { value: value },
        timestamp: generation[:timestamp]
      }
    end
  end

  def balance
    value = Nokogiri::HTML(@html).css('.gray-box dd.scale').text.to_i

    [{ values: { value: value * 1000 } }]
  end

  def readouts
    request unless defined? @readouts
    @readouts
  end

  def login_data
    {
      username: ENV['TAURON_USER'],
      password: ENV['TAURON_PASSWORD'],
      service: 'https://elicznik.tauron-dystrybucja.pl'
    }
  end

  def request
    HTTP
      .persistent('https://logowanie.tauron-dystrybucja.pl') do |http|
        response = http.follow.get('/login?service=https://elicznik.tauron-dystrybucja.pl', ssl_context: ssl_context)
        cookies = response.cookies

        login_req = http.cookies(cookies).post('/login', form: login_data, ssl_context: ssl_context)
        login_req.body.to_s
        redir_uri = URI(login_req.headers['Location'])

        HTTP
          .cookies(login_req.cookies)
          .persistent("https://#{redir_uri.host}") do |inner_http|
            @html = inner_http.get("/?#{redir_uri.query}", ssl_context: ssl_context).body.to_s
            inner_body = inner_http.post('/index/charts', params: params, ssl_context: ssl_context).body
            @readouts = inner_body.empty? ? nil : JSON.parse(inner_body)
          end
      end
  end

  def params
    {
      'dane[chartDay]': date.strftime('%d.%m.%Y'),
      'dane[paramType]': 'day',
      'dane[smartNr]': ENV['TAURON_METER_ID'],
      'dane[checkOZE]': 'on'
    }
  end

  def ssl_context
    @ssl_context ||= begin
      ssl_context = OpenSSL::SSL::SSLContext.new
      ssl_context.security_level = 1
      ssl_context.ssl_version = :TLSv1
      ssl_context
    end
  end

  def influx
    @influx ||= InfluxDB::Client.new('pv', host: ENV['INFLUXDB_HOST'])
  end
end
