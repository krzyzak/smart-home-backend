# frozen_string_literal: true

class Fibaro
  def all
    request
      .get(url('/api/devices'))
      .parse
  end

  def get(id)
    request
      .get(url("/api/devices/#{id}"))
      .parse
  end

  def alarm_devices
    @alarm_devices ||= visible_devices.select { |item| item['baseType'] == 'com.fibaro.securitySensor' }
  end

  def other_devices
    @other_devices ||= visible_devices.reject { |item| item['baseType'] == 'com.fibaro.securitySensor' }
  end

  private

  def visible_devices
    @visible_devices ||= all.select do |item|
      item['enabled'] && item['visible'] && item.fetch('properties', {}).key?('value')
    end
  end

  def request
    HTTP.basic_auth(user: ENV['FIBARO_USER'], pass: ENV['FIBARO_PASSWORD'])
  end

  def url(path)
    [ENV['FIBARO_URI'], path].join('')
  end
end
