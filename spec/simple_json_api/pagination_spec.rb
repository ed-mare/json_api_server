require 'rails_helper'

describe SimpleJsonApi::Pagination do
  let(:max_per_page) { 5 }
  let(:default_per_page) { 4 }
  let(:request_all) { FakeRequest.new(page: { number: '2', limit: '3' }) }
  let(:request_bad_values) { FakeRequest.new(page: { number: 'foo', limit: 'bar' }) }
  let(:request_negative_values) { FakeRequest.new(page: { number: '-4', limit: '-5' }) }
  let(:request_none) { FakeRequest.new({}) }
  let(:pagination_with_opts) do
    SimpleJsonApi::Pagination.new(request_all, Topic, max_per_page: max_per_page,
                                                      default_per_page: default_per_page)
  end
  let(:pagination_no_opts) do
    SimpleJsonApi::Pagination.new(request_all, Topic)
  end
  let(:pagination_bad_params) do
    SimpleJsonApi::Pagination.new(request_bad_values, Topic, max_per_page: max_per_page,
                                                             default_per_page: default_per_page)
  end
  let(:pagination_negative_params) do
    SimpleJsonApi::Pagination.new(request_negative_values, Topic, max_per_page: max_per_page,
                                                                  default_per_page: default_per_page)
  end
  let(:pagination_no_params) do
    SimpleJsonApi::Pagination.new(request_none, Topic, max_per_page: max_per_page,
                                                       default_per_page: default_per_page)
  end

  describe '#initialize' do
    it 'assigns request attr' do
      expect(pagination_with_opts.request).to be(request_all)
    end

    it 'assigns model attr' do
      expect(pagination_with_opts.model).to be(Topic)
    end

    it 'assigns params attr to request.query_parameters' do
      expect(pagination_with_opts.params).to be(request_all.query_parameters)
    end

    it 'assigns max_per_page option to :max_per_page attr' do
      expect(pagination_with_opts.max_per_page).to eq(max_per_page)
    end

    it 'assigns default_per_page option to :default_per_page attr' do
      expect(pagination_with_opts.default_per_page).to eq(default_per_page)
    end

    it 'defaults max_per_page to SimpleJsonApi.configuration.default_max_per_page' do
      expect(pagination_no_opts.max_per_page).to eq(SimpleJsonApi.configuration.default_max_per_page)
    end

    it 'defaults default_per_page to SimpleJsonApi.configuration.default_per_page' do
      expect(pagination_no_opts.default_per_page).to eq(SimpleJsonApi.configuration.default_per_page)
    end
  end

  describe '#number' do
    it 'is an alias to #page' do
      expect(SimpleJsonApi::Pagination.instance_method(:number)).to eq(
        SimpleJsonApi::Pagination.instance_method(:page)
      )
    end
  end

  describe '#page' do
    it 'converts number to an integer' do
      expect(pagination_with_opts.page).to eq(2)
    end

    it 'converts invalid number (foo) to 1' do
      expect(pagination_bad_params.page).to eq(1)
    end

    it 'converts negative number to 1' do
      expect(pagination_negative_params.page).to eq(1)
    end

    it 'converts no number to 1' do
      expect(pagination_no_params.page).to eq(1)
    end
  end

  describe '#limit' do
    it 'is an alias to #per_page' do
      expect(SimpleJsonApi::Pagination.instance_method(:limit)).to eq(
        SimpleJsonApi::Pagination.instance_method(:per_page)
      )
    end
  end

  describe '#per_page' do
    it 'converts limit to an integer' do
      expect(pagination_with_opts.per_page).to eq(3)
    end

    it 'converts invalid limit (bar) to default_per_page' do
      expect(pagination_bad_params.per_page).to eq(default_per_page)
    end

    it 'converts negative limit to default_per_page' do
      expect(pagination_negative_params.per_page).to eq(default_per_page)
    end

    it 'converts no limit to default_per_page' do
      expect(pagination_no_params.per_page).to eq(default_per_page)
    end

    it 'is :max_per_page when limit > max_per_page' do
      request = FakeRequest.new(page: { number: '2', limit: '25' })
      pagination = SimpleJsonApi::Pagination.new(request, Topic, max_per_page: 6)
      expect(pagination.per_page).to eq(6)
    end
  end

  describe '#paginator_for' do
    before(:all) do
      @publisher = Publisher.create(name: 'Pub1')
      (1..13).each do |i|
        Topic.create(book: "Book #{i}",
                     quote: 'for validation',
                     publisher: @publisher,
                     author: 'J.K. Rowling')
      end
    end

    after(:all) { delete_all_records }
    let(:pagination) { SimpleJsonApi::Pagination.new(request_all, Topic, max_per_page: 10) }
    let(:paginator) { pagination.paginator_for(pagination.query) }

    it 'returns a SimpleJsonApi::Paginator object' do
      expect(paginator).to be_instance_of(SimpleJsonApi::Paginator)
    end

    it 'sets the paginator attributes with values from the Pagination instance' do
      base_url = 'http://localhost:3001/fake' #  SimpleJsonApi.configuration.base_url + request.path

      expect(pagination.base_url).to eq(base_url)
      expect(paginator.first).to eq("#{base_url}?page%5Blimit%5D=3&page%5Bnumber%5D=1")
      expect(paginator.last).to eq("#{base_url}?page%5Blimit%5D=3&page%5Bnumber%5D=5")
      expect(paginator.self).to eq("#{base_url}?page%5Blimit%5D=3&page%5Bnumber%5D=2")
      expect(paginator.next).to eq("#{base_url}?page%5Blimit%5D=3&page%5Bnumber%5D=3")
      expect(paginator.prev).to eq("#{base_url}?page%5Blimit%5D=3&page%5Bnumber%5D=1")
    end
  end

  describe '#query' do
    it 'is an alias to #relation' do
      expect(SimpleJsonApi::Pagination.instance_method(:query)).to eq(
        SimpleJsonApi::Pagination.instance_method(:relation)
      )
    end
  end

  describe '#relation' do
    before(:all) do
      @publisher = Publisher.create(name: 'Pub1')
      (1..10).each do |i|
        Topic.create(book: "Book #{i}",
                     quote: 'for validation',
                     publisher: @publisher,
                     author: 'J.K. Rowling')
      end
    end

    after(:all) { delete_all_records }

    it 'calls will_paginate with :page and :per_page' do
      # SELECT  \"topics\".* FROM \"topics\" LIMIT 3 OFFSET 3
      expect(pagination_with_opts.per_page).to eq(3)
      expect(pagination_with_opts.page).to eq(2)
      expect(pagination_with_opts.relation.to_sql).to match(/LIMIT 3 OFFSET 3/i)
    end

    it 'uses defaults (page: 1, per_page: default_per_page) if no pagination params' do
      # SELECT  \"topics\".* FROM \"topics\" LIMIT 4 OFFSET 0
      expect(pagination_no_params.per_page).to eq(default_per_page)
      expect(pagination_no_params.page).to eq(1)
      expect(pagination_no_params.relation.to_sql).to match(/LIMIT #{default_per_page} OFFSET 0/i)
    end
  end
end
