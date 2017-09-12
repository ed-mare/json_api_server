require 'spec_helper'

describe SimpleJsonApi::BaseSerializer do
  class MyClass
    include SimpleJsonApi::Serializer

    A_HASH = {
      datetime: DateTime.new(1993, 0o2, 24, 12, 0, 0, '+09:00'),
      date: Date.new(1993, 0o2, 24),
      xss: '<script>alert("owned!")</script> &lt;'
    }.freeze

    A_JSON = %q[{
      "datetime":"1993-02-24T12:00:00.000+09:00",
      "date":"1993-02-24",
      "xss":"\u003cscript\u003ealert(\"owned!\")\u003c\/script\u003e \u0026lt;"
      }].freeze

    def as_json
      A_HASH
    end
  end

  class MyClassDefaults
    include SimpleJsonApi::Serializer
  end

  let(:my_class_defaults) { MyClassDefaults.new }
  let(:my_class) { MyClass.new }

  describe '#as_json' do
    it 'defaults to empty hash' do
      expect(my_class_defaults.as_json).to eq({})
    end
    it 'should be overridden by class' do
      expect(my_class.as_json).to eq(MyClass::A_HASH)
    end
  end

  describe '#to_json' do
    it 'serializes as_json to json' do
      expect(my_class_defaults.to_json).to eq('{}')
      puts my_class.to_json
      puts MyClass::A_JSON
      expect(my_class.to_json).to be_same_json_as(MyClass::A_JSON)
    end
  end

  describe '#serializer_options' do
    let(:json) { my_class.to_json }

    it 'default to SimpleJsonApi.configuration.serializer_options' do
      expect(my_class.serializer_options).to eq(SimpleJsonApi.configuration.serializer_options)
    end

    it 'sets time: :xmlschema (converts DateTime to ISO8601)' do
      # optionally milliseconds
      expect(json).to match(/1993-02-24T12:00:00(\.000)?\+09:00/)
      expect(json).to match(/"1993-02-24"/)
    end

    it 'sets mode: :compat (convert symbols to "string" vs ":string"' do
      expect(json).to match(/"datetime"/)
      expect(json).to match(/"date"/)
      expect(json).to match(/"xss"/)
    end

    # \u003C and \u003E
    # U+003C < Less-than sign
    # U+003E > Greater-than sign

    it 'sets escape_mode: :xss_safe (escapes HTML and XML characters such as & and <)' do
      m = Regexp.escape('\u003cscript\u003ealert(\"owned!\")\u003c\/script\u003e \u0026lt;')
      expect(json).to match(/#{m}/)
    end

    it 'can be overridden with to_json\'s options param' do
      new_json = my_class.to_json(time_format: :unix)
      # {":datetime":{"^O":"DateTime","year":1993,"month":2,"day":24,"hour":12,"min":0,"sec":
      # {"^O":"Rational","numerator":0,"denominator":1},"offset":{"^O":"Rational","numerator":3,
      # "denominator":8},"start":2299161.0},":date":{"^O":"Date","year":1993,"month":2,"day":24,
      # "start":2299161.0},":xss":"<script>alert(\"owned!\")</script> &lt;"}
      expect(new_json).to match(/#{Regexp.escape('<script>')}/)
      expect(new_json).to match(/:datetime/)
      expect(new_json).to match(/"year":1993/)
    end
  end
end
