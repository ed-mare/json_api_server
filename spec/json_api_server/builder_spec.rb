require 'rails_helper' # need model to test.

describe JsonApiServer::Builder do
  let(:request_empty) { FakeRequest.new({ 'include' => '', 'sort' => '-character' }, '/topics') }
  let(:request_1) { FakeRequest.new({ 'include' => 'publisher', 'sort' => '-character', 'page' => { 'number' => 1, 'limit' => 3 } }, '/topics') }
  let(:request_2) { FakeRequest.new({ 'include' => 'comments', 'sort' => 'location', 'filter' => { 'quote' => 'swear' } }, '/topics') }
  let(:request_3) { FakeRequest.new({ 'include' => 'comments,publisher', 'filter' => { 'book' => '*harry*' } }, '/topics') }
  let(:request_4) { FakeRequest.new({}, '/topics') }
  let(:request_5) { FakeRequest.new({ fields: { comments: 'title,comment', users: 'email,first_name,last_name' } }, '/topics') }
  let(:pagination_options) { { default_per_page: 2, max_per_page: 5 } }
  let(:sort_options) do
    {
      permitted: %i[character location published],
      default: { id: :desc }
    }
  end
  let(:filter_permitted) do
    [
      { id: { type: 'Integer' } },
      { published: { type: 'Date' } },
      { book: { wildcard: :both } }
    ]
  end
  let(:include_permitted) { ['publisher' => -> { includes(:publisher) }] }

  before(:all) do
    @user = User.create(email: 'jane@doe.com')
    @publisher1 = Publisher.create(name: 'Pub1')
    @publisher2 = Publisher.create(name: 'Pub2')
    @topic1 = Topic.create(character: 'Kreacher',
                           location: 'Dervish & Banges',
                           quote: 'Harry, suffering like this proves you are still a man! This pain is part of being human … the fact that you can feel pain like this is your greatest strength.',
                           book: 'Harry Potter and the Half-Blood Prince',
                           published: Date.new(2005, 7, 16),
                           publisher: @publisher1,
                           author: 'J.K. Rowling')
    @topic2 = Topic.create(character: 'Hedwig',
                           location: 'Ministry of Magic',
                           quote: 'To the well-organized mind, death is but the next great adventure.',
                           book: 'Harry Potter and the Order of the Phoenix',
                           published: Date.new(2003, 6, 21),
                           publisher: @publisher2,
                           author: 'J.K. Rowling')
    @topic3 = Topic.create(character: 'Ernie Macmillan',
                           location: 'The Leaky Cauldron',
                           quote: 'Dark and difficult times lie ahead. Soon we must all face the choice between what is right and what is easy.',
                           book: 'Harry Potter and the Prisoner of Azkaban',
                           published: Date.new(1999, 7, 8),
                           publisher: @publisher1,
                           author: 'J.K. Rowling')
    @topic4 = Topic.create(character: 'Frank Longbottom',
                           location: 'Ministry of Magic',
                           quote: 'Platform 9 3/4',
                           book: 'Harry Potter and the Goblet of Fire',
                           published: Date.new(2000, 7, 8),
                           publisher: @publisher2,
                           author: 'J.K. Rowling')
    @topic5 = Topic.create(character: 'Florean Fortescue',
                           location: 'Azkaban',
                           quote: 'It takes a great deal of bravery to stand up to our enemies, but just as much to stand up to our friends.',
                           book: 'Harry Potter and the Order of the Phoenix',
                           published: Date.new(2003, 6, 21),
                           publisher: @publisher1,
                           author: 'J.K. Rowling')
    @topic6 = Topic.create(character: 'Harry Potter',
                           location: 'Hogwards',
                           quote: 'I solemnly swear I am up to no good.',
                           book: 'Harry Potter and the Chamber of Secrets',
                           published: Date.new(1998, 7, 2),
                           publisher: @publisher2,
                           author: 'J.K. Rowling')
    @comment1 = Comment.create(author: @user, topic: @topic2, title: 'Comment about topic 2')
    @comment2 = Comment.create(author: @user, topic: @topic1, title: 'Comment about topic 1')
  end

  after(:all) { delete_all_records }

  describe '#pagination' do
    let(:builder) do
      JsonApiServer::Builder.new(request_1, Topic.order(id: :desc))
                            .add_pagination(pagination_options)
    end
    let(:builder_no_pagination) do
      JsonApiServer::Builder.new(request_1, Topic.order(id: :desc))
    end
    it 'includes pagination when added' do
      expect(builder.pagination).to be_a(JsonApiServer::Pagination)
      expect(builder.pagination.per_page).to eq(3)
      expect(builder.pagination.page).to eq(1)
    end

    it 'includes pagination in :relation output' do
      query = builder.relation.to_sql
      expect(query).to match(/LIMIT 3/)
      expect(query).to match(/OFFSET 0/)
    end

    it "doesn't remove existing query conditions" do
      query = builder.relation.to_sql
      expect(query).to match(/DESC/)
    end

    it "doesn't raise errors when pagination is not included" do
      expect { builder_no_pagination.relation }.not_to raise_error
    end
  end

  describe '#sort' do
    let(:builder) do
      JsonApiServer::Builder.new(request_1, Topic.all)
                            .add_sort(sort_options)
    end

    it 'includes sort when added' do
      expect(builder.sort).to be_a(JsonApiServer::Sort)
      expect(builder.sort.sort_params).to eq([{ 'character' => :desc }])
    end

    it 'includes sort in :relation output' do
      query = builder.relation.to_sql
      expect(query).to match(/character.+ DESC/i)
    end

    it 'raises an exception on invalid sort params' do
      req = FakeRequest.new({ 'sort' => 'foobar' }, '/topics')
      builder = JsonApiServer::Builder.new(req, Topic.all)
                                      .add_sort(sort_options)
      expect { builder.relation }.to raise_exception(JsonApiServer::BadRequest, /Sort param 'foobar' is not supported/)
    end
  end

  describe '#include' do
    # {"include"=>"publisher"..., }
    let(:builder) do
      JsonApiServer::Builder.new(request_1, Topic.all)
                            .add_include(include_permitted)
    end

    it 'includes include when added' do
      expect(builder.include).to be_a(JsonApiServer::Include)
      expect(builder.include.include_params).to eq(['publisher'])
    end

    it 'includes include in :relation output' do
      topic = builder.relation.first
      expect(topic).to have_loaded_association(:publisher)
    end

    it 'raises an exception on invalid include params' do
      builder = JsonApiServer::Builder.new(request_3, Topic.all)
                                      .add_include(include_permitted)
      expect { builder.relation }.to raise_exception(JsonApiServer::BadRequest, /Inclusion param 'comments' is not supported/)
    end
  end

  describe '#filter' do
    # "filter" => { "book" => "harry" }
    let(:builder) do
      JsonApiServer::Builder.new(request_3, Topic.all)
                            .add_filter(filter_permitted)
    end

    it 'includes filter when added' do
      expect(builder.filter).to be_a(JsonApiServer::Filter)
      expect(builder.filter.filter_params).to eq('book' => '*harry*')
    end

    it 'includes filter in :relation output' do
      query = builder.relation.to_sql
      # SELECT "topics".* FROM "topics" WHERE (book LIKE '%harry*%')
      expect(query).to match(/WHERE.+book.+LIKE.+/i)
    end

    it 'raises an exception on invalid filter params' do
      # "filter" => { "quote" => "swear" }
      builder = JsonApiServer::Builder.new(request_2, Topic.all)
                                      .add_filter(filter_permitted)
      expect { builder.relation }.to raise_exception(JsonApiServer::BadRequest, /Filter param 'quote' is not supported/)
    end
  end

  describe '#relation' do
    let(:builder) do
      req = FakeRequest.new({
                              'include' => 'publisher',
                              'filter' => { 'book' => '*harry' },
                              'sort' => '-character'
                            }, '/topics')
      JsonApiServer::Builder.new(req, Topic.order(id: :desc))
                            .add_pagination(pagination_options)
                            .add_sort(sort_options)
                            .add_include(include_permitted)
                            .add_filter(filter_permitted)
    end

    it 'includes all Relation conditions specified' do
      query = builder.relation.to_sql
      topics = builder.relation
      # puts query
      expect(query).to match(/LIMIT 2/i)
      expect(query).to match(/OFFSET 0/i)
      expect(query).to match(/"character" DESC/i)
      expect(query).to match(/"book" LIKE '%harry%'/i)
      expect(topics.first).to have_loaded_association(:publisher)
    end
  end

  describe '#paginator' do
    let(:builder) do
      JsonApiServer::Builder.new(request_1, Topic.order(id: :desc))
                            .add_pagination(pagination_options)
    end
    let(:builder_no_pagination) do
      JsonApiServer::Builder.new(request_1, Topic.order(id: :desc))
    end

    it 'is an instance of Paginator based on the Pagination object created with #add_pagination' do
      expect(builder.paginator.first).to eq(
        'http://localhost:3001/topics?include=publisher&page%5Blimit%5D=3&page%5Bnumber%5D=1&sort=-character'
      )
      expect(builder.paginator.last).to eq(
        'http://localhost:3001/topics?include=publisher&page%5Blimit%5D=3&page%5Bnumber%5D=2&sort=-character'
      )
    end

    it 'is nil if #add_pagination is never called' do
      expect(builder_no_pagination.paginator).to eq(nil)
    end
  end

  describe '#includes' do
    let(:builder) do
      JsonApiServer::Builder.new(request_1, Topic.all)
                            .add_include(include_permitted)
    end
    let(:builder_no_add_include) do
      JsonApiServer::Builder.new(request_1, Topic.all)
    end
    let(:builder_no_includes_requested) do
      JsonApiServer::Builder.new(request_4, Topic.all)
                            .add_include(include_permitted)
    end

    it 'is an array of whitelisted relationship names when #add_include was called' do
      expect(builder.includes).to eq(['publisher'])
    end

    it 'is empty array when no includes are requested' do
      expect(builder_no_includes_requested.includes).to eq([])
    end

    it 'is nil when #add_include is never called' do
      expect(builder_no_add_include.includes).to eq(nil)
    end
  end

  describe '#sparse_fields' do
    let(:builder) { JsonApiServer::Builder.new(request_5, Topic.all).add_fields }
    let(:builder_no_add_fields) { JsonApiServer::Builder.new(request_5, Topic.all) }
    let(:builder_no_fields_requested) { JsonApiServer::Builder.new(request_4, Topic.all).add_fields }

    it 'is a hash when #add_fields is called and sparse fields are requested' do
      expect(builder.sparse_fields).to eq(
        'comments' => %w[title comment], 'users' => %w[email first_name last_name]
      )
    end

    it 'is nil when #add_fields is called and no sparse fields are requested' do
      expect(builder_no_fields_requested.sparse_fields).to eq(nil)
    end

    it 'is nil when #add_fields is never called' do
      expect(builder_no_add_fields.sparse_fields).to eq(nil)
    end
  end
end
