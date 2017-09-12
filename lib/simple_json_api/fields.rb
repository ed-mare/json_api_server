module SimpleJsonApi # :nodoc:
  # ==== Description:
  #
  # Implements sparse fieldsets per JSON API spec http://jsonapi.org/format/#fetching-sparse-fieldsets.
  # Spec states: "A client MAY request that an endpoint return only specific fields in
  # the response on a per-type basis by including a fields[TYPE] parameter."
  #
  # This class extracts sparse fields and organizes them by 'type' which is associated with a
  # a serializer. There is no whitelisting. It's assumed the serializer or view controls which
  # fields to return.
  #
  # === Usage:
  #
  # A sparse fields request look like:
  #    /articles?include=author&fields[articles]=title,body,author&fields[people]=name
  #
  # This is converted to a hash:
  #  {
  #    'articles' => ['title', 'body', 'author'],
  #    'people' => ['name']
  #  }
  #
  # ==== Examples:
  #
  # Given request:
  # <tt>articles?include=author&fields[articles]=title,body,author&fields[people]=name</tt>
  #
  #  req = SimpleJsonApi::Fields.new(request)
  #  req.sparse_fields # => {'articles => ['title', 'body', 'author'], 'people' => ['name']}
  #
  # Given request: <tt>/articles</tt>
  #
  #  req = SimpleJsonApi::Fields.new(request)
  #  req.sparse_fields # => nil
  #
  # ==== Note:
  #
  # - SimpleJsonApi::AttributesBuilder provides methods for using this class in serializers or views.
  # - SimpleJsonApi::Builder class provides an easier way to use this class.
  #
  class Fields
    # Controller request object.
    attr_reader :request

    # Query parameters from #request.
    attr_reader :params

    # Arguments:
    #
    # - <tt>request</tt> - ActionDispatch::Request object.
    # - <tt>options</tt> (Hash) - Reserved but not used.
    def initialize(request, **_options)
      @request = request
      @params = request.query_parameters
    end

    # nil when there are no sparse fields in the request. Otherwise,
    # returns a hash of format:
    #   {'<type>' => ['<field name 1>', '<field name 2>', ... ], ...}.
    def sparse_fields
      @sparse_fields ||= begin
        return nil unless @params[:fields].respond_to?(:key)
        hash = @params[:fields].each_with_object({}) do |(k, v), sum|
          sum[k.to_s] = convert(v) if v.present? && v.respond_to?(:split)
        end
        hash.any? ? hash : nil
      end
    end

    protected

    def convert(string)
      string.split(',').map!(&:strip)
    end
  end
end
