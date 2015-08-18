$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require 'formant'

require 'minitest/autorun'
require 'minitest/pride'

require "minitest/reporters"
Minitest::Reporters.use!(
  Minitest::Reporters::SpecReporter.new,
  ENV,
  Minitest.backtrace_filter
)

#
# Randomly set an American timezone to help expose timezone-related bugs:
#
_us_time_zones = ActiveSupport::TimeZone.us_zones.map(&:name)
Time.zone = _us_time_zones[rand(_us_time_zones.length)]
puts "[Setting random US timezone: #{Time.zone}]"


I18n.backend.store_translations :en, {
  time: {
    formats: {
      day_date_time: '%a, %b %e, %l:%M %p',
      time_day_date: '%l:%M %p - %a %b %e',
      fullday_date_time: '%A, %B %e, %l:%M %p',
      :default => "%a, %d. %b %Y %H:%M:%S %z",
      :short => "%d. %b %H:%M",
      :long => "%d. %B %Y %H:%M"
    },
    am: 'am',
    pm: 'pm'
  }
}
