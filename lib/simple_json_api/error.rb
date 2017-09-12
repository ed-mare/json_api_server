module SimpleJsonApi # :nodoc:
  # Implements a single error based on spec: http://jsonapi.org/examples/#error-objects.
  #
  # Serializes to something like this. Skips attributes that are nil. Ignores
  # non-jsonapi attributes.
  #  error.to_json =>
  #
  #  {
  #    ":jsonapi": {
  #      ":version": "1.0"
  #    },
  #    ":errors": {
  #      ":id": 1234
  #      ":status": "422",
  #      ":code": 5,
  #      ":source": {
  #        ":pointer": "/data/attributes/first-name"
  #      },
  #      ":title": "Invalid Attribute",
  #      ":detail": "First name must contain at least three characters.",
  #      ":meta": {
  #        ":attrs": [1,2,3]
  #      },
  #      ":links": {
  #        ":self": "http://example.com/user"
  #     }
  #   }
  #  }
  class Error
    include SimpleJsonApi::Serializer
    include SimpleJsonApi::ApiVersion

    class << self
      # Allowable error attributes.
      attr_accessor :error_attrs
    end

    @error_attrs = %w[id status source title detail code meta links]

    def initialize(attrs = {})
      @error =
        if attrs.respond_to?(:keys)
          h = attrs.select { |k, _v| self.class.error_attrs.include?(k.to_s) }
          h.empty? ? nil : h
        end
    end

    attr_reader :error

    # Object that's serializable to json.
    def as_json
      {
        'jsonapi' => jsonapi,
        'errors' => error_as_array
      }
    end

    protected

    def error_as_array
      [@error].compact
    end
  end
end
