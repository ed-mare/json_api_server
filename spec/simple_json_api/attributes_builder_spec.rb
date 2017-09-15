require 'spec_helper'
require 'ostruct'

describe SimpleJsonApi::AttributesBuilder do
  let(:fields) { %w[title body author_name created_at updated_at] }
  let(:fields1) { %w[title body author_name] }
  let(:object) do
    OpenStruct.new(title: 'what', body: 'ho', author_name: 'John',
    created_at: Time.now, updated_at: Time.now)
  end

  describe '#fields' do
    it 'is assigned in initialize' do
      b = SimpleJsonApi::AttributesBuilder.new(fields)
      expect(b.fields).to eq(fields)
    end

    it 'stringifies array elements' do
      a = fields.map(&:to_sym)
      b = SimpleJsonApi::AttributesBuilder.new(a)
      expect(b.fields).to eq(fields)
    end

    it 'defaults to nil' do
      b = SimpleJsonApi::AttributesBuilder.new
      expect(b.fields).to eq(nil)
    end
  end

  describe 'add' do
    it 'is chainable' do
      b = SimpleJsonApi::AttributesBuilder.new(fields1)
      expect(b.add('title', 'the title')).to be(b)
    end

    it 'adds when name is in fields array' do
      attrs = SimpleJsonApi::AttributesBuilder.new(fields1)
                                              .add('title', 'the title')
                                              .add('body', 'the body')
                                              .add('author_name', 'the name')
                                              .add('created_at', 'created')
                                              .add('updated_at', 'updated')
                                              .attributes

      expect(attrs).to eq('title' => 'the title',
                          'body' => 'the body',
                          'author_name' => 'the name')
    end

    it 'accepts strings or symbols for name' do
      attrs = SimpleJsonApi::AttributesBuilder.new(fields1)
                                              .add('title', 'the title')
                                              .add(:body, 'the body')
                                              .add('author_name', 'the name')
                                              .add(:created_at, 'created')
                                              .add('updated_at', 'updated')
                                              .attributes

      expect(attrs).to eq('title' => 'the title',
                          'body' => 'the body',
                          'author_name' => 'the name')
    end

    it 'adds all if fields array is nil' do
      attrs = SimpleJsonApi::AttributesBuilder.new
                                              .add('title', 'the title')
                                              .add('body', 'the body')
                                              .add('author_name', 'the name')
                                              .add('created_at',  Date.new(2000, 7, 8).iso8601)
                                              .add('updated_at', Date.new(2000, 7, 9).iso8601)
                                              .attributes

      expect(attrs).to eq('title' => 'the title',
                          'body' => 'the body',
                          'author_name' => 'the name',
                          'created_at' => '2000-07-08',
                          'updated_at' => '2000-07-09')
    end
  end

  describe 'add_multi' do
    it 'is chainable' do
      b = SimpleJsonApi::AttributesBuilder.new(fields1)
      expect(b.add_multi(object, :title)).to be(b)
    end

    it 'adds values in the fields array' do
      attrs = SimpleJsonApi::AttributesBuilder.new(fields1)
                .add_multi(object, :title, :body, :author_name, :created_at)
                .attributes

      expect(attrs).to eq('title' => 'what',
                          'body' => 'ho',
                          'author_name' => 'John')
    end

    it 'takes symbols or strings for attributes' do
      attrs = SimpleJsonApi::AttributesBuilder.new(fields1)
                .add_multi(object, 'title', :body, 'author_name', :created_at)
                .attributes

      expect(attrs).to eq('title' => 'what',
                                    'body' => 'ho',
                                    'author_name' => 'John')
    end
  end

  describe 'add_if' do
    it 'adds when the proc returns true' do
      attrs = SimpleJsonApi::AttributesBuilder.new(fields)
                                              .add_if('title', 'the title', -> { 1 == 1 })
                                              .add_if('body', 'the body', -> { 1 == 2 })
                                              .add_if('author_name', 'the name', -> { 'foo' })
                                              .add('created_at', 'created')
                                              .add('updated_at', 'updated')
                                              .attributes

      expect(attrs).to eq('title' => 'the title',
                          'created_at' => 'created',
                          'updated_at' => 'updated')
    end
  end
end
