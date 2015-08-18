# Formant

[![Build Status](https://travis-ci.org/polypressure/formant.svg?branch=master)](https://travis-ci.org/polypressure/formant)
[![Test Coverage](https://codeclimate.com/github/polypressure/formant/badges/coverage.svg)](https://codeclimate.com/github/polypressure/formant/coverage)
[![Code Climate](https://codeclimate.com/github/polypressure/formant/badges/gpa.svg)](https://codeclimate.com/github/polypressure/formant)


Formant is a tiny library that provides a simplified, minimalistic form object implementation for Rails applications. A form object is a simple, (mostly) plain-old Ruby object, separate from your ActiveRecord models, that lets you collect and validate input. A bit more specifically, Formant helps you to keep any input parsing, normalization, validation, and formatting logic related to form processing out of your ActiveRecord models, ensuring that they stay lean and focused on persistence.

Form objects also simplify the collection of input from complicated forms. With form objects, when collecting input that involves multiple ActiveRecord models, you can avoid having to use something like `accepts_nested_attributes_for`. Instead, you define a single form object containing all the necessary fields spanning multiple models. You use this single form object in place of the multiple ActiveRecord models within your view, form, and controller. You can then parse, normalize, and validate that input in one place, and pass/distribute the form field values to whatever number of model objects are required by your business logic.

With Formant, you can declaratively specify any special parsing and normalization logic to apply to the form field values upon input (i.e. right before validation). Some built-in examples of parsing/normalizing input include:

* Stripping leading and trailing whitespace, and squishing internal whitespace.
* Parsing date/time strings using the current timezone.
* Normalizing phone numbers into a consistent internal format, e.g. "+13125551212" for storage in the database.
* Normalizing and parsing currency strings into a BigDecimal.

Once parsed and normalized, Formant then applies any validation rules that you've specified, using the standard validation macros provided by ActiveRecord. These can be invoked as usual, i.e. with the `valid?`, `invalid?`, or `validate` methods.

Formant also lets you specify special formatting rules on fields upon output (typically, when redisplaying forms). Some built-in examples of formatting output include:

* Rendering date/time values using localized string formats.
* Displaying phone numbers in a standard format, e.g. "(312) 555-1212"
* Formatting a BigDecimal value as a currency/price string.
* Formatting a number delimited with commas and decimal points.




## Installation

Add this line to your application's Gemfile:

```ruby
gem 'formant'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install formant


### Configuration

Add the following to your `config/application.rb`:

```ruby
module MyApplication
  class Application < Rails::Application
    ...
    config.autoload_paths << Rails.root.join('forms')
  end
end
```

You can create a locale file containing date/time formats named `time_formats.en.yml`. In a standard Rails application, this file would go in the `config/locales` directory, and would look something like this:

```ruby
en:
  time:
    formats:
      day_date_time: '%a, %b %e, %l:%M %p'
      time_day_date: '%l:%M %p - %a %b %e'
      fullday_date_time: '%A, %B %e, %l:%M %p'

```

## Usage

Define your form as a subclass of `Formant::FormObject`, specify the fields using `attr_accessor`, then specify parsing, validation, and formatting rules. Your form objects should go in the app/forms directory:

```ruby
class AppointmentForm < FormObject

  attr_accessor(
    :starts_at,
    :first_name, :last_name,
    :phone, :email,
    :monthly_revenue,
    :some_big_number
  )

  #
  # Rules for any special parsing/transformation upon input…
  #

  # This parses datetime strings using the current Time.zone
  # into a ActiveSupport::TimeWithZone object:
  parse :starts_at, as: :datetime

  # This normalizes phone numbers into a consistent internal format
  # (with no dashes, dots, or other separators, and a leading "+1").
  # For example, if the user passes in a phone number in the format
  # "312-555-1212" or "(312)555.1212", it will be normalized
  # into the format "+13125551212":
  parse :phone, as: :phone_number

  # This normalizes and parses a string price (possibly containing
  # currency symbols, commas, and decimal points) into a BigDecimal
  # value:
  parse :monthly_revenue, as: :currency


  # This strips leading and trailing whitespace from the field values:
  parse :last_name, to: :strip_whitespace
  parse :email, to: :strip_whitespace
  # This also collapses multiple consecutive internal spaces into a single space:
  parse :first_name, to: :strip_whitespace, squish: true


  #
  # Rules for any special formatting/transformation upon output
  # or redisplay of the form. These will be triggered by invoking
  # the FormObject#reformatted! method…
  #

  # This reformats the datetime in the :starts_at field using the
  # format specified by the :day_date_time key, which can be defined
  # in config/locales/time_formats.en.yml file:
  reformat :starts_at, as: :datetime, format: :day_date_time

  # This reformats the phone number in the :phone field into a
  # standard format for the 'US'. For a phone number normalized
  # to "+13125551212", the reformatted number is "(312) 555-1212":
  reformat :phone, as: :phone_number, country_code: 'US'

  # This reformats the BigDecimal in the :monthly_revenue field
  # into a string, eg. "$10,252.32". You can pass it options as
  # defined in http://api.rubyonrails.org/classes/ActionView/Helpers/NumberHelper.html#method-i-number_to_currency
  reformat :monthly_revenue, as: :currency

  # This reformats the number in the :some_big_number field into
  # string delimited with commas and decimal points, e.g.
  # "25,123.08". You can pass it options as # defined in
  # http://api.rubyonrails.org/classes/ActionView/Helpers/NumberHelper.html#method-i-number_with_delimiter
  reformat :some_big_number, as: :number_with_delimiter

  #
  # Validation rules, as usual:
  #
  validates :starts_at, presence: true
  validate :in_future

  validates :first_name, presence: true
  validates :last_name, presence: true

  validates_plausible_phone :phone, presence: true
  validates :email, presence: true, email: true

  def in_future
    errors.add(:starts_at, "must be in the future") if starts_at && starts_at.past?
  end

end
```

In your controller, instantiate a FormObject by passing it the request params, then validate the input params by calling either `valid?` or `invalid?`. If validation succeeds, you can then pass the form field values to any models or business-logic objects. If validation fails, you can redisplay the form as usual, passing the form object (rather than the model object) to the view—just as you would with an ActiveRecord model:

```ruby
class AppointmentsController < ApplicationController

  def create
    appointment_form = AppointmentForm.new(appointment_params)

    #
    # Ideally, this should be in a separate business-logic object,
    # we're showing this logic inline within the controller for
    # the sake of simplicity:
    #
    if appointment_form.invalid?
      @appointment_form = appointment_form.reformatted!
      render :new and return
    end

    client = Client.new(
      first_name: appointment_form.first_name,
      last_name: appointment_form.last_name,
      phone: appointment_form.phone,
      email: appointment_form.email
    )  

    appointment = Appointment.new(
      starts_at: appointment_form.starts_at
    )

    client.save!
    appointment.save!

    redirect_to appointments_path, notice: "Your appointment has been booked."
  end

end
```

Your form looks just as it normally would, but rather than using your ActiveRecord models directly, you use the form object instead. Here's an example written in the Slim templating language:

```ruby
h4 Make an appointment

= form_for(@appointment_form, url: appointments_url) do |f|
  = render "shared/validation_errors", errors: @appointment_form.errors

  .row.collapse
    .small-2.columns
      = f.text_field :starts_at, placeholder: 'Date/Time', required: true
    .small-2.columns
      = f.text_field :first_name, placeholder: 'First Name', required: true
    .small-2.columns
      = f.text_field :last_name, placeholder: 'Last Name', required: true
    .small-2.columns
      = f.text_field :phone, placeholder: 'Phone', required: true
    .small-2.columns
      = f.text_field :email, placeholder: 'Email', required: true, type: 'email'

  .row
    .small-12.columns
      = f.button 'Submit'
```
You can see that you can access the fields and the validation errors as you usually would with an ActiveRecord model.

### Other stuff

You can get a params hash of all the form object's attribute by calling `to_params`.

You can register callbacks to be invoked before and after validation:

```ruby
class MyForm < Formant::FormObject
  ...

  before_validation :do_stuff_before_validation
  after_validation  :do_stuff_after_validation

  ...

  def do_stuff_before_validation
    # Some pre-validation logic.
  end

  def do_stuff_after_validation
    # Some post validation logic.
  end

end

```

## Additional parsing and reformatting rules

Parsing and formatting rules can be added trivially. Here is an example for how you would add rules for converting a blank string into a nil:

```ruby
#
#
module BlankAsNil

  #
  # All parse rule methods must have a name beginning with
  # the prefix "parse_" and ending with the parse rule type.
  # In this example, the parse rule type is "slug".
  #
  # The method signature should always be as follows: the first
  # argument is field_value, in which Formant passes the unparsed
  # value of the form field/attribute. The second argument
  # contains a hash of any options required by your parse rule
  # logic.
  #
  # Your parse method should return the parsed value of course.
  # Formant takes care of assigning it to the field attribute.
  #
  def parse_blank_into_nil(field_value, options={})
    field_value.nil? || (field_value.is_a?(String) && field_value !~ /\S/) ? nil : field_value
  end


  #
  # For a reformatting rule, it's pretty much the same thing,
  # except you replace the "parse_" prefix in the method name
  # with "format_".
  #
  # This is an example for formatting numbers with a delimiter,
  # assuming Formant didn't already provide this:
  #
  def format_number_with_delimiter(field_value, options={})
    number_with_delimiter(field_value, options)
  end

end

#
# You can then specify that the parse rule can be used as normal
# with the parse macro/directive:
#
class MyForm < Formant::FormObject
  include MoreParsingAndFormattingRules

  attr_accessor :title, :some_number

  parse :title, as: :blank_into_nil
  format :some_number, as: :number_with_delimiter
end



```



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/polypressure/formant/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
