require "formant/version"

require 'active_model'
require 'active_support/all'
require 'action_view'
require 'phony_rails'


module Formant
  include ActionView::Helpers::NumberHelper

  #
  # Base class for Form objects.
  #
  # See https://www.reinteractive.net/posts/158-form-objects-in-rails
  # (among others) for more info on form objects for more details.
  #
  # This is a simplified implementation of form objects that focuses
  # on collecting input in a PORO, specifying any special parsing
  # and transformation on fields upon input (i.e., before validation),
  # and special formatting/transformation on fields for display/output
  # and redisplay of forms.
  #
  class FormObject

    include ActiveModel::Model
    include ActiveModel::Validations::Callbacks

    before_validation :parse_fields!

    class << self
      attr_accessor :parse_fields, :format_fields
    end

    #
    # Directive to add a parse rule for the specified attribute.
    # Parse rules let you apply any special parsing/transformation
    # logic on the form's attributes upon input. The parsing rules
    # are applied automatically prior to validation.
    #
    # Usage example:
    #
    # class MyForm < FormObject
    #   ...
    #   parse :appointment_time, as: :datetime
    #   parse :phone, as: :phone_number
    #   parse :price, as: :currency
    #   parse :email, to: :strip_whitespace
    #   ...
    # end
    #
    # The above example specifies that the appointment_time attribute
    # should be parsed with the parse_datetime method (which converts
    # the datetime string into an ActiveSupport::TimeWithZone object),
    # and that the # phone attribute should be parsed with the
    # parse_phone_number method (which normalizes the phone number into
    # a standard format).
    #
    def self.parse(field_name, options={})
      self.parse_fields ||= []
      parse_type = options[:as] || options[:to]
      raise "no parse type provided" if parse_type.blank?
      self.parse_fields << [ field_name, "parse_#{parse_type}", options ]
    end

    #
    # Directive to add a reformat rule for the specified attribute.
    # These let you apply any special formatting/normalization
    # logic on the form's attributes upon output. Typically you want
    # to do this when you have to redisplay a form.
    #
    # The format rules are triggered when the FormObject#reformatted!
    # method is invoked, which modifies the attribute in place.
    #
    # Usage example:
    #
    # class MyForm < FormObject
    #   ...
    #   reformat :appointment_time, as: :datetime, format: :day_date_time
    #   reformat :phone, as: :phone_number, country_code: 'US'
    #   ...
    # end
    #
    # The above example specifies that the appointment_time attribute
    # should be reformatted with the format_datetime method (using the format
    # specified in the locale file with the :day_date_time key), and that
    # the phone attribute should be parsed with the parse_phone_number
    # method, and a fixed country_code of 'US'
    #
    def self.reformat(field_name, options={})
      self.format_fields ||= []
      self.format_fields << [ field_name, "format_#{options[:as]}", options ]
    end

    #
    # Triger any formatting rules specified with the reformat directive.
    # The attributes are reformatted and mutated in place.
    #
    # Returns an instance of the form object.
    #
    def reformatted!
      self.class.format_fields.each do |field_name, format_method, options|
        formatted_value = send(format_method, get_field(field_name), options)
        set_field(field_name, formatted_value)
      end
      self
    end

    #
    # Return all the attributes as a params hash.
    #
    def to_params
      attrs = Hash.new
      instance_variables.each do |ivar|
        name = ivar[1..-1]
        attrs[name.to_sym] = instance_variable_get(ivar) if respond_to? "#{name}="
      end
      attrs
    end


    private

    def parse_datetime(field_value, options={})
      Time.zone.parse(field_value || '')
    end

    def parse_phone_number(field_value, options={})
      cc = options[:country_code] || 'US'
      PhonyRails.normalize_number(field_value, country_code: cc)
    end

    def parse_currency(field_value, options={})
      if field_value.is_a?(String)
        field_value.gsub(/[^0-9\.]+/, '').to_d
      elsif field_value.is_a?(Numeric)
        field_value.to_d
      else
        field_value
      end
    end

    def parse_strip_whitespace(field_value, options={})
      return field_value unless field_value.is_a?(String)
      options[:squish] ? field_value.squish : field_value.strip if field_value
    end

    def format_datetime(field_value, options={})
      I18n.l(field_value, options).squish if field_value
    end

    def format_phone_number(field_value, options={})
      field_value.phony_formatted(options) if field_value
    end

    def format_currency(field_value, options={})
      ActionView::Base.new.number_to_currency(field_value, options) if field_value
    end

    def format_number_with_delimiter(field_value, options={})
      ActionView::Base.new.number_with_delimiter(field_value, options)
    end

    def parse_fields!
      self.class.parse_fields.each do |field_name, parse_method, options|
        parsed_value = send(parse_method, get_field(field_name), options)
        set_field(field_name, parsed_value)
      end
      true
    end

    def get_field(field_name)
      instance_variable_get(as_sym(field_name))
    end

    def set_field(field_name, value)
      instance_variable_set(as_sym(field_name), value)
    end

    def as_sym(field_name)
      field = "@#{field_name}".to_sym
    end

  end

end
