require 'spec_helper'

describe SimpleJsonApi::ApiVersion do
  let(:my_class) do
    klass = Class.new do
      include SimpleJsonApi::ApiVersion
    end
    klass.new
  end

  describe '#jsonapi' do
    it 'has a JSON API version number' do
      expect(my_class.jsonapi).to eq('version' => '1.0')
    end
  end
end
