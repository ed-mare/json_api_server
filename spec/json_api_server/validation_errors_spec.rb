require 'spec_helper'
require 'active_model'

describe JsonApiServer::ValidationErrors do
  let(:model) do
    class MyModel
      include ActiveModel::Validations
      attr_accessor :first_name, :last_name
      validates :first_name, :last_name, presence: true
      validates :first_name, inclusion: ['Sam']
    end
    model = MyModel.new
    model.valid?
    model
  end

  describe '#as_json' do
    it 'returns one validation error per attribute' do
      e = JsonApiServer::ValidationErrors.new(model)
      expect(model.errors[:first_name].length).to eq(2)
      expect(model.errors[:last_name].length).to eq(1)

      expect(e.as_json).to eq(
        'jsonapi' => { 'version' => '1.0' },
        'errors' =>  [
          {
            'status' => '422',
            'source' => { 'pointer' => '/data/attributes/first_name' },
            'title' => 'Invalid Attribute',
            'detail' => "First name can't be blank"
          },
          {
            'status' => '422',
            'source' => { 'pointer' => '/data/attributes/last_name' },
            'title' => 'Invalid Attribute',
            'detail' => "Last name can't be blank"
          }
        ]
      )
    end

    it 'returns no errors (empty array) when no validation errors' do
      sam = MyModel.new.tap do |u|
        u.first_name = 'Sam'
        u.last_name = 'Spade'
      end
      expect(sam.valid?).to eq(true)
      e = JsonApiServer::ValidationErrors.new(sam)
      expect(e.as_json).to eq(
        'jsonapi' => { 'version' => '1.0' },
        'errors' =>  []
      )
    end

    it 'returns no errors (empty array) when object is not model' do
      e = JsonApiServer::ValidationErrors.new(nil)
      expect(e.as_json).to eq(
        'jsonapi' => { 'version' => '1.0' },
        'errors' => []
      )
    end
  end

  describe '#to_json' do
    it 'returns one validation error per attribute' do
      e = JsonApiServer::ValidationErrors.new(model)
      # puts e.to_json
      expect(e.to_json).to be_same_json_as(
        %q({
          "jsonapi": {
            "version": "1.0"
          },
          "errors": [
            {
              "status": "422",
              "source": {
                "pointer": "/data/attributes/first_name"
              },
              "title": "Invalid Attribute",
              "detail": "First name can't be blank"
            },
            {
              "status": "422",
              "source": {
                "pointer": "/data/attributes/last_name"
              },
              "title": "Invalid Attribute",
              "detail": "Last name can't be blank"
            }
          ]
        })
      )
    end

    it 'returns no errors (empty array) when no validation errors' do
      sam = MyModel.new.tap do |u|
        u.first_name = 'Sam'
        u.last_name = 'Spade'
      end
      expect(sam.valid?).to eq(true)
      e = JsonApiServer::ValidationErrors.new(sam)
      expect(e.to_json).to be_same_json_as('
        {
          "jsonapi": {
            "version": "1.0"
          },
          "errors": []
        }
      ')
    end
  end
end
