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

Time.zone = 'Central Time (US & Canada)'

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
