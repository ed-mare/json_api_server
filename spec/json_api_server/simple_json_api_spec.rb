require 'spec_helper'

describe JsonApiServer do
  describe 'VERSION' do
    it 'has a version number' do
      expect(JsonApiServer::VERSION).not_to be nil
    end
  end
end
