require 'rails_helper' # need model to test.

describe SimpleJsonApi::Include do
  let(:request_empty) { FakeRequest.new('include' => '', 'sort' => '-character') }
  let(:request_0) { FakeRequest.new('sort' => '-character') }
  let(:request_1) { FakeRequest.new('include' => 'publisher', 'sort' => '-character') }
  let(:request_2) { FakeRequest.new('include' => 'comments', 'sort' => '-character') }
  let(:request_3) { FakeRequest.new('include' => 'comments.author,publisher', 'sort' => '-character') }

  describe '#initialize' do
    it 'assigns request attr' do
      i = SimpleJsonApi::Include.new(request_empty, Topic)
      expect(i.request).to eq(request_empty)
    end

    it 'assigns model attr' do
      i = SimpleJsonApi::Include.new(request_empty, Topic)
      expect(i.model).to eq(Topic)
    end

    it 'assigns params attr to request.query_parameters' do
      i = SimpleJsonApi::Include.new(request_1, Topic)
      expect(i.params).to eq(request_1.query_parameters)
    end

    it 'assigns permitted to empty hash if not assigned' do
      i = SimpleJsonApi::Include.new(request_empty, Topic)
      expect(i.permitted).to eq([])
    end

    it 'assigns permitted to empty hash if assigned a non-array' do
      i = SimpleJsonApi::Include.new(request_empty, Topic, 'foobar')
      expect(i.permitted).to eq([])
    end
  end

  describe '#include_params' do
    it 'converts to array' do
      i = SimpleJsonApi::Include.new(request_empty, Topic)
      expect(i.include_params).to eq([])

      i = SimpleJsonApi::Include.new(request_0, Topic)
      expect(i.include_params).to eq([])

      i = SimpleJsonApi::Include.new(request_1, Topic)
      expect(i.include_params).to eq(['publisher'])

      i = SimpleJsonApi::Include.new(request_3, Topic)
      expect(i.include_params).to match_array(['comments.author', 'publisher'])
    end
  end

  describe '#includes' do
    it 'raises an exception when invalid includes are specified (#relation called)' do
      i = SimpleJsonApi::Include.new(
        request_1,
        Topic,
        ['comments' => Topic.includes(:comments)]
      )
      expect { i.includes }.to raise_error(SimpleJsonApi::BadRequest,
                                           /Inclusion param 'publisher' is not supported/)
    end

    it 'raises an exception when invalid includes are specified (#relation not called)' do
      i = SimpleJsonApi::Include.new(
        request_1,
        Topic,
        ['comments']
      )
      expect { i.includes }.to raise_error(SimpleJsonApi::BadRequest,
                                           /Inclusion param 'publisher' is not supported/)
    end

    it 'is an array of permitted includes' do
      req = FakeRequest.new('include' => 'comments,comments.author,publisher')
      i = SimpleJsonApi::Include.new(
        req,
        Topic,
        [{ 'comments' => -> { includes(:comments) } }, 'comments.author', 'publisher']
      )
      expect(i.includes).to eq(['comments', 'comments.author', 'publisher'])
    end

    it 'is an array of permitted includes as symbols' do
      req = FakeRequest.new('include' => 'comments,comments.author,publisher')
      i = SimpleJsonApi::Include.new(
        req,
        Topic,
        [{ comments: -> { includes(:comments) } }, :'comments.author', :publisher]
      )
      expect(i.includes).to eq(['comments', 'comments.author', 'publisher'])
    end

    it 'handles empty string' do
      req = FakeRequest.new('include' => ' ')
      i = SimpleJsonApi::Include.new(
        req,
        Topic,
        [{ 'comments' => -> { includes(:comments) } }, 'comments.author', 'publisher']
      )
      expect(i.includes).to eq([])
    end
  end

  describe '#query' do
    it 'is an alias to #relation' do
      expect(SimpleJsonApi::Include.instance_method(:query)).to eq(
        SimpleJsonApi::Include.instance_method(:relation)
      )
    end
  end

  describe '#relation' do
    before(:each) do
      @user = User.create(email: 'jane@doe.com')
      @publisher1 = Publisher.create(name: 'Pub1')
      @publisher2 = Publisher.create(name: 'Pub2')
      @topic1 = Topic.create(book: 'Harry Potter and the Half-Blood Prince',
                             quote: 'for validation',
                             publisher: @publisher1,
                             author: 'J.K. Rowling')
      @topic2 = Topic.create(book: 'Harry Potter and the Order of the Phoenix',
                             quote: 'for validation',
                             publisher: @publisher2,
                             author: 'J.K. Rowling')
      @topic3 = Topic.create(book: 'Harry Potter and the Prisoner of Azkaban',
                             quote: 'for validation',
                             publisher: @publisher1,
                             author: 'J.K. Rowling')
      @comment1 = Comment.create(author: @user, topic: @topic2, title: 'Comment about topic 2')
      @comment2 = Comment.create(author: @user, topic: @topic1, title: 'Comment about topic 1')
    end

    after(:each) { delete_all_records }

    it 'preloads matching belongs_to relationship' do
      i = SimpleJsonApi::Include.new(
        request_1,
        Topic,
        ['publisher' => -> { includes(:publisher) }]
      )
      topic = i.relation.first
      expect(topic).to have_loaded_association(:publisher)
      expect(topic).not_to have_loaded_association(:comments)
    end

    it 'preloads matching has_many relationship' do
      i = SimpleJsonApi::Include.new(
        request_2,
        Topic,
        ['comments' => -> { includes(:comments) }]
      )
      topic = i.relation.first
      expect(topic).to have_loaded_association(:comments)
      expect(topic).not_to have_loaded_association(:publisher)
    end

    it 'accepts relationship defined as Model.includes(...)' do
      i = SimpleJsonApi::Include.new(
        request_2,
        Topic,
        ['comments' => Topic.includes(:comments)]
      )
      topic = i.relation.first
      expect(topic).to have_loaded_association(:comments)
    end

    it 'raises exception if requested include is not permitted' do
      i = SimpleJsonApi::Include.new(
        request_1,
        Topic,
        ['comments' => Topic.includes(:comments)]
      )
      expect { i.relation }.to raise_error(SimpleJsonApi::BadRequest,
                                           /Inclusion param 'publisher' is not supported/)
    end

    it "doesn't raise an exception if no include parameters" do
      i = SimpleJsonApi::Include.new(
        request_0,
        Topic,
        ['comments' => Topic.includes(:comments)]
      )
      expect { i.relation }.not_to raise_error
    end

    it "doesn't raise an exception if include parameter is empty string" do
      i = SimpleJsonApi::Include.new(
        request_empty,
        Topic,
        ['comments' => Topic.includes(:comments)]
      )
      expect { i.relation }.not_to raise_error
    end

    it "returns nil if eagerloading isn't configured for any" do
      i = SimpleJsonApi::Include.new(
        request_2,
        Topic,
        ['comments']
      )
      expect(i.relation).to eq(nil)
    end

    it 'eagerloads if at least one config has eagerloading' do
      request = FakeRequest.new('include' => 'comments,publisher', 'sort' => '-character')
      i = SimpleJsonApi::Include.new(
        request,
        Topic,
        ['comments', { 'publisher' => -> { includes(:publisher) } }]
      )
      expect(i.relation).to_not eq(nil)
    end

    it 'eagerloads when 2+ are configured for eagerloading' do
      request = FakeRequest.new('include' => 'comments,publisher', 'sort' => '-character')
      i = SimpleJsonApi::Include.new(
        request,
        Topic,
        [{ 'comments' => -> { includes(:comments) } }, { 'publisher' => -> { includes(:publisher) } }]
      )
      topic = i.relation.first
      expect(topic).to have_loaded_association(:comments)
      expect(topic).to have_loaded_association(:publisher)
    end
  end
end
