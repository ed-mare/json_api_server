require 'spec_helper'

describe SimpleJsonApi::Errors do
  include_context 'errors shared context'

  describe '#initialize' do
    it 'accepts an error hash' do
      e = SimpleJsonApi::Errors.new(error_1_hash)
      expect(e.as_json).to eq(error_1_as_json)
    end
    it 'accepts an array of error hashes' do
      e = SimpleJsonApi::Errors.new([error_1_hash])
      expect(e.as_json).to eq(error_1_as_json)
    end
    it 'accepts nil' do
      e = SimpleJsonApi::Errors.new(nil)
      expect(e.as_json).to eq(nil_as_json)
      e1 = SimpleJsonApi::Errors.new([nil, nil])
      expect(e1.as_json).to eq(nil_as_json)
    end
  end

  describe '#as_json' do
    it 'removes non-jsonapi attributes' do
      e = SimpleJsonApi::Errors.new(error_1_hash)
      expect(e.as_json).to eq(error_1_as_json)
    end

    it 'serializes partial error attributes' do
      e = SimpleJsonApi::Errors.new(error_2_hash)
      expect(e.as_json).to eq(error_2_as_json)
    end

    it 'serializes multiple errors' do
      e = SimpleJsonApi::Errors.new([error_1_hash, error_2_hash])
      expect(e.as_json).to eq(errors_1_and_2_as_json)
    end
  end

  describe '#to_json' do
    it 'removes non-jsonapi attributes' do
      e = SimpleJsonApi::Errors.new(error_1_hash)
      expect(e.to_json).to be_same_json_as(error_1_to_json)
    end

    it 'serializes partial error attributes' do
      e = SimpleJsonApi::Errors.new(error_2_hash)
      # puts e.to_json
      expect(e.to_json).to be_same_json_as(error_2_to_json)
    end

    it 'serializes multiple errors' do
      e = SimpleJsonApi::Errors.new([error_1_hash, error_2_hash])
      expect(e.to_json).to be_same_json_as(errors_1_and_2_to_json)
    end

    it 'serializes nil to empty errors' do
      e = SimpleJsonApi::Errors.new(nil)
      expect(e.to_json).to be_same_json_as(nil_to_json)
      e1 = SimpleJsonApi::Errors.new([nil, nil])
      expect(e1.to_json).to be_same_json_as(nil_to_json)
    end
  end
end
