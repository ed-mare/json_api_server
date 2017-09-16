require 'spec_helper'

describe SimpleJsonApi::Paginator do
  let(:current_page) { 3 }
  let(:total_pages) { 24 }
  let(:per_page) { 10 }
  let(:base_url) { 'https://www.example.com/articles/' }
  let(:params) { { foo: 'bar', page: { limit: 12, number: 7 } } }
  let(:paginator) do
    SimpleJsonApi::Paginator.new(current_page, total_pages, per_page, base_url, **params)
  end

  describe '#initialize' do
    it 'sets @current_page to value specified in method parameter' do
      expect(paginator.instance_variable_get(:@current_page)).to eq(current_page)
    end

    it 'sets @total_pages to value specified in method parameter' do
      expect(paginator.instance_variable_get(:@total_pages)).to eq(total_pages)
    end

    it 'sets @per_page to value specified in method parameter' do
      expect(paginator.instance_variable_get(:@per_page)).to eq(per_page)
    end

    it 'sets @base_url to value specified in method parameter' do
      expect(paginator.instance_variable_get(:@base_url)).to eq(base_url)
    end

    it 'sets @params to value specified in method parameter' do
      expect(paginator.instance_variable_get(:@params)).to eq(params)
    end
  end

  describe '#first' do
    it 'sets the url to the first page' do
      expected = "#{base_url}?foo=bar&page%5Blimit%5D=#{per_page}&page%5Bnumber%5D=1"
      expect(paginator.first).to eq(expected)
    end

    # sets url
    # includes all params
  end

  describe '#last' do
    it 'sets the url to the last page' do
      expected = "#{base_url}?foo=bar&page%5Blimit%5D=#{per_page}&page%5Bnumber%5D=24"
      expect(paginator.last).to eq(expected)
    end
  end

  describe '#self' do
    it 'sets the url to the current page' do
      expected = "#{base_url}?foo=bar&page%5Blimit%5D=#{per_page}&page%5Bnumber%5D=3"
      expect(paginator.self).to eq(expected)
    end
  end

  describe '#next' do
    it 'sets the url to the next page' do
      expected = "#{base_url}?foo=bar&page%5Blimit%5D=#{per_page}&page%5Bnumber%5D=4"
      expect(paginator.next).to eq(expected)
    end

    it 'is nil when current_page is last page' do
      p = SimpleJsonApi::Paginator.new(total_pages, total_pages, per_page, base_url, **params)
      expect(p.next).to eq(nil)
    end

    it 'is nil when current_page is invalid' do
      p = SimpleJsonApi::Paginator.new(-2, total_pages, per_page, base_url, **params)
      expect(p.next).to eq(nil)

      p1 = SimpleJsonApi::Paginator.new(total_pages + 1, total_pages, per_page, base_url, **params)
      expect(p1.next).to eq(nil)
    end
  end

  describe '#prev' do
    it 'sets the url correctly' do
      expected = "#{base_url}?foo=bar&page%5Blimit%5D=#{per_page}&page%5Bnumber%5D=2"
      expect(paginator.prev).to eq(expected)
    end

    it 'is nil when current_page is first page' do
      p = SimpleJsonApi::Paginator.new(1, total_pages, per_page, base_url, **params)
      expect(p.prev).to eq(nil)
    end

    it 'is nil when current_page is invalid' do
      p = SimpleJsonApi::Paginator.new(-2, total_pages, per_page, base_url, **params)
      expect(p.prev).to eq(nil)

      p1 = SimpleJsonApi::Paginator.new(total_pages + 2, total_pages, per_page, base_url, **params)
      expect(p1.prev).to eq(nil)
    end
  end

  describe '#as_json' do
    it 'returns a hash with first, self, next, prev, last' do
      expect(paginator.as_json).to eq('first' => "#{base_url}?foo=bar&page%5Blimit%5D=#{per_page}&page%5Bnumber%5D=1",
                                      'last' => "#{base_url}?foo=bar&page%5Blimit%5D=#{per_page}&page%5Bnumber%5D=24",
                                      'self' => "#{base_url}?foo=bar&page%5Blimit%5D=#{per_page}&page%5Bnumber%5D=3",
                                      'next' => "#{base_url}?foo=bar&page%5Blimit%5D=#{per_page}&page%5Bnumber%5D=4",
                                      'prev' => "#{base_url}?foo=bar&page%5Blimit%5D=#{per_page}&page%5Bnumber%5D=2")
    end
  end

  describe '#to_h' do
    it 'aliases as_json' do
      expect(paginator.as_json).to eq(paginator.to_h)
    end
  end

  describe '#meta_info' do
    it 'returns current_page, total_pages, and per_page as a hash' do
      expect(paginator.meta_info).to eq('links' => {
                                          'current_page' => current_page,
                                          'total_pages' => total_pages,
                                          'per_page' => per_page
                                        })
    end
  end
end
