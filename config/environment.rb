# frozen_string_literal: true

require 'bundler'
require 'pathname'
require 'dotenv/load' unless ENV['APP_ENV'] == 'production'

$LOAD_PATH.unshift(Dir.pwd)

Bundler.require

Dir[Pathname.new(Dir.pwd).join('app/**/*.rb')].sort.each do |file|
  require file
end
