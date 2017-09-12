require 'rails_helper' # need model to test.

describe SimpleJsonApi::Fields do
  let(:request) do
    FakeRequest.new(fields: {
                      comments: 'title,comment',
                      users: 'email,first_name,last_name'
                    })
  end
  let(:request_nils) do
    FakeRequest.new(fields: {
                      author: ' ',
                      addresses: nil
                    })
  end
  let(:request_none_requested) { FakeRequest.new({}) }

  describe '#sparse_fields' do
    it "is a hash of format {'type' => ['field', 'field', ...]}" do
      r = SimpleJsonApi::Fields.new(request)
      expect(r.sparse_fields).to eq('comments' => %w[title comment],
                                    'users' => %w[email first_name last_name])
    end

    it 'ignores blank strings and nil' do
      r = SimpleJsonApi::Fields.new(request_nils)
      expect(r.sparse_fields).to eq(nil)
    end

    it 'is nil when no sparse fields are requested' do
      r = SimpleJsonApi::Fields.new(request_none_requested)
      expect(r.sparse_fields).to eq(nil)
    end
  end
end
