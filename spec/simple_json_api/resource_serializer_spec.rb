require 'spec_helper'
require 'ostruct'

describe SimpleJsonApi::ResourceSerializer do
  let(:object) { OpenStruct.new(id: 2, title: 'hello') }
  let(:includes) { %w[comments tags author] }
  let(:fields) { { 'articles' => %w[title body], 'people' => ['name'] } }
  let(:instance_with_options) do
    SimpleJsonApi::ResourceSerializer.new(object,
                                          includes: includes, fields: fields)
  end
  let(:instance_without_options) do
    SimpleJsonApi::ResourceSerializer.new(object)
  end

  describe '#initialize' do
    it 'sets object instance variable' do
      s = SimpleJsonApi::ResourceSerializer.new(object)
      expect(s.instance_variable_get(:@object)).to be(object)
    end
    it 'sets include option' do
      s = SimpleJsonApi::ResourceSerializer.new(object, includes: includes)
      expect(s.includes).to be(includes)
    end
    it 'sets fields option' do
      s = SimpleJsonApi::ResourceSerializer.new(object, fields: fields)
      expect(s.fields).to be(fields)
    end
    it 'sets as_json_options option' do
      s = SimpleJsonApi::ResourceSerializer.new(object, as_json_options: { include: [:data] })
      expect(s.as_json_options).to eq(include: [:data])
    end
  end

  describe '.from_builder' do
    let(:request) do
      FakeRequest.new({
                        page: { number: 1, limit: 4 },
                        sort: '-character',
                        filter: { id: '>1' },
                        include: 'comments',
                        fields: { comments: 'title,comment', users: 'email,first_name,last_name' }
                      }, '/topics')
    end
    let(:builder) do
      SimpleJsonApi::Builder.new(request, object)
                            .add_pagination(default_per_page: 2, max_per_page: 5)
                            .add_filter([{ id: { type: 'Integer' } }])
                            .add_sort(permitted: %i[character location published],
                                      default: { id: :desc })
                            .add_include(['comments'])
                            .add_fields
    end
    it 'returns an instance of ResourceSerializer with options set' do
      serializer = SimpleJsonApi::ResourceSerializer.from_builder(builder)
      expect(serializer).to be_an_instance_of(SimpleJsonApi::ResourceSerializer)
      expect(serializer.includes).to_not eq(nil)
      expect(serializer.fields).to_not eq(nil)
    end
  end

  describe '#attributes_builder_for (protected)' do
    it 'returns instance of AttributesBuilder when #fields is nil' do
      builder = instance_without_options.send(:attributes_builder_for, 'articles')
      expect(builder.fields).to eq(nil)
    end

    it 'returns instance of AttributesBuilder when #fields is populated' do
      builder = instance_with_options.send(:attributes_builder_for, 'articles')
      expect(builder.fields).to eq(%w[title body])
    end
  end
end
