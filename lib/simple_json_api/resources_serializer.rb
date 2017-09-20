# TODO: inheritance is dubious with introduction of :type and relationship_data.
module SimpleJsonApi # :nodoc:
  # ==== Description
  #
  # Serializer for a collection/array of resources. Inherits from
  # SimpleJsonApi::ResourceSerializer.
  #
  # ==== Example
  #
  # Given a resource serializer for Topic:
  #
  #  class TopicSerializer < SimpleJsonApi::ResourceSerializer
  #   resource_type 'topics'
  #
  #    def links
  #      { self: File.join(base_url, "/topics/#{@object.id}") }
  #    end
  #
  #    def data
  #      {
  #        type: self.class.type,
  #        id: @object.id,
  #        attributes: attributes
  #      }
  #    end
  #
  #    protected
  #
  #    def attributes
  #      attributes_builder
  #        .add('book', @object.book)
  #        .add('author', @object.author)
  #        .add('quote', @object.quote)
  #        .add('character', @object.character)
  #        .add('location', @object.location)
  #        .add('published', @object.published)
  #        .add('created_at', @object.created_at.try(:iso8601, 0))
  #        .add('updated_at', @object.updated_at.try(:iso8601, 0))
  #        .attributes
  #    end
  #  end
  #
  # Create a Topics serializer like so:
  #
  #  class TopicsSerializer < SimpleJsonApi::ResourcesSerializer
  #    serializer TopicSerializer
  #  end
  #
  # Create an instance from builder:
  #
  #   builder = SimpleJsonApi::Builder.new(request, Topic.all)
  #     .add_pagination(pagination_options)
  #     .add_filter(filter_options)
  #     .add_sort(sort_options)
  #     .add_include(include_options)
  #     .add_fields
  #
  #   # populates links with pagination info, merges data from each
  #   # Topic serializer instance.
  #   serializer = TopicsSerializer.from_builder(builder)
  #
  class ResourcesSerializer < SimpleJsonApi::ResourceSerializer
    # Instance of SimpleJsonApi::Paginator or nil (default). Based on pagination
    # params. Extracted via SimpleJsonApi::Pagination and available
    # through SimpleJsonApi::Builder#paginator. Set in initializer options.
    attr_reader :paginator

    # Instance of SimpleJsonApi::Filter or nil (default). Based on filter
    # params. Extracted via SimpleJsonApi::Filter and available
    # through SimpleJsonApi::Builder#filter. Set in initializer options.
    attr_reader :filter

    class << self
      attr_reader :objects_serializer

      # A serializer class. If set,'objects' will be converted to instances of
      # this serializer.
      def serializer(klass)
        @objects_serializer = klass
      end
    end

    # * <tt>objects</tt> - An array of objects. If #serializer is specified, the
    #   objects will be converted to this class.
    # * <tt>options</tt> - Hash:
    #   * <tt>filter</tt> - Instance of SimpleJsonApi::Filter or nil. Sets #filter.
    #   * <tt>:paginator</tt> - Instance of SimpleJsonApi::Fields or nil. Sets #paginator.
    #   * <tt>:as_json_options</tt> - See options at SimpleJsonApi::BaseSerializer#as_json_options.
    def initialize(objects, **options)
      super(nil, options)
      remove_instance_variable(:@object)
      @paginator = options[:paginator]
      @filter = options[:filter]
      @objects = initalize_objects(objects)
    end

    def links
      @paginator.try(:as_json) || {}
    end

    # Subclasses override for customized behaviour.
    def data
      data = @objects.try(:map) { |o| o.try(:data) }
      data.try(:compact!) || data
    end

    # Subclasses override for customized behaviour.
    def relationship_data
      data = @objects.try(:map) { |o| o.try(:relationship_data) }
      data.try(:compact!) || data
    end

    # Subclasses override for customized behaviour.
    def included
      included = @objects.try(:map) { |o| o.try(:included) }
      included.try(:flatten!)
      included.try(:compact!) || included
    end

    protected

    def initalize_objects(objects)
      klass = self.class.objects_serializer
      if klass && objects.respond_to?(:map)
        objects.map { |object| klass.new(object, includes: includes, fields: fields) }
      else
        objects
      end
    end
  end
end
