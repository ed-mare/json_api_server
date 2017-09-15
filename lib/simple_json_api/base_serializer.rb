module SimpleJsonApi # :nodoc:
  # === Description
  #
  # Base JSON API serializer for this gem. Based on spec document structure:
  # http://jsonapi.org/format/#document-structure. Classes should inherit and override.
  # ResourceSerializer and ResourcesSerializer inherit from this class.
  #
  # Consists of 4 methods (#links, #data, #included, #meta) which create
  # the following document structure. The 4 methods should return data
  # that is serializable to JSON.
  #
  #   {
  #    ":jsonapi": {
  #      ":version": "1.0"
  #    },
  #    ":links": null,
  #    ":data": null,
  #    ":included": null,
  #    ":meta": null
  #   }
  #
  # Example class:
  #
  #   class CommentSerializer < SimpleJsonApi::BaseSerializer
  #     def initialize(object, **options)
  #       super(options)
  #       @object = object
  #     end
  #
  #     def links
  #       {
  #         self: File.join(base_url, "/comments/#{@object.id}")
  #       }
  #     end
  #
  #     def data
  #       {
  #         "type": "comments",
  #         "id": "12",
  #         "attributes": {
  #           "comment": @object.comment,
  #           "created_at": @object.created_at,
  #           "updated_at": @object.created_at,
  #         },
  #         "relationships": {
  #           "author": {
  #             "links": {"self": "http://example.com/people/#{@object.author_id}"},
  #             "data": {"id": @object.author_id, "type": "people"}
  #           }
  #         }
  #       }
  #     end
  #   end
  #
  # Sometimes only part of document is needed, for example, when embedding one serializer in another.
  # <tt>as_json</tt> takes an optional hash argument which determines which parts of the document to return.
  # These options can also be set in the #as_json_options attribute.
  #
  #  serializer.as_json(include: [:data]) # => { data: {...} }
  #  serializer.as_json(include: [:links]) # => { links: {...} }
  #  serializer.as_json(include: [:data, :links]) # =>
  #  # {
  #  #   links: {...},
  #  #   data: {...}
  #  # }
  #  serializer.as_json(include: [:relationship_data]) # =>
  #  # {
  #  #   data: {
  #  #      # data element minus the attributes section.
  #  #   }
  #  # }
  #
  # <tt>base_url</tt> -- is SimpleJsonApi::Configuration#base_url exposed as a protected
  # method. For creating links.
  class BaseSerializer
    include SimpleJsonApi::Serializer
    include SimpleJsonApi::ApiVersion

    # Hash. as_json options. Same options can be passed into #as_json.
    # Defaults to nil. When not set, all sections are rendered.
    #
    # Possible options:
    #
    # <tt>:include</tt> (Array) -- Optional. Possible values: :jsonapi, :links, :data,
    # :included, :meta and :relationship_data. :relationship_data is a special case --
    # if present in the array, only relationship data is rendered (data section w/o
    # attributes).
    #
    # i.e,
    #
    #   # Set attribute
    #   serializer.as_json_options = { include: [:data] }
    #   serializer.as_json_options = { include: [:data, :links] }
    #   serializer.as_json_options = { include: [:relationship_data] }
    #
    #   # Or set when calling #as_json
    #   serializer.as_json(include: [:data])
    attr_accessor :as_json_options

    def initialize(**options)
      @as_json_options = options[:as_json_options]
    end

    # JSON API *links* section. Subclass implements.
    # Api spec: http://jsonapi.org/format/#document-links
    def links
      nil
    end

    # JSON API *data* section. Subclass implements.
    # Api spec: http://jsonapi.org/format/#document-structure
    def data
      nil
    end

    # JSON to render with #as_json_option :relationship_data. Subclass implements.
    # Api spec: http://jsonapi.org/format/#fetching-relationships
    def relationship_data
      nil
    end

    # JSON API *included* section. Sublclass implements.
    # Api spec: http://jsonapi.org/format/#fetching-includes
    def included
      nil
    end

    # JSON API *meta* section. Sublclass implements.
    # Api spec: http://jsonapi.org/format/#document-meta
    def meta
      nil
    end

    # Creates the following document structure by default. See #as_json_options for
    # a description of options. The hash is with indifferent access.
    #   {
    #    "jsonapi" => {
    #      "version" => "1.0"
    #    },
    #    "links" => null,
    #    "data" => null,
    #    "included" => null,
    #    "meta" => null
    #   }
    def as_json(**options)
      opts = (options.any? ? options : as_json_options) || {}
      sections = opts[:include] || %w[jsonapi links data included meta]
      hash = {}

      if sections.include?(:relationship_data)
        hash['data'] = relationship_data
      else
        sections.each { |s| hash[s] = send(s) if sections.include?(s) }
      end

      ActiveSupport::HashWithIndifferentAccess.new(hash)
    end

    protected

    # Configuration base_url.
    def base_url
      SimpleJsonApi.configuration.base_url
    end
  end
end
