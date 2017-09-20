module JsonApiServer # :nodoc:
  # For one or more errors: http://jsonapi.org/examples/#error-objects.
  #
  # Serializes to an arrray of errors. Skips attributes that are nil. Ignores
  # non-jsonapi attributes.
  #
  #  error.to_json
  #  {
  #   ":jsonapi": {
  #     ":version": "1.0"
  #   },
  #   ":errors": [{
  #     ":id": 1234
  #     ":status": "422",
  #     ":code": 5,
  #     ":source": {
  #       ":pointer": "/data/attributes/first-name"
  #     },
  #     ":title": "Invalid Attribute",
  #     ":detail": "First name must contain at least three characters.",
  #     ":meta": {
  #       ":attrs": [1,2,3]
  #     },
  #     ":links": {
  #       ":self": "http://example.com/user"
  #     }
  #   }]
  #  }
  # Use for singular or multiple errors.
  class Errors
    include JsonApiServer::Serializer
    include JsonApiServer::ApiVersion

    def initialize(errors)
      errors = errors.is_a?(Array) ? errors : [errors]
      @errors = errors.map do |error|
        JsonApiServer::Error.new(error).error
      end
      @errors.compact!
      @errors
    end

    def as_json
      {
        'jsonapi' => jsonapi,
        'errors' => @errors
      }
    end
  end
end
