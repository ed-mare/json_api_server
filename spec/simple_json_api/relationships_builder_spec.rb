require 'spec_helper'

describe SimpleJsonApi::RelationshipsBuilder do
  class PeopleSerializer < SimpleJsonApi::ResourceSerializer
    def links
      { self: File.join(base_url, "/people/#{@object[:id]}") }
    end

    def data
      {
        type: 'people',
        id: @object[:id],
        attributes: {
          first_name: @object[:first_name],
          last_name: @object[:last_name]
        }
      }
    end
  end

  class ComSerializer < SimpleJsonApi::ResourceSerializer
    resource_type 'comments'

    def links
      { self: File.join(base_url, "/comments/#{@object[:id]}") }
    end

    def data
      {
        type: 'comments',
        id: @object[:id],
        attributes: {
          title: @object[:title],
          comment: @object[:comment]
        }
      }
    end
  end

  class BookSerializer < SimpleJsonApi::ResourceSerializer
    def links
      { self: File.join(base_url, "/book/#{@object[:id]}") }
    end

    def data
      {
        type: 'books',
        id: @object[:id],
        attributes: {
          title: @object[:title],
          relationships: relationships.relationships
        }
      }
    end

    def included
      relationships.included
    end

    protected

    def relationships
      @relationships ||= begin
        comments = [{ id: 1, title: 'a', comment: 'b' }, { id: 2, title: 'c', comment: 'd' }]
        author = { id: 6, first_name: 'John', last_name: 'Steinbeck' }
        relationships_builder
          .include('author', PeopleSerializer.new(author), relate: { include: [:relationship_data] })
          .include_each('comments', comments, relate: { include: [:relationship_data] }) { |c| ComSerializer.new(c) }
      end
    end
  end

  let(:request) { FakeRequest.new('include' => 'comments,author') }
  let(:includes) { SimpleJsonApi::Include.new(request, nil, %w[comments author]) }
  let(:book_serializer) { BookSerializer.new({ id: 1, title: 'The Grapes of Wrath', author_id: 6 }, includes: includes.includes) }
  let(:comment1_serializer) { ComSerializer.new(id: 1, title: 'a', comment: 'b') }
  let(:comment2_serializer) { ComSerializer.new(id: 2, title: 'c', comment: 'd') }
  let(:author_serializer) { PeopleSerializer.new(id: 6, first_name: 'John', last_name: 'Steinbeck') }

  describe '#initialize' do
    let(:rb) { SimpleJsonApi::RelationshipsBuilder.new }

    it 'sets @relationships to empty hash' do
      expect(rb.instance_variable_get(:@relationships)).to eq({})
    end

    it 'sets @included to empty array' do
      expect(rb.instance_variable_get(:@included)).to eq([])
    end
  end

  describe '#relate' do
    it 'merges relationships into a hash' do
      author_serializer.as_json_options = { include: [:data] }

      r = SimpleJsonApi::RelationshipsBuilder.new
                                             .relate('author', author_serializer)
                                             .relationships

      expect(r).to eq(
        'author' => {
          'data' => {
            'type' => 'people',
            'id' => 6,
            'attributes' => { 'first_name' => 'John', 'last_name' => 'Steinbeck' }
          }
        }
      )
    end

    it 'creates an array if a key is used more than once' do
      comment1_serializer.as_json_options = { include: [:data] }
      comment2_serializer.as_json_options = { include: [:data] }

      r = SimpleJsonApi::RelationshipsBuilder.new
                                             .relate('comments', comment1_serializer)
                                             .relate('comments', comment2_serializer)
                                             .relationships

      expect(r).to eq(
        'comments' => [
          { 'data' => { 'type' => 'comments', 'id' => 1, 'attributes' => { 'title' => 'a', 'comment' => 'b' } } },
          { 'data' => { 'type' => 'comments', 'id' => 2, 'attributes' => { 'title' => 'c', 'comment' => 'd' } } }
        ]
      )
    end

    it 'removes duplicates from an array' do
      comment1_serializer.as_json_options = { include: [:data] }
      comment2_serializer.as_json_options = { include: [:data] }

      r = SimpleJsonApi::RelationshipsBuilder.new
                                             .relate('comments', comment1_serializer)
                                             .relate('comments', comment1_serializer)
                                             .relate('comments', comment1_serializer)
                                             .relationships

      # restores to hash if just one element in array.
      expect(r).to eq(
        'comments' => {
          'data' => { 'type' => 'comments', 'id' => 1, 'attributes' => { 'title' => 'a', 'comment' => 'b' } }
        }
      )

      r = SimpleJsonApi::RelationshipsBuilder.new
                                             .relate('comments', comment1_serializer)
                                             .relate('comments', comment1_serializer)
                                             .relate('comments', comment2_serializer)
                                             .relate('comments', comment1_serializer)
                                             .relationships

      expect(r).to eq(
        'comments' => [
          { 'data' => { 'type' => 'comments', 'id' => 1, 'attributes' => { 'title' => 'a', 'comment' => 'b' } } },
          { 'data' => { 'type' => 'comments', 'id' => 2, 'attributes' => { 'title' => 'c', 'comment' => 'd' } } }
        ]
      )
    end

    it 'allows relationship type to be specified (defaults to relationship name)' do
      author_serializer.as_json_options = { include: [:data] }
      r = SimpleJsonApi::RelationshipsBuilder.new
                                             .relate('author', author_serializer)
                                             .relationships

      expect(r).to eq(
        'author' => {
          'data' => {
            'type' => 'people',
            'id' => 6,
            'attributes' => { 'first_name' => 'John', 'last_name' => 'Steinbeck' }
          }
        }
      )
    end
  end

  describe '#relate_each' do
    let(:comments) do
      [
        { id: 1, title: 'a', comment: 'b' },
        { id: 2, title: 'c', comment: 'd' }
      ]
    end

    it 'relates each when in @includes' do
      r = SimpleJsonApi::RelationshipsBuilder.new
                                             .relate_each('comments', comments) { |c| ComSerializer.new(c, as_json_options: { include: [:data] }) }
                                             .relationships

      expect(r).to eq(
        'comments' => [
          { 'data' => { 'type' => 'comments', 'id' => 1, 'attributes' => { 'title' => 'a', 'comment' => 'b' } } },
          { 'data' => { 'type' => 'comments', 'id' => 2, 'attributes' => { 'title' => 'c', 'comment' => 'd' } } }
        ]
      )
    end
  end

  describe '#include' do
    it 'adds, by default, the data element to included (array)' do
      r = SimpleJsonApi::RelationshipsBuilder.new
                                             .include('author', author_serializer)
                                             .include('comments', comment1_serializer)
                                             .include('comments', comment2_serializer)
                                             .included

      expect(r).to eq([
                        { 'type' => 'people', 'id' => 6, 'attributes' => { 'first_name' => 'John', 'last_name' => 'Steinbeck' } },
                        { 'type' => 'comments', 'id' => 1, 'attributes' => { 'title' => 'a', 'comment' => 'b' } },
                        { 'type' => 'comments', 'id' => 2, 'attributes' => { 'title' => 'c', 'comment' => 'd' } }
                      ])
    end

    it 'adds to relationships if :relate option is specified' do
      b = SimpleJsonApi::RelationshipsBuilder.new
                                             .include('author', author_serializer, relate: { include: [:relationship_data] })
                                             .include('comments', comment1_serializer, relate: { include: [:relationship_data] })
                                             .include('comments', comment2_serializer, relate: { include: [:relationship_data] })

      expect(b.included).to eq([
                                 { 'type' => 'people', 'id' => 6, 'attributes' => { 'first_name' => 'John', 'last_name' => 'Steinbeck' } },
                                 { 'type' => 'comments', 'id' => 1, 'attributes' => { 'title' => 'a', 'comment' => 'b' } },
                                 { 'type' => 'comments', 'id' => 2, 'attributes' => { 'title' => 'c', 'comment' => 'd' } }
                               ])

      expect(b.relationships).to eq('author' => { 'data' => { 'type' => 'people', 'id' => 6 } },
                                    'comments' => [{ 'data' => { 'type' => 'comments', 'id' => 1 } }, { 'data' => { 'type' => 'comments', 'id' => 2 } }])
    end

    it 'allows relationship type to be specified in options' do
      b = SimpleJsonApi::RelationshipsBuilder.new
                                             .include('author', author_serializer, relate: { include: [:relationship_data] })

      # type doesn't affect includes
      expect(b.included).to eq(
        [
          { 'type' => 'people', 'id' => 6, 'attributes' => { 'first_name' => 'John', 'last_name' => 'Steinbeck' } }
        ]
      )

      # type affects relationships only
      expect(b.relationships).to eq('author' => { 'data' => { 'type' => 'people', 'id' => 6 } })
    end
  end

  describe '#include_each' do
    let(:comments) do
      [
        { id: 1, title: 'a', comment: 'b' },
        { id: 2, title: 'c', comment: 'd' }
      ]
    end

    it 'adds each element to included (array)' do
      r = SimpleJsonApi::RelationshipsBuilder.new
                                             .include('author', author_serializer)
                                             .include_each('comments', comments) { |c| ComSerializer.new(c) }
                                             .included

      expect(r).to eq([
                        { 'type' => 'people', 'id' => 6, 'attributes' => { 'first_name' => 'John', 'last_name' => 'Steinbeck' } },
                        { 'type' => 'comments', 'id' => 1, 'attributes' => { 'title' => 'a', 'comment' => 'b' } },
                        { 'type' => 'comments', 'id' => 2, 'attributes' => { 'title' => 'c', 'comment' => 'd' } }
                      ])
    end

    it 'adds to relationships if :relate option is specified' do
      b = SimpleJsonApi::RelationshipsBuilder.new
                                             .include('author', author_serializer, relate: { include: [:relationship_data] })
                                             .include_each('comments', comments, relate: { include: [:relationship_data] }) { |c| ComSerializer.new(c) }

      expect(b.included).to eq([
                                 { 'type' => 'people', 'id' => 6, 'attributes' => { 'first_name' => 'John', 'last_name' => 'Steinbeck' } },
                                 { 'type' => 'comments', 'id' => 1, 'attributes' => { 'title' => 'a', 'comment' => 'b' } },
                                 { 'type' => 'comments', 'id' => 2, 'attributes' => { 'title' => 'c', 'comment' => 'd' } }
                               ])

      expect(b.relationships).to eq('author' => { 'data' => { 'type' => 'people', 'id' => 6 } },
                                    'comments' => [{ 'data' => { 'type' => 'comments', 'id' => 1 } }, { 'data' => { 'type' => 'comments', 'id' => 2 } }])
    end
  end

  describe 'example using object in a serializer' do
    it 'creates the correct hash' do
      expect(book_serializer.as_json).to eq(
        { jsonapi: { version: '1.0' },
          links: { self: 'http://localhost:3001/book/1' },
          data: { type: 'books', id: 1,
                  attributes: { title: 'The Grapes of Wrath',
                                relationships: {
                                  'author' => { data: { type: 'people', id: 6 } },
                                  'comments' => [
                                    { data: { type: 'comments', id: 1 } },
                                    { data: { type: 'comments', id: 2 } }
                                  ]
                                } } },
          included: [
            { type: 'people', id: 6, attributes: { first_name: 'John', last_name: 'Steinbeck' } },
            { type: 'comments', id: 1, attributes: { title: 'a', comment: 'b' } },
            { type: 'comments', id: 2, attributes: { title: 'c', comment: 'd' } }
          ],
          meta: nil }.with_indifferent_access
      )
    end
  end
end
