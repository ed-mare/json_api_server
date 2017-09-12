require 'rails_helper' # need model to test.

# ie., GET /comments?filter[post]=1,2&filter[author]=12  could use * as wildcard
describe SimpleJsonApi::Filter do
  let(:configs) do
    [
      { id: { type: 'Integer' } },
      { published: { type: 'Date' } },
      { published1: { col_name: :published, type: 'Date' } },
      :location,
      { book: { wildcard: :both } },
      { search: { builder: :model_query, method: :search } }
    ]
  end
  let(:configs_empty) { [] }
  let(:request_by_id) { FakeRequest.new(filter: { id: '1,2' }) }
  let(:request_invalid_attr) { FakeRequest.new(filter: { author: 'J.K Rowling' }) }
  let(:request_empty) { FakeRequest.new({}) }

  describe '#initialize' do
    let(:filter) { SimpleJsonApi::Filter.new(request_by_id, Topic, configs) }
    let(:filter_no_params) { SimpleJsonApi::Filter.new(request_empty, Topic, configs) }

    it 'assigns request attr' do
      expect(filter.request).to eq(request_by_id)
    end

    it 'assigns model attr' do
      expect(filter.model).to eq(Topic)
    end

    it 'assigns params attr to request.query_parameters' do
      expect(filter.params).to eq(request_by_id.query_parameters)
    end

    it 'assigns permitted to empty hash if not assigned' do
      expect(filter.permitted).to eq(configs)
    end
  end

  describe '#filter_params' do
    let(:filter) { SimpleJsonApi::Filter.new(request_by_id, Topic, configs) }
    let(:filter_no_params) { SimpleJsonApi::Filter.new(request_empty, Topic, configs) }

    it 'is the filter params if present' do
      expect(filter.filter_params).to eq('id' => '1,2')
    end
    it 'is an empty hash if none present' do
      expect(filter_no_params.filter_params).to eq({})
    end
  end

  describe '#meta_info' do
    let(:request) { FakeRequest.new(filter: { book: 'Harry Potter', id: '1,2', published: '' }) }

    it 'describes filters (for meta element)' do
      filter = SimpleJsonApi::Filter.new(request, Topic, configs)
      expect(filter.meta_info).to eq(filter: ['book: Harry Potter', 'id: 1,2'])
    end

    it 'removes filters with blank values' do
      req = FakeRequest.new(filter: { book: 'Harry Potter', id: '1,2', published: '', published1: '10/22/2011' })
      filter = SimpleJsonApi::Filter.new(req, Topic, configs)
      expect(filter.meta_info).to eq(filter: ['book: Harry Potter', 'id: 1,2', 'published1: 10/22/2011'])
    end
  end

  describe '#query' do
    it 'is an alias to #relation' do
      expect(SimpleJsonApi::Filter.instance_method(:query)).to eq(
        SimpleJsonApi::Filter.instance_method(:relation)
      )
    end
  end

  describe '#relation' do
    describe 'casts values to specified type in filter configs' do
      let(:configs) do
        [
          { id: { type: 'Integer' } },
          { published: { type: 'Date' } },
          :location,
          { created: { col_name: :created_at, type: 'DateTime' } }
        ]
      end
      let(:request_num) { FakeRequest.new(filter: { id: '1' }) }
      let(:request_string) { FakeRequest.new(filter: { location: '1' }) }
      let(:request_date) { FakeRequest.new(filter: { published: '2017-09-04' }) }
      let(:request_bad_date) { FakeRequest.new(filter: { published: '2017' }) }
      let(:request_datetime) { FakeRequest.new(filter: { created: '2017-09-04T18:44:50+03:00' }) }
      let(:request_bad_datetime) { FakeRequest.new(filter: { created: '2017+03:00' }) }

      it '- ex: converts to an integer' do
        filter = SimpleJsonApi::Filter.new(request_num, Topic, configs)
        expect(filter.relation.to_sql).to match(/= 1/)
      end

      it '- ex: converts to a string' do
        filter = SimpleJsonApi::Filter.new(request_string, Topic, configs)
        expect(filter.relation.to_sql).to match(/= '1'/)
      end

      it '- ex: converts to a Date' do
        filter = SimpleJsonApi::Filter.new(request_date, Topic, configs)
        expect(filter.relation.to_sql).to match(/'2017-09-04'/)
      end

      it '- ex: converts unrecongizable Date to nil' do
        filter = SimpleJsonApi::Filter.new(request_bad_date, Topic, configs)
        expect(filter.relation.to_sql).to match(/\"topics\".\"published\" = NULL/)
      end

      it '- ex: converts to a DateTime (calls :in_time_zone)' do
        filter = SimpleJsonApi::Filter.new(request_datetime, Topic, configs)
        expect(filter.relation.to_sql).to match(/\"topics\".\"created_at\" = '2017-09-04 15:44:50'/)
      end

      it '- ex: converts unrecongizable DateTime to nil' do
        filter = SimpleJsonApi::Filter.new(request_bad_datetime, Topic, configs)
        expect(filter.relation.to_sql).to match(/\"topics\".\"created_at\" = NULL/)
      end

      it '- ex: converts multiple values (comma separated) to type' do
        request = FakeRequest.new(filter: { id: '1,2,3' })
        filter = SimpleJsonApi::Filter.new(request, Topic, configs)
        expect(filter.relation.to_sql).to match(/IN \(1,2,3\)/)
      end

      it '- ex: converts to a Float' do
        pending('add real column to table')
        raise
      end

      it 'ex: converts to a BigDecimal' do
        pending('add real column to table')
        raise
      end
    end

    describe 'wildcards' do
      let(:request) { FakeRequest.new(filter: { book: '*Harry Potter' }) }
      let(:request_wo_wildcard) { FakeRequest.new(filter: { book: 'Harry Potter' }) }
      let(:config_left) { [{ book: { wildcard: :left } }] }
      let(:config_right) { [{ book: { wildcard: :right } }] }
      let(:config_both) { [{ book: { wildcard: :both } }] }

      it 'the left when configured for :left and param begins with *' do
        filter = SimpleJsonApi::Filter.new(request, Topic, config_left)
        expect(filter.relation.to_sql).to match(/\("topics"."book" LIKE '%Harry Potter'\)/)
      end

      it 'the right when configured for :right and param begins with *' do
        filter = SimpleJsonApi::Filter.new(request, Topic, config_right)
        expect(filter.relation.to_sql).to match(/\("topics"."book" LIKE 'Harry Potter%'\)/)
      end

      it 'both sides when configured for :both and param begins with *' do
        filter = SimpleJsonApi::Filter.new(request, Topic, config_both)
        expect(filter.relation.to_sql).to match(/\("topics"."book" LIKE '%Harry Potter%'\)/)
      end

      it 'only when param begin with *' do
        filter = SimpleJsonApi::Filter.new(request_wo_wildcard, Topic, config_both)
        expect(filter.relation.to_sql).to match(/\("topics"."book" = 'Harry Potter'\)/)
      end
    end

    describe 'creates an IN statement' do
      let(:configs) do
        [
          { id: { type: 'Integer' } },
          { published: { type: 'Date' } },
          :location,
          { created: { col_name: :created_at, type: 'DateTime' } }
        ]
      end
      let(:request_num) { FakeRequest.new(filter: { id: '1,2,3' }) }
      let(:request_string) { FakeRequest.new(filter: { location: 'Hogwarts, Leaky Cauldron' }) }
      let(:request_date) { FakeRequest.new(filter: { published: '2017-09-04, 2016-08-03' }) }
      let(:request_datetime) { FakeRequest.new(filter: { created: '2017-09-04T18:44:50+03:00, 2016-08-03T18:44:50+03:00' }) }

      it 'for comma separated integers' do
        filter = SimpleJsonApi::Filter.new(request_num, Topic, configs)
        re = Regexp.escape('"topics"."id" IN (1,2,3)')
        expect(filter.relation.to_sql).to match(/#{re}/)
      end

      it 'for comma separated strings' do
        filter = SimpleJsonApi::Filter.new(request_string, Topic, configs)
        re = Regexp.escape(%["topics"."location" IN ('Hogwarts','Leaky Cauldron')])
        expect(filter.relation.to_sql).to match(/#{re}/)
      end

      it 'for comma separated dates' do
        filter = SimpleJsonApi::Filter.new(request_date, Topic, configs)
        re = Regexp.escape(%["topics"."published" IN ('2017-09-04','2016-08-03')])
        expect(filter.relation.to_sql).to match(/#{re}/)
      end

      it 'for comma separated datetimes and casts to timezone if responds to :in_time_zone' do
        filter = SimpleJsonApi::Filter.new(request_datetime, Topic, configs)
        re = Regexp.escape(%["topics"."created_at" IN ('2017-09-04 15:44:50','2016-08-03 15:44:50')])
        expect(filter.relation.to_sql).to match(/#{re}/)
      end
    end

    describe 'accepts operators' do
      let(:configs) do
        [
          { id: { type: 'Integer' } },
          { published: { type: 'Date' } },
          { published1: { type: 'Date', col_name: :published } },
          :location
        ]
      end
      let(:request_eq) { FakeRequest.new(filter: { id: '1' }) }
      let(:request_neq) { FakeRequest.new(filter: { id: '!=1' }) }
      let(:request_gt) { FakeRequest.new(filter: { id: '>1' }) }
      let(:request_gte) { FakeRequest.new(filter: { id: '>=1' }) }
      let(:request_lt) { FakeRequest.new(filter: { published: '<2017-09-04' }) }
      let(:request_lte) { FakeRequest.new(filter: { published: '<=2017-09-04' }) }
      let(:request_op_unknown) { FakeRequest.new(filter: { published: '+2017-09-04' }) }
      let(:request_between) { FakeRequest.new(filter: { published: '>1998-01-01', published1: '<1999-12-31' }) }

      it '> and >=' do
        filter_gt = SimpleJsonApi::Filter.new(request_gt, Topic, configs)
        filter_gte = SimpleJsonApi::Filter.new(request_gte, Topic, configs)
        expect(filter_gt.relation.to_sql).to match(/"topics"."id" > 1/)
        expect(filter_gte.relation.to_sql).to match(/"topics"."id" >= 1/)
      end

      it '< and <=' do
        filter_lt = SimpleJsonApi::Filter.new(request_lt, Topic, configs)
        filter_lte = SimpleJsonApi::Filter.new(request_lte, Topic, configs)
        expect(filter_lt.relation.to_sql).to match(/"topics"."published" < '2017-09-04'/)
        expect(filter_lte.relation.to_sql).to match(/"topics"."published" <= '2017-09-04'/)
      end

      it '= and !=' do
        filter_eq = SimpleJsonApi::Filter.new(request_eq, Topic, configs)
        filter_neq = SimpleJsonApi::Filter.new(request_neq, Topic, configs)
        expect(filter_eq.relation.to_sql).to match(/"topics"."id" = 1/)
        expect(filter_neq.relation.to_sql).to match(/"topics"."id" != 1/)
      end

      it 'which can be combined' do
        filter = SimpleJsonApi::Filter.new(request_between, Topic, configs)
        re = Regexp.escape(%[("topics"."published" > '1998-01-01') AND ("topics"."published" < '1999-12-31')])
        expect(filter.relation.to_sql).to match(/#{re}/)
      end

      it 'and defaults to = if none of the above' do
        filter = SimpleJsonApi::Filter.new(request_op_unknown, Topic, configs)
        expect(filter.relation.to_sql).to match(/"topics"."published" = '2017-09-04'/)
      end
    end

    describe 'with builder: :model_query configs' do
      let(:request) { FakeRequest.new(filter: { search: 'abc' }) }
      let(:filter) { SimpleJsonApi::Filter.new(request, Topic, configs) }

      it 'calls a model\'s singleton method' do
        # See test_app/app/models/topic.rb
        expect(filter.relation.to_sql).to match(/character LIKE .+ OR book LIKE/)
      end
    end

    describe 'with custom builder configs' do
      # custom builder in test_app/config/initializers/simple_json_api.rb
      let(:configs) do
        [
          { book: { builder: :my_custom_builder } }
        ]
      end
      let(:request) { FakeRequest.new(filter: { book: 'abc' }) }
      let(:filter) { SimpleJsonApi::Filter.new(request, Topic, configs) }

      it 'uses a custom builder' do
        expect(filter.relation.to_sql).to match(/book LIKE '%abc%'/)
      end
    end

    it 'ANDs multiple queries' do
      request = FakeRequest.new(filter: { id: '>=1', published: '<2017-09-04', book: '*Harry Potter' })
      filter = SimpleJsonApi::Filter.new(request, Topic, configs)
      re = Regexp.escape(%[("topics"."id" >= 1) AND ("topics"."published" < '2017-09-04') AND ("topics"."book" LIKE '%Harry Potter%')])
      expect(filter.relation.to_sql).to match(/#{re}/)
    end

    it 'raises a SimpleJsonApi::BadRequest if an unpermitted attribute is requested' do
      filter = SimpleJsonApi::Filter.new(request_invalid_attr, Topic, configs)
      expect { filter.relation }.to raise_exception(SimpleJsonApi::BadRequest,
                                                    /Filter param 'author' is not supported/)
    end
  end
end
