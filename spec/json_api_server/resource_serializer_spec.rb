require 'spec_helper'
require 'ostruct'

class PersonSerializer < JsonApiServer::ResourceSerializer; end
class EpisodeSerializer < JsonApiServer::ResourceSerializer; end
class GoblinSerializer < JsonApiServer::ResourceSerializer
  resource_type 'creatures'
end

describe JsonApiServer::ResourceSerializer do
  let(:object) { OpenStruct.new(id: 2, title: 'hello') }
  let(:includes) { %w[comments tags author] }
  let(:fields) { { 'articles' => %w[title body], 'people' => ['name'] } }
  let(:instance_with_options) do
    JsonApiServer::ResourceSerializer.new(object,
                                          includes: includes, fields: fields)
  end
  let(:instance_without_options) do
    JsonApiServer::ResourceSerializer.new(object)
  end

  describe '.resource_type' do
    it 'sets class attribute :type' do
      expect(GoblinSerializer.type).to eq('creatures')
    end
  end

  describe '#initialize' do
    it 'sets object instance variable' do
      s = JsonApiServer::ResourceSerializer.new(object)
      expect(s.instance_variable_get(:@object)).to be(object)
    end
    it 'sets include option' do
      s = JsonApiServer::ResourceSerializer.new(object, includes: includes)
      expect(s.includes).to be(includes)
    end
    it 'sets fields option' do
      s = JsonApiServer::ResourceSerializer.new(object, fields: fields)
      expect(s.fields).to be(fields)
    end
    it 'sets as_json_options option' do
      s = JsonApiServer::ResourceSerializer.new(object, as_json_options: { include: [:data] })
      expect(s.as_json_options).to eq(include: [:data])
    end
  end

  describe '#relationship?' do
    it 'is true when relationship is in @includes' do
      expect(instance_with_options.send(:relationship?, 'tags')).to eq(true)
    end

    it 'is true when symbol is used' do
      expect(instance_with_options.send(:relationship?, :tags)).to eq(true)
    end

    it 'is false when not in includes' do
      expect(instance_with_options.send(:relationship?, 'idontexist')).to eq(false)
      expect(instance_without_options.send(:relationship?, 'idontexist')).to eq(false)
    end
  end

  describe '#relationship_data' do
    let(:episode_serializer) { EpisodeSerializer.new(object) }
    let(:person_serializer) { PersonSerializer.new(object) }
    let(:goblin_serializer) { GoblinSerializer.new(object) }
    let(:nil_object_serializer) { GoblinSerializer.new(nil) }

    it 'is {type: <type>, id: <object.id>} where type is guessed from serializer name' do
      expect(episode_serializer.relationship_data).to eq(
        'type' => 'episodes', 'id' => 2
      )
    end

    it 'correctly pluralizes type' do
      expect(person_serializer.relationship_data).to eq(
        'type' => 'people', 'id' => 2
      )
    end

    it 'uses value from #resource_type as type if set' do
      expect(goblin_serializer.relationship_data).to eq(
        'type' => 'creatures', 'id' => 2
      )
    end

    it "doesn't raise errors if object doesn't have id" do
      expect { nil_object_serializer.relationship_data }.not_to raise_error
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
      JsonApiServer::Builder.new(request, object)
                            .add_pagination(default_per_page: 2, max_per_page: 5)
                            .add_filter([{ id: { type: 'Integer' } }])
                            .add_sort(permitted: %i[character location published],
                                      default: { id: :desc })
                            .add_include(['comments'])
                            .add_fields
    end
    it 'returns an instance of ResourceSerializer with options set' do
      serializer = JsonApiServer::ResourceSerializer.from_builder(builder)
      expect(serializer).to be_an_instance_of(JsonApiServer::ResourceSerializer)
      expect(serializer.includes).to_not eq(nil)
      expect(serializer.fields).to_not eq(nil)
    end
  end

  describe '#inclusions? (protected)' do
    it 'is true when inclusions are requested' do
      expect(instance_with_options.send(:inclusions?)).to eq(true)
    end

    it 'is false when inclusions are not requested' do
      expect(instance_without_options.send(:inclusions?)).to eq(false)
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
