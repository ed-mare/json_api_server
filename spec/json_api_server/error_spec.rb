require 'spec_helper'

describe JsonApiServer::Error do
  include_context 'errors shared context'

  let(:error) do
    JsonApiServer::Error.new(error_1_hash)
  end

  describe '#intialize' do
    it 'sets id in #errors' do
      expect(error.error['id']).to eq(1504)
    end
    it 'sets status in #errors' do
      expect(error.error['status']).to eq('422')
    end
    it 'sets code in #errors' do
      expect(error.error['code']).to eq(5)
    end
    it 'sets source in #errors' do
      expect(error.error['source']).to eq('pointer' => '/data/attributes/first-name')
    end
    it 'sets title in #errors' do
      expect(error.error['title']).to eq('Invalid Attribute')
    end
    it 'sets detail in #errors' do
      expect(error.error['detail']).to eq('First name must contain at least three characters.')
    end
    it 'sets meta in #errors' do
      expect(error.error['meta']).to eq('attrs' => [1, 2, 3])
    end
    it 'sets links in #errors' do
      expect(error.error['links']).to eq('self' => 'http://example.com/user')
    end
    it 'sets error to empty Array if params not a hash' do
      e = JsonApiServer::Error.new(nil)
      expect(e.as_json).to eq('jsonapi' => { 'version' => '1.0' }, 'errors' => [])
      e1 = JsonApiServer::Error.new([1, 2, 3])
      expect(e1.as_json).to eq('jsonapi' => { 'version' => '1.0' }, 'errors' => [])
    end
  end

  describe '#as_json' do
    it 'includes json api version and error object' do
      expect(error.as_json).to eq(error_1_as_json)
    end
    it 'excludes non-jsonapi attributes' do
      expect(error.error.key?('ignoreme')).to eq(false)
    end
  end

  describe '#to_json' do
    it 'serializes as_json to json' do
      expect(error.to_json).to be_same_json_as(error_1_to_json)
    end
  end
end
