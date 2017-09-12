RSpec.shared_context 'errors shared context' do
  let(:error_1_hash) do
    {
      'id' => 1504,
      'status' => '422',
      'code' => 5,
      'source' => { 'pointer' => '/data/attributes/first-name' },
      'title' => 'Invalid Attribute',
      'detail' => 'First name must contain at least three characters.',
      'meta' => { 'attrs' => [1, 2, 3] },
      'links' => { 'self' => 'http://example.com/user' },
      'ignore_me' => {
        'attr' => "shouldn't be here"
      }
    }
  end

  let(:error_1_as_json) do
    {
      'jsonapi' => {
        'version' => '1.0'
      },
      'errors' => [{
        'id' => 1504,
        'status' => '422',
        'code' => 5,
        'source' => { 'pointer' => '/data/attributes/first-name' },
        'title' => 'Invalid Attribute',
        'detail' => 'First name must contain at least three characters.',
        'meta' => { 'attrs' => [1, 2, 3] },
        'links' => { 'self' => 'http://example.com/user' }
      }]
    }
  end

  let(:error_1_to_json) do
    '{
      "jsonapi": {
        "version": "1.0"
      },
      "errors": [{
        "id": 1504,
        "status": "422",
        "code": 5,
        "source": {
          "pointer": "/data/attributes/first-name"
        },
        "title": "Invalid Attribute",
        "detail": "First name must contain at least three characters.",
        "meta": {
          "attrs": [1,2,3]
        },
        "links": {
          "self": "http://example.com/user"
        }
      }]
    }'
  end

  let(:error_2_hash) do
    {
      'status' => '422',
      'source' => { 'pointer' => '/data/attributes/sandwich' },
      'title' => 'Invalid Attribute',
      'detail' => 'A sandwich requires two pieces of bread.'
    }
  end

  let(:error_2_as_json) do
    {
      'jsonapi' => {
        'version' => '1.0'
      },
      'errors' => [{
        'status' => '422',
        'source' => { 'pointer' => '/data/attributes/sandwich' },
        'title' => 'Invalid Attribute',
        'detail' => 'A sandwich requires two pieces of bread.'
      }]
    }
  end

  let(:error_2_to_json) do
    '
      {
        "jsonapi": {
          "version": "1.0"
        },
        "errors": [
          {
            "status": "422",
            "source": {
              "pointer": "/data/attributes/sandwich"
            },
            "title": "Invalid Attribute",
            "detail": "A sandwich requires two pieces of bread."
          }
        ]
      }
    '
  end

  let(:nil_as_json) do
    {
      'jsonapi' => {
        'version' => '1.0'
      },
      'errors' => []
    }
  end

  let(:nil_to_json) do
    '
      {
        "jsonapi": {
          "version": "1.0"
        },
        "errors": []
      }
    '
  end

  let(:errors_1_and_2_as_json) do
    {
      'jsonapi' => {
        'version' => '1.0'
      },
      'errors' => [
        {
          'id' => 1504,
          'status' => '422',
          'code' => 5,
          'source' => { 'pointer' => '/data/attributes/first-name' },
          'title' => 'Invalid Attribute',
          'detail' => 'First name must contain at least three characters.',
          'meta' => { 'attrs' => [1, 2, 3] },
          'links' => { 'self' => 'http://example.com/user' }
        },
        {
          'status' => '422',
          'source' => { 'pointer' => '/data/attributes/sandwich' },
          'title' => 'Invalid Attribute',
          'detail' => 'A sandwich requires two pieces of bread.'
        }
      ]
    }
  end

  let(:errors_1_and_2_to_json) do
    '{
      "jsonapi": {
        "version": "1.0"
      },
      "errors": [{
        "id": 1504,
        "status": "422",
        "code": 5,
        "source": {
          "pointer": "/data/attributes/first-name"
        },
        "title": "Invalid Attribute",
        "detail": "First name must contain at least three characters.",
        "meta": {
          "attrs": [1,2,3]
        },
        "links": {
          "self": "http://example.com/user"
        }
      },
      {
        "status": "422",
        "source": { "pointer": "/data/attributes/sandwich" },
        "title": "Invalid Attribute",
        "detail": "A sandwich requires two pieces of bread."
      }]
    }'
  end
end
