require 'spec_helper'

describe SimpleJsonApi do
  describe 'VERSION' do
    it 'has a version number' do
      expect(SimpleJsonApi::VERSION).not_to be nil
    end
  end
end
