require 'rails_helper' # testing model

describe JsonApiServer::Sort do
  let(:request_empty) { FakeRequest.new('sort' => '') }
  let(:request_one) { FakeRequest.new('sort' => '-character') }
  let(:request_multi) { FakeRequest.new('sort' => '-character,id') }
  let(:request_no_match) { FakeRequest.new('sort' => '-notsupported') }
  let(:request_column_alias) { FakeRequest.new('sort' => 'created') }
  let(:request_no_sort) { FakeRequest.new({}) }
  let(:options_multi) do
    {
      permitted: [:id, :character, :location, :published, { created: { col_name: :created_at } }],
      default: { id: :desc }
    }
  end
  let(:options_no_default) do
    {
      permitted: %i[character location published]
    }
  end
  let(:sort_empty) { JsonApiServer::Sort.new(request_empty, Topic, options_multi) }
  let(:sort_one) { JsonApiServer::Sort.new(request_one, Topic, options_multi) }
  let(:sort_multi) { JsonApiServer::Sort.new(request_multi, Topic, options_multi) }
  let(:sort_none) { JsonApiServer::Sort.new(request_no_sort, Topic, options_multi) }
  let(:sort_no_default) { JsonApiServer::Sort.new(request_no_sort, Topic, options_no_default) }
  let(:sort_no_opts) { JsonApiServer::Sort.new(request_no_sort, Topic, {}) }
  let(:sort_column_alias) { JsonApiServer::Sort.new(request_column_alias, Topic, options_multi) }

  describe '#initialize' do
    it 'assigns request attr' do
      expect(sort_one.request).to be(request_one)
    end

    it 'assigns model attr' do
      expect(sort_one.model).to be(Topic)
    end

    it 'assigns params attr to request.query_parameters' do
      expect(sort_one.params).to be(request_one.query_parameters)
    end

    it 'assigns options attr' do
      expect(sort_one.options).to be(options_multi)
    end
  end

  describe '#sort' do
    it 'are the sort params' do
      expect(sort_empty.sort).to eq('')
      expect(sort_none.sort).to eq('')
      expect(sort_one.sort).to eq('-character')
      expect(sort_multi.sort).to eq('-character,id')
    end
  end

  describe '#sort_params' do
    it 'are the sort params' do
      expect(sort_empty.sort).to eq('')
      expect(sort_none.sort).to eq('')
      expect(sort_one.sort_params).to eq([{ 'character' => :desc }])
      expect(sort_multi.sort_params).to eq([{ 'character' => :desc }, { 'id' => :asc }])
    end
  end

  describe '#configs' do
    it 'is an instance of JsonApiServer::SortConfigs' do
      expect(sort_one.configs).to be_an_instance_of(JsonApiServer::SortConfigs)
    end
  end

  describe '#query' do
    it 'is an alias to #relation' do
      expect(JsonApiServer::Sort.instance_method(:query)).to eq(
        JsonApiServer::Sort.instance_method(:relation)
      )
    end
  end

  describe '#relation' do
    it 'raises an exception when requested sort attributes are not in the permitted list' do
      sort = JsonApiServer::Sort.new(request_no_match, Topic, options_multi)
      expect { sort.relation }.to raise_error(JsonApiServer::BadRequest,
                                              /Sort param 'notsupported' is not supported/)
    end

    it 'appends ORDER BY to the ActiveRecord::Relation' do
      expect(sort_one.relation.to_sql).to match(/ORDER BY/i)
    end

    it 'treats dash (-<attribute_name>) to mean DESC' do
      expect(sort_one.relation.to_sql).to match(/ORDER BY.+character.? DESC/i)
    end

    it 'appends multiple sort params' do
      # "SELECT \"topics\".* FROM \"topics\" ORDER BY \"topics\".\"character\" DESC, \"topics\".\"id\" ASC"
      expect(sort_multi.relation.to_sql).to match(/ORDER BY.+character.? DESC,.+id.? ASC/i)
    end

    it 'uses default sort when no sort params and default sort is specified' do
      # "SELECT \"topics\".* FROM \"topics\" ORDER BY \"topics\".\"id\" DESC"
      expect(sort_none.relation.to_sql).to match(/ORDER BY.+id.? DESC/i)
    end

    it "doesn't sort when no sort params and default sort isn't specified" do
      expect(sort_no_default.relation).to eq(nil)
    end

    it "doesn't sort when there are no sort configs" do
      expect(sort_no_opts.relation).to eq(nil)
    end

    it 'uses column alias when one is specified in config' do
      expect(sort_column_alias.relation.to_sql).to match(/ORDER BY.+created_at.? ASC/i)
    end
  end
end
