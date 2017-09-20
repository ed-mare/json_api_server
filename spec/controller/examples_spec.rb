require 'rails_helper'

# Serializers for test_app models.
require_relative '../example_serializers/user_serializer'
require_relative '../example_serializers/publisher_serializer'
require_relative '../example_serializers/comment_serializer'
require_relative '../example_serializers/topic_serializer'
require_relative '../example_serializers/topics_serializer'

# Base API controller handles errors.
class BaseController < ApplicationController
  include JsonApiServer::Controller::ErrorHandling
end

# Use fitler, sort and pagination in controller.
class TopicsController < BaseController
  attr_accessor :pagination_options, :sort_options, :filter_options, :include_options
end

RSpec.describe 'Examples (putting it all together)', type: :controller do
  before(:all) do
    @user = User.create(email: 'jane@doe.com', first_name: 'Jane', last_name: 'Doe')
    @publisher1 = Publisher.create(name: 'Pub1')
    @publisher2 = Publisher.create(name: 'Pub2')
    @topic1 = Topic.create!(character: 'Kreacher',
                            location: 'Dervish & Banges',
                            quote: 'Harry, suffering like this proves you are still a man! This pain is part of being human … the fact that you can feel pain like this is your greatest strength.',
                            book: 'Harry Potter and the Half-Blood Prince',
                            published: Date.new(2005, 7, 16),
                            publisher: @publisher1,
                            author: 'J.K. Rowling')
    @topic2 = Topic.create!(character: 'Hedwig',
                            location: 'Ministry of Magic',
                            quote: 'To the well-organized mind, death is but the next great adventure.',
                            book: 'Harry Potter and the Order of the Phoenix',
                            published: Date.new(2003, 6, 21),
                            publisher: @publisher2,
                            author: 'J.K. Rowling')
    @topic3 = Topic.create!(character: 'Ernie Macmillan',
                            location: 'The Leaky Cauldron',
                            quote: 'Dark and difficult times lie ahead. Soon we must all face the choice between what is right and what is easy.',
                            book: 'Harry Potter and the Prisoner of Azkaban',
                            published: Date.new(1999, 7, 8),
                            publisher: @publisher1,
                            author: 'J.K. Rowling')
    @topic4 = Topic.create!(character: 'Frank Longbottom',
                            location: 'Ministry of Magic',
                            quote: 'Platform 9 3/4',
                            book: 'Harry Potter and the Goblet of Fire',
                            published: Date.new(2000, 7, 8),
                            publisher: @publisher2,
                            author: 'J.K. Rowling')
    @topic5 = Topic.create!(character: 'Florean Fortescue',
                            location: 'Azkaban',
                            quote: 'It takes a great deal of bravery to stand up to our enemies, but just as much to stand up to our friends.',
                            book: 'Harry Potter and the Order of the Phoenix',
                            published: Date.new(2003, 6, 21),
                            publisher: @publisher1,
                            author: 'J.K. Rowling')
    @topic6 = Topic.create!(character: 'Harry Potter',
                            location: 'Hogwards',
                            quote: 'I solemnly swear I am up to no good.',
                            book: 'Harry Potter and the Chamber of Secrets',
                            published: Date.new(1998, 7, 2),
                            publisher: @publisher2,
                            author: 'J.K. Rowling')

    [@topic1, @topic2, @topic3, @topic4, @topic5, @topic6].each do |topic|
      (1..5).each do |i|
        Comment.create!(author: @user, topic: topic,
                        title: "Comment title about topic #{topic.id} - #{i}",
                        comment: "Comment about #{topic.id} - #{i}")
      end
    end
  end

  after(:all) { delete_all_records }

  controller(TopicsController) do
    before_action do |c|
      c.pagination_options = { default_per_page: 2, max_per_page: 5 }
      c.sort_options = {
        permitted: %i[character location published],
        default: { id: :desc }
      }
      c.filter_options = [
        { id: { type: 'Integer' } },
        { published: { type: 'Date' } },
        { published1: { col_name: :published, type: 'Date' } },
        :location,
        { book: { wildcard: :both } },
        { search: { builder: :model_query, method: :search } }
      ]
      c.include_options = [{ 'publisher' => -> { includes(:publisher) } },
                           { 'comments' => -> { includes(:comments) } },
                           'comment.author']
    end

    def index
      builder = JsonApiServer::Builder.new(request, Topic.all)
                                      .add_pagination(pagination_options)
                                      .add_filter(filter_options)
                                      .add_sort(sort_options)
                                      .add_include(include_options)
                                      .add_fields

      serializer = TopicsSerializer.from_builder(builder)

      # -> Alternatively....
      # serializer = TopicsSerializer.new(
      #   builder.query,
      #   paginator: builder.paginator,
      #   filter: builder.filter,
      #   includes: builder.includes,
      #   fields: builder.sparse_fields
      # )

      render json: serializer.to_json, status: :ok
    end

    def show
      include_options = ['publisher', 'comments', 'comments.includes']

      topic = Topic.find(params[:id])
      builder = JsonApiServer::Builder.new(request, topic)
                                      .add_include(include_options)
                                      .add_fields

      serializer = TopicSerializer.from_builder(builder)

      # -> Alternatively....
      # serializer = TopicSerializer.new(
      #   topic,
      #   includes: builder.includes,
      #   fields: builder.sparse_fields
      # )

      render json: serializer.to_json, status: :ok
    end

    def create
      topic = Topic.new(topic_params)
      if topic.save
        serializer = TopicSerializer.new(topic)
        render json: serializer.to_json, status: :created
      else
        render_422(topic)
      end
    end

    protected

    def topic_params
      params.require(:data)
            .require(:attributes)
            .permit(:character, :location, :book, :quote, :author, :published)
    end
  end

  describe '#index' do
    context 'with no querystring params' do
      before(:each) do
        get :index
        @hash = load_json(response.body)
        # puts response.body
      end

      it 'returns 200' do
        expect(response).to have_http_status(200)
      end

      it 'includes jsonapi version' do
        expect(@hash['jsonapi']).to eq('version' => '1.0')
      end

      it 'includes links' do
        links = @hash['links']
        expect(links['self']).to eq('http://localhost:3001/topics?page%5Blimit%5D=2&page%5Bnumber%5D=1')
        expect(links['first']).to eq('http://localhost:3001/topics?page%5Blimit%5D=2&page%5Bnumber%5D=1')
        expect(links['last']).to eq('http://localhost:3001/topics?page%5Blimit%5D=2&page%5Bnumber%5D=3')
        expect(links['prev']).to eq(nil)
        expect(links['next']).to eq('http://localhost:3001/topics?page%5Blimit%5D=2&page%5Bnumber%5D=2')
      end

      it 'includes data ordered by id desc (configured as default)' do
        data = @hash['data']
        first = data.first
        second = data.second
        expect(data.length).to eq(2)
        expect(first['id']).to eq(@topic6.id)
        expect(second['id']).to eq(@topic5.id)
      end

      it 'includes meta info' do
        meta = @hash['meta']
        expect(meta['links']).to eq('current_page' => 1, 'total_pages' => 3, 'per_page' => 2)
        expect(meta['filter']).to eq([])
      end
    end

    context 'with querystring params' do
      before(:each) do
        get :index, params: {
          page: { number: 1, limit: 4 },
          sort: '-location',
          filter: { published: '>1998-01-01', published1: '<1999-12-31' },
          include: 'publisher,comments,comment.author',
          fields: { comments: 'title,comment', users: 'email,first_name,last_name' }
        }
        @hash = load_json(response.body)
      end

      it 'returns 200' do
        expect(response).to have_http_status(200)
        # puts response
        # puts @hash.to_json
      end

      it 'includes jsonapi version' do
        expect(@hash['jsonapi']).to eq('version' => '1.0')
      end

      it 'includes links' do
        links = @hash['links']

        selph = links['self']
        expect(selph).to have_query_parameter('filter[published]', '>1998-01-01')
        expect(selph).to have_query_parameter('filter[published1]', '<1999-12-31')
        expect(selph).to have_query_parameter('page[limit]', '4')
        expect(selph).to have_query_parameter('page[number]', '1')
        expect(selph).to have_query_parameter('sort', '-location')

        first = links['first']
        expect(first).to have_query_parameter('filter[published]', '>1998-01-01')
        expect(first).to have_query_parameter('filter[published1]', '<1999-12-31')
        expect(first).to have_query_parameter('page[limit]', '4')
        expect(first).to have_query_parameter('page[number]', '1')
        expect(first).to have_query_parameter('sort', '-location')

        last = links['last']
        expect(last).to have_query_parameter('filter[published]', '>1998-01-01')
        expect(last).to have_query_parameter('filter[published1]', '<1999-12-31')
        expect(last).to have_query_parameter('page[limit]', '4')
        expect(last).to have_query_parameter('page[number]', '1')
        expect(last).to have_query_parameter('sort', '-location')

        nxt = links['next']
        expect(nxt).to eq(nil)

        prev = links['prev']
        expect(prev).to eq(nil)
      end

      it 'includes data matching filter, ordered by location desc' do
        data = @hash['data']
        first = data.first
        second = data.second
        expect(data.length).to eq(2)
        expect(first['id']).to eq(@topic3.id)
        expect(second['id']).to eq(@topic6.id)
      end

      # requested includes "publisher,comments,comment.author",
      # permitted includes -> { 'publisher': -> { includes(:publisher) },
      #                'comments': -> { includes(:comments) },
      #                'comment.author': nil }
      # requested fields: { comments: 'title,comment', users: 'email,first_name,last_name'

      it 'includes publisher relationship' do
        # Expect this because its configured for as_json_options = {include: [:data]}
        #
        # "publisher": {
        #   "data": {
        #     "type": "publishers",
        #     "id": 1,
        #     "attributes": {
        #       "name": "Pub1",
        #       "created_at": "2017-08-29T22:48:17.467702000Z",
        #       "updated_at": "2017-08-29T22:48:17.467702000Z"
        #     }
        #   }
        # }
        first = @hash['data'].first
        rel = first['relationships']['publisher']['data']
        expect(rel.keys).to eq(%w[type id attributes])
        expect(rel['attributes'].keys).to eq(%w[name created_at updated_at])
      end

      it 'includes comments relationship with author relationship' do
        # - Expect only title, comment for comment (sparse_fields).
        # - Expect only email,first_name,last_name for author (sparse fields).
        # - Expect author relationship (comment.author) with all data attributes.
        #
        # "data": {
        #   "type": "comments",
        #   "id": 11,
        #   "attributes": {
        #     "title": "Comment title about topic 3 - 1",
        #     "comment": "Comment about 3 - 1"
        #   },
        #   "relationships": {
        #     "author": {
        #       "data": {
        #         "type": "users",
        #         "id": 1,
        #         "attributes": {
        #           "email": "jane@doe.com",
        #           "first_name": null,
        #           "last_name": null
        #         }
        #       }
        #     }
        #   }
        first = @hash['data'].first
        rel = first['relationships']['comments']
        comment = rel.first
        author = comment['data']['relationships']['author']

        expect(rel.length).to eq(5)
        expect(comment['data'].keys).to eq(%w[type id attributes relationships])
        expect(comment['data']['attributes'].keys).to eq(%w[title comment])

        expect(author['data'].keys).to eq(%w[type id attributes])
        expect(author['data']['attributes'].keys).to eq(%w[email first_name last_name])
      end

      it 'has no included data' do
        expect(@hash['included']).to eq([])
      end

      it 'includes meta info' do
        meta = @hash['meta']
        expect(meta['links']).to eq('current_page' => 1, 'total_pages' => 1, 'per_page' => 4)
        expect(meta['filter']).to eq(['published: >1998-01-01', 'published1: <1999-12-31'])
      end
    end
  end

  describe '#show' do
    context 'with existent id + includes + sparse fields' do
      before(:each) do
        get :show, params: { id: @topic3.id,
                             include: 'publisher,comments.includes',
                             fields: { comments: 'title,comment,created_at' } }
        @hash = load_json(response.body)
        # puts @hash.to_json
      end

      it 'returns a 200 response code' do
        expect(response).to have_http_status(200)
      end

      it 'includes jsonapi version' do
        expect(@hash['jsonapi']).to eq('version' => '1.0')
      end

      it 'includes link for self' do
        links = @hash['links']
        expect(links['self']).to eq("http://localhost:3001/topics/#{@topic3.id}")
      end

      it 'includes data' do
        data = @hash['data']

        expect(data['type']).to eq('topics')
        expect(data['id']).to eq(@topic3.id)
        expect(data['attributes']['character']).to eq(@topic3.character)
        expect(data['attributes']['published']).to eq(@topic3.published.iso8601)
      end

      it 'includes relationships' do
        # "relationships": {
        #  "comments": [
        #   {
        #     "data": {
        #       "type": "comments",
        #       "id": 11,
        #       "relationships": {}
        #     }
        #   },...

        # "included": [
        #   {
        #     "type": "comments",
        #     "id": 11,
        #     "attributes": {
        #       "title": "Comment title about topic 3 - 1",
        #       "comment": "Comment about 3 - 1",
        #       "created_at": "2017-08-30T06:04:48.382714000Z"
        #     },
        #     "relationships": {}
        #   },

        # fields: { comments: 'title,comment,created_at' }

        comments_relationship = @hash['data']['relationships']['comments']
        comment_data = comments_relationship.first['data']
        comments_includes = @hash['included']
        comment_includes = comments_includes.first

        expect(comments_relationship.length).to eq(5)
        expect(comments_includes.length).to eq(5)

        expect(comment_data.keys).to eq(%w[type id])
        expect(comment_includes.keys).to eq(%w[type id attributes relationships])
        expect(comment_includes['attributes'].keys).to eq(%w[title comment created_at])
      end
    end

    context 'with non-existent id' do
      before(:each) do
        get :show, params: { id: 12_345 }
        @response_hash = load_json(response.body)
      end

      it 'returns a 404 response code' do
        expect(response).to have_http_status(404)
      end

      it 'returns error json' do
        expected = { 'jsonapi' => { 'version' => '1.0' }, 'errors' => [{ 'status' => 404, 'title' => 'Not Found', 'detail' => 'This resource does not exist.' }] }
        expect(@response_hash).to eq(expected)
      end
    end
  end

  describe '#create' do
    context 'with valid params' do
      before(:each) do
        post :create, params: {
          data: {
            attributes: {
              character: 'Draco Malfoy',
              location: 'Flourish & Blotts',
              book: 'Harry Potter and the Chamber of Secrets',
              quote: "Can't even go to a bookshop without making the front page",
              author: 'J.K. Rowling',
              published: '1998-07-02'
            }
          }
        }
        @hash = load_json(response.body)
        @id = @hash['data']['id']
      end

      it 'returns a 201 response code' do
        expect(response).to have_http_status(201)
      end

      it 'includes jsonapi version' do
        expect(@hash['jsonapi']).to eq('version' => '1.0')
      end

      it 'includes link for self' do
        links = @hash['links']
        expect(links['self']).to eq("http://localhost:3001/topics/#{@id}")
      end

      it 'includes data' do
        data = @hash['data']
        expect(data['type']).to eq('topics')
        expect(data['id']).to eq(@id)
        expect(data['attributes']['character']).to eq('Draco Malfoy')
        expect(data['attributes']['quote']).to eq("Can't even go to a bookshop without making the front page")
        expect(data['attributes']['book']).to eq('Harry Potter and the Chamber of Secrets')
        expect(data['attributes']['location']).to eq('Flourish & Blotts')
        expect(data['attributes']['author']).to eq('J.K. Rowling')
        expect(data['attributes']['published']).to eq('1998-07-02')
      end
    end

    context 'with invalid params' do
      before(:each) do
        post :create, params: {
          data: {
            attributes: {
              character: 'Draco Malfoy'
            }
          }
        }
        @response_hash = load_json(response.body)
      end

      it 'returns a 422 response code' do
        expect(response).to have_http_status(422)
      end

      it 'returns error json' do
        expected = load_json(%q({"jsonapi":{"version":"1.0"},"errors":[
          {"status":"422", "source":{"pointer":"\/data\/attributes\/book"},"title":"Invalid Attribute","detail":"Book can't be blank"},
          {"status":"422", "source":{"pointer":"\/data\/attributes\/quote"},"title":"Invalid Attribute","detail":"Quote can't be blank"}
          ]}))
        expect(@response_hash).to eq(expected)
      end
    end
  end

  describe 'mime type' do
    describe 'with request content_type application/vnd.api+json' do
      before(:each) do
        request.content_type = 'application/vnd.api+json'
        get :show, params: { id: @topic3.id,
                             include: 'publisher',
                             fields: { comments: 'title,comment,created_at' } }
        @hash = load_json(response.body)
        # puts "REQUEST CONTENT TYPE #{request.content_type}"
      end
      it 'returns application/vnd.api+json' do
        expect(response.content_type).to eq('application/vnd.api+json')
      end
    end

    describe 'with request content_type application/json' do
      before(:each) do
        request.content_type = 'application/json'
        get :show, params: { id: @topic3.id,
                             include: 'publisher',
                             fields: { comments: 'title,comment,created_at' } }
        @hash = load_json(response.body)
      end
      it 'returns application/vnd.api+json' do
        expect(response.content_type).to eq('application/vnd.api+json')
      end
    end
  end
end
