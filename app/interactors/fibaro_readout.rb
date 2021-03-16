# frozen_string_literal: true

require 'sixarm_ruby_unaccent'
require 'hanami/utils/string'
require 'hanami/utils/hash'

class FibaroReadout
  def call
    fibaro_influx.write_points(other_devices_data)

    alarm_devices_data.each do |device, value|
      alarm_influx.write_point(device, value)
    end
  end

  def other_devices_data
    @other_devices_data ||= fibaro.other_devices.map do |device|
      values = device_value(device)

      {
        series: 'hc3',
        tags: {
          device: device['id'],
          name: device['name']
        },
        values: values
      }
    end.compact
  end

  def alarm_devices_data
    @alarm_devices_data ||= fibaro.alarm_devices.map do |device|
      values = alarm_device_value(device)

      next if should_skip_alarm_device_write?(device, values)

      device_name = Hanami::Utils::String.dasherize(device['name']).unaccent
      [device_name, { values: values }]
    end.compact
  end

  private

  def device_value(device)
    value = device.dig('properties', 'value')

    if device.fetch('interfaces', []).include?('energy')
      return { energy: device.dig('properties', 'energy'), power: device.dig('properties', 'power') }
    end

    if value.is_a?(Numeric)
      { num_value: value.to_f }
    elsif device['properties'].key?('alarm')
      {
        lastBreached: device.dig('properties', 'lastBreached'),
        bool_value: device.dig('properties', 'value'),
        value: device.dig('properties', 'value'),
        tamper: device.dig('properties', 'tamper'),
        tamperAlarm: device.dig('properties', 'tamperAlarm'),
        alarm: device.dig('properties', 'alarm')
      }
    elsif value === true || value === false
      { bool_value: value }
    else
      raise ArgumentError, device
    end
  end

  def alarm_device_value(device)
    {
      lastBreached: device.dig('properties', 'lastBreached'),
      tamper: device.dig('properties', 'tamper'),
      tamperAlarm: device.dig('properties', 'tamperAlarm'),
      alarm: device.dig('properties', 'alarm'),
      state: alarm_device_state(device['properties']).to_s
    }
  end

  def alarm_device_state(device)
    return :tamper if device['tamper'] || device['tamperAlarm']
    return :alarm if device['alarm']

    device['value'] ? :breached : :ok
  end

  def should_skip_alarm_device_write?(device, values)
    device_name = Hanami::Utils::String.dasherize(device['name']).unaccent.gsub('.', '')

    query = alarm_influx.query(%(SELECT * FROM "#{device_name}" ORDER BY DESC LIMIT 1))

    return true if query.empty?

    data = Hanami::Utils::Hash.symbolize(query.first['values'].first.slice('alarm', 'lastBreached', 'state', 'tamper', 'tamperAlarm'))
    data == values
  end

  def fibaro
    @fibaro ||= Fibaro.new
  end

  def fibaro_influx
    @fibaro_influx ||= InfluxDB::Client.new('fibaro', host: ENV['INFLUXDB_HOST'])
  end

  def alarm_influx
    @alarm_influx ||= InfluxDB::Client.new('alarm', host: ENV['INFLUXDB_HOST'])
  end
end
