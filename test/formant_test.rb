require 'test_helper'

class FormantTest < ActiveSupport::TestCase

  test "initialize form object from hash" do
    form = UserForm.new({
      first_name: 'John',
      last_name: 'Doe',
      email: 'john@test.com',
      phone: '312-555-1212',
      meeting_datetime: 'Aug 26, 2015 7:00 pm'
    })

    assert_equal 'John', form.first_name
    assert_equal 'Doe', form.last_name
    assert_equal 'john@test.com', form.email
    assert_equal '312-555-1212', form.phone
    assert_equal 'Aug 26, 2015 7:00 pm', form.meeting_datetime
  end

  test "validation succeeds with valid attributes" do
    form = UserForm.new({
      first_name: 'John',
      last_name: 'Doe',
      email: 'john@test.com',
      phone: '312-555-1212',
      meeting_datetime: 'Aug 26, 2015 7:00 pm'
    })

    assert form.valid?
  end

  test "validation fails with invalid attributes" do
    form = UserForm.new({})

    refute form.valid?
    assert form.invalid?
  end

  test "parses datetime" do
    form = UserForm.new({
      first_name: 'John',
      last_name: 'Doe',
      email: 'john@test.com',
      phone: '312-555-1212',
      meeting_datetime: 'Aug 26, 2015 7:18 pm'
    })

    form.validate

    assert_equal Time.zone.local(2015, 8, 26, 19, 18), form.meeting_datetime
  end

  test "normalizes phone" do
    form = UserForm.new({
      first_name: 'John',
      last_name: 'Doe',
      email: 'john@test.com',
      phone: '312-555-1212',
      meeting_datetime: 'Aug 26, 2015 7:18 pm'
    })

    form.validate

    assert_equal '+13125551212', form.phone
  end

  test "parses currency when field is a string" do
    form = UserForm.new({
      first_name: 'John',
      last_name: 'Doe',
      email: 'john@test.com',
      phone: '312-555-1212',
      meeting_datetime: 'Aug 26, 2015 7:18 pm',
      price: '$5,258.31'
    })

    form.validate

    assert_equal BigDecimal.new(5258.31, 6), form.price
  end

  test "parses currency when field is a number" do
    form = UserForm.new({
      first_name: 'John',
      last_name: 'Doe',
      email: 'john@test.com',
      phone: '312-555-1212',
      meeting_datetime: 'Aug 26, 2015 7:18 pm',
      price: 5258.31
    })

    form.validate

    assert_equal BigDecimal.new(5258.31, 6), form.price
  end

  test "strips leading, internal, and trailing whitespace" do
    form = UserForm.new({
      first_name: 'Joe   Bob   ',
      last_name: '  Doe  ',
      email: '   john@test.com',
      phone: '312-555-1212',
      meeting_datetime: 'Aug 26, 2015 7:18 pm',
      price: '$5,258.31'
    })

    form.validate

    assert_equal 'Joe Bob', form.first_name
    assert_equal 'Doe', form.last_name
    assert_equal 'john@test.com', form.email
  end


  test "reformats datetime" do
    form = UserForm.new({
      first_name: 'John',
      last_name: 'Doe',
      email: 'john@test.com',
      phone: '312-555-1212',
      meeting_datetime: 'Aug 26, 2015 7:18 pm'
    })

    form.validate
    form.reformatted!

    assert_equal 'Wed, Aug 26, 7:18 PM', form.meeting_datetime
  end


  test "reformats phone" do
    form = UserForm.new({
      first_name: 'John',
      last_name: 'Doe',
      email: 'john@test.com',
      phone: '312-555-1212',
      meeting_datetime: 'Aug 26, 2015 7:18 pm'
    })

    form.validate
    form.reformatted!

    assert_equal '(312) 555-1212', form.phone
  end

  test "reformats currency" do
    form = UserForm.new({
      first_name: 'John',
      last_name: 'Doe',
      email: 'john@test.com',
      phone: '312-555-1212',
      meeting_datetime: 'Aug 26, 2015 7:18 pm',
      price: '$5,258.31'
    })

    form.validate
    form.reformatted!

    assert_equal '$5,258.31', form.price
  end

  test "reformats number with delimiter" do
    form = UserForm.new({
      first_name: 'John',
      last_name: 'Doe',
      email: 'john@test.com',
      phone: '312-555-1212',
      meeting_datetime: 'Aug 26, 2015 7:18 pm',
      price: '$5,258.31',
      some_big_number: '12345678.05',
      some_other_big_number: '12345678.05'
    })

    form.validate
    form.reformatted!

    assert_equal '12,345,678.05', form.some_big_number
    assert_equal '12 345 678,05', form.some_other_big_number
  end


  test "to_params returns a hash of all the attributes" do
    attrs = {
      first_name: 'John',
      last_name: 'Doe',
      email: 'john@test.com',
      phone: '312-555-1212',
      meeting_datetime: 'Aug 26, 2015 7:18 pm'
    }

    form = UserForm.new(attrs)

    assert_equal attrs, form.to_params
  end

  test "a callback can be specified with before_validate" do
    form = UserForm.new({
      first_name: 'John',
      last_name: 'Doe',
      email: 'john@test.com',
      phone: '312-555-1212',
      meeting_datetime: 'Aug 26, 2015 7:18 pm'
    })

    form.validate

    assert form.pre_validation_callback_invoked?
  end

  test "a callback can be specified with after_validate" do
    form = UserForm.new({
      first_name: 'John',
      last_name: 'Doe',
      email: 'john@test.com',
      phone: '312-555-1212',
      meeting_datetime: 'Aug 26, 2015 7:18 pm'
    })

    form.validate

    assert form.post_validation_callback_invoked?
  end


end

class UserForm < Formant::FormObject

  attr_accessor(
    :first_name,
    :last_name,
    :email,
    :phone,
    :meeting_datetime,
    :price,
    :some_big_number,
    :some_other_big_number
  )

  before_validation :do_stuff_before_validation
  after_validation  :do_stuff_after_validation

  parse :phone, as: :phone_number
  parse :meeting_datetime, as: :datetime
  parse :price, as: :currency
  parse :first_name, to: :strip_whitespace, squish: true
  parse :last_name, to: :strip_whitespace
  parse :email, to: :strip_whitespace

  reformat :meeting_datetime, as: :datetime, format: :day_date_time, locale: :en
  reformat :phone, as: :phone_number, country_code: 'US'
  reformat :price, as: :currency
  reformat :some_big_number, as: :number_with_delimiter
  reformat :some_other_big_number, as: :number_with_delimiter, delimiter: " ", separator: ","

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true
  validates :phone, presence: true
  validates :meeting_datetime, presence: true

  def do_stuff_before_validation
    @pre_validation_callback_invoked = true
  end

  def pre_validation_callback_invoked?
    @pre_validation_callback_invoked
  end

  def do_stuff_after_validation
    @post_validation_callback_invoked = true
  end

  def post_validation_callback_invoked?
    @post_validation_callback_invoked
  end

end
