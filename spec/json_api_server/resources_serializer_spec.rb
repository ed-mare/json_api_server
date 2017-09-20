require 'rails_helper' # need model to test.
require 'ostruct'

describe JsonApiServer::ResourcesSerializer do
  let(:objects) { Topic.all }
  let(:request) do
    FakeRequest.new({
                      page: { number: 1, limit: 4 },
                      sort: '-character',
                      filter: { id: '>1' },
                      include: 'comments',
                      fields: { comments: 'title,comment', users: 'email,first_name,last_name' }
                    }, '/topics')
  end
  let(:includes) { %w[comments tags author] }
  let(:fields) { { 'articles' => %w[title body], 'people' => ['name'] } }
  let(:filter) { JsonApiServer::Filter.new(request, Topic, %i[character location published]) }
  let(:paginator) { JsonApiServer::Paginator.new(2, 20, 10, 'http://foo') }

  describe '#initialize' do
    it 'sets objects instance variable to objects if serializer is not set' do
      s = JsonApiServer::ResourcesSerializer.new(objects)
      expect(JsonApiServer::ResourcesSerializer.objects_serializer).to eq(nil)
      expect(s.instance_variable_get(:@objects)).to be(objects)
    end

    it 'sets filter option' do
      s = JsonApiServer::ResourcesSerializer.new(objects, filter: filter)
      expect(s.filter).to be(filter)
    end
    it 'sets paginator option' do
      s = JsonApiServer::ResourcesSerializer.new(objects, paginator: paginator)
      expect(s.paginator).to be(paginator)
    end
    it 'sets include option' do
      s = JsonApiServer::ResourcesSerializer.new(objects, includes: includes)
      expect(s.includes).to be(includes)
    end
    it 'sets fields option' do
      s = JsonApiServer::ResourcesSerializer.new(objects, fields: fields)
      expect(s.fields).to be(fields)
    end
    it 'sets as_json_options option' do
      s = JsonApiServer::ResourcesSerializer.new(objects, as_json_options: { include: [:data] })
      expect(s.as_json_options).to eq(include: [:data])
    end
    it 'does not require options' do
      s = JsonApiServer::ResourcesSerializer.new(objects)
      expect(s.filter).to eq(nil)
      expect(s.paginator).to eq(nil)
      expect(s.includes).to eq(nil)
      expect(s.fields).to eq(nil)
    end
  end

  describe '.from_builder' do
    let(:builder) do
      JsonApiServer::Builder.new(request, Topic.all)
                            .add_pagination(default_per_page: 2, max_per_page: 5)
                            .add_filter([{ id: { type: 'Integer' } }])
                            .add_sort(permitted: %i[character location published],
                                      default: { id: :desc })
                            .add_include(['comments'])
                            .add_fields
    end

    it 'returns an instance of ResourceSerializer with options set' do
      s = JsonApiServer::ResourcesSerializer.from_builder(builder)
      expect(s).to be_an_instance_of(JsonApiServer::ResourcesSerializer)
      expect(s.paginator).to_not eq(nil)
      expect(s.filter).to_not eq(nil)
      expect(s.includes).to_not eq(nil)
      expect(s.fields).to_not eq(nil)
    end
  end
end
