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
# Allow for Rails-style test names, where test names can be defined with
# strings rather than a Ruby-method name with underscores.
#
# Usage:
#
#   class
#     extend DefineTestNamesWithStrings
#     ...
#     test "a descriptive test name" do
#       ...
#     end
#   end
#
# Note: We could have just pulled this in from ActiveSupport::TestCase,
# but I wanted to avoid the dependency.
#
module DefineTestNamesWithStrings

  # Helper to define a test method using a String. Under the hood, it replaces
  # spaces with underscores and defines the test method.
  #
  #   test "verify something" do
  #     ...
  #   end
  def test(name, &block)
    test_name = "test_#{name.gsub(/\s+|,/,'_')}".to_sym
    defined = method_defined? test_name
    raise "#{test_name} is already defined in #{self}" if defined
    if block_given?
      define_method(test_name, &block)
    else
      define_method(test_name) do
        flunk "No implementation provided for #{name}"
      end
    end
  end
end

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
