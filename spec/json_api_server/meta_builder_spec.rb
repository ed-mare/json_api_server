require 'rails_helper'

describe JsonApiServer::MetaBuilder do
  describe '#add' do
    it 'is adds key/value to meta hash' do
      b = JsonApiServer::MetaBuilder.new
                                    .add('foo', 'bar')
      expect(b.meta).to eq('foo' => 'bar')
    end
  end

  describe '#merge' do
    it 'is merges hash to meta hash' do
      b = JsonApiServer::MetaBuilder.new
                                    .add('foo', 'bar')
                                    .merge(a: [1, 2, 3])
      expect(b.meta).to eq('foo' => 'bar', a: [1, 2, 3])
    end

    it 'ignores nil and empty hash' do
      b = JsonApiServer::MetaBuilder.new
                                    .add('foo', 'bar')
                                    .merge(nil)
                                    .merge({})
      expect(b.meta).to eq('foo' => 'bar')
    end
  end
end
