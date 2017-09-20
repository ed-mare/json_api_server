require 'spec_helper'

describe JsonApiServer::BaseSerializer do
  class MyClass < JsonApiServer::BaseSerializer
    def as_json
      {
        datetime: DateTime.new(1993, 0o2, 24, 12, 0, 0, '+09:00'),
        date: Date.new(1993, 0o2, 24),
        xss: '<script>alert("owned!")</script>'
      }
    end
  end

  # borrowed from http://jsonapi.org/examples/
  class ExampleSerializer < JsonApiServer::BaseSerializer
    def links
      {
        'self' => 'http://example.com/articles?page[number]=3&page[size]=1',
        'first' => 'http://example.com/articles?page[number]=1&page[size]=1',
        'prev' => 'http://example.com/articles?page[number]=2&page[size]=1',
        'next' => 'http://example.com/articles?page[number]=4&page[size]=1',
        'last' => 'http://example.com/articles?page[number]=13&page[size]=1'
      }
    end

    def data
      [{
        'type' => 'articles',
        'id' => '1',
        'attributes' => {
          'title' => 'JSON API paints my bikeshed!',
          'body' => 'The shortest article. Ever.'
        },
        'relationships' => {
          'author' => {
            'data' => { 'id' => '42', 'type' => 'people' }
          }
        }
      }]
    end

    def relationship_data
      [{ type: 'articles', id: '1' }]
    end

    def included
      [
        {
          'type' => 'people',
          'id' => '42',
          'attributes' => {
            'name' => 'John',
            'age' => 80,
            'gender' => 'male'
          }
        }
      ]
    end

    def meta
      {
        'total-pages' => 13
      }
    end
  end

  let(:base) { JsonApiServer::BaseSerializer.new }
  let(:example) { ExampleSerializer.new }
  let(:my_class) { MyClass.new }

  describe '#links' do
    it 'is nil by default' do
      expect(base.links).to eq(nil)
    end
  end

  describe '#data' do
    it 'is nil by default' do
      expect(base.data).to eq(nil)
    end
  end

  describe '#included' do
    it 'is nil by default' do
      expect(base.included).to eq(nil)
    end
  end

  describe '#meta' do
    it 'is nil by default' do
      expect(base.meta).to eq(nil)
    end
  end

  describe '#as_json' do
    it 'includes jsonapi version, links, data, meta, and included sections by default' do
      expected = {
        'jsonapi' => { 'version' => '1.0' },
        'links' => nil,
        'data' => nil,
        'included' => nil,
        'meta' => nil
      }
      expect(base.as_json).to eq(expected)
    end

    it 'modifies output based on options' do
      expect(base.as_json(include: [:data])).to eq('data' => nil)
      expect(base.as_json(include: %i[data links meta])).to eq('data' => nil, 'links' => nil, 'meta' => nil)
    end

    it 'overrides options set in as_json_options' do
      base1 = JsonApiServer::BaseSerializer.new
      base1.as_json_options = { include: [:jsonapi] }
      expect(base.as_json(include: %i[links data])).to eq('links' => nil, 'data' => nil)
    end
  end

  describe '#as_json_options' do
    it 'is nil by default' do
      expect(example.as_json_options).to eq(nil)
    end

    it 'modifies as_json output when assigned' do
      example.as_json_options = { include: [:data] }
      expect(example.as_json).to eq('data' => example.data)
    end

    it 'modifies as_json output when {include: [:relationship_data]}' do
      example.as_json_options = { include: [:relationship_data] }
      expected = {
        'data' => [
          { 'type' => 'articles', 'id' => '1' }
        ]
      }
      # removes attributes from data elements.
      expect(example.as_json).to eq(expected)
    end
  end

  describe '#to_json' do
    it 'serializes as_json hash to json' do
      expected = dump_json(jsonapi: { version: '1.0' },
                           links: nil,
                           data: nil,
                           included: nil,
                           meta: nil)
      # puts expected
      expect(base.to_json).to eq(expected)
    end
  end

  describe 'serialization options' do
    it 'convert DateTime to ISO8601' do
      # optionally milliseconds - seems to change if oj_mimic_json is added to rails app.
      expect(my_class.to_json).to match(/1993-02-24T12:00:00(\.000)?\+09:00/)
    end

    it 'convert Date to ISO8601' do
      expect(my_class.to_json).to match(/"1993-02-24"/)
    end

    # \u003C and \u003E
    # U+003C < Less-than sign
    # U+003E > Greater-than sign

    it 'escapes HTML and XML characters such as & and <' do
      m = Regexp.escape('\\u003cscript\\u003ealert')
      expect(my_class.to_json).to match(/#{m}/)
      # puts load_json(my_class.to_json)
    end
  end

  describe '#base_url (protected)' do
    it 'points to Configuration#base_url' do
      expect(base.send(:base_url)).to eq(JsonApiServer.configuration.base_url)
    end
  end
end
