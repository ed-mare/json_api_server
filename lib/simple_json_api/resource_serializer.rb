module SimpleJsonApi # :nodoc:
  # ==== Description
  #
  # Attributes and methods intended for a single resource, i.e., topic.
  # Subclasses SimpleJsonApi::BaseSerializer.
  #
  # Example class:
  #
  #   class CommentSerializer < SimpleJsonApi::ResourceSerializer
  #     def links
  #       {
  #         self: File.join(base_url, "/comments/#{@object.id}")
  #       }
  #     end
  #
  #     def data
  #       {
  #         type: 'comments',
  #         id: @object.id,
  #         attributes: attributes,
  #         relationships: relationships.relationships
  #       }
  #     end
  #
  #     def included
  #       relationships.included
  #     end
  #
  #     protected
  #
  #     def attributes
  #       attributes_builder_for('comments')
  #         .add('title', @object.title)
  #         .add('comment', @object.comment)
  #         .add('created_at', @object.created_at.try(:iso8601, 9))
  #         .add('updated_at', @object.updated_at.try(:iso8601, 9))
  #         .attributes
  #     end
  #
  #     def relationships
  #        @relationships ||= begin
  #           relationships_builder
  #             .relate('comment.author', user_serializer(@object.author), type: 'author')
  #             .include('comment.author.include', user_serializer(@object.author),
  #                 type: 'author', relate: {include: [:links]})
  #        end
  #     end
  #   end
  #
  # Create an instance from builder:
  #
  #   topic = Topic.find(params[:id])
  #   builder = SimpleJsonApi::Builder.new(request, topic)
  #     .add_include(include_options)
  #     .add_fields
  #
  #   serializer = TopicSerializer.from_builder(builder)
  #
  class ResourceSerializer < SimpleJsonApi::BaseSerializer
    # Array. Relationships to include. Array of strings. From the
    # 'include' param. Extracted via SimpleJsonApi::Include#includes which
    # is also available through SimpleJsonApi::Builder#includes. Defaults to
    # nil. Set in initializer options.
    #
    # i.e.,
    #
    #   GET /articles?include=comments.author,publisher becomes:
    #   includes = ['comments.author', 'publisher']
    attr_reader :includes

    # Hash. Fields requested by user. From the 'fields' param. Extracted
    # via SimpleJsonApi::Fields#sparse_fields which is also available through
    # SimpleJsonApi::Builder#sparse_fields. Defaults to nil. Set in initializer
    # options.
    #
    # i.e.,
    #
    #   GET /articles?include=author&fields[articles]=title,body&fields[people]=name becomes:
    #   fields = {'articles' => ['title', 'body'], 'people' => ['name']}
    attr_reader :fields

    # * <tt>object</tt> - instance of model or presenter or whatever stores data.
    # * <tt>options</tt> - Hash (optional):
    #   * <tt>:includes</tt> - Instance of SimpleJsonApi::Include or nil. Sets #includes.
    #   * <tt>:fields</tt> - Instance of SimpleJsonApi::Fields or nil. Sets #fields.
    def initialize(object, **options)
      super(options)
      @object = object
      @includes = options[:includes]
      @fields = options[:fields]
    end

    # * <tt>:builder</tt> - Instance of SimpleJsonApi::Builder.
    # #object, #includes and #fields will be extracted from it.
    # * <tt>options</tt> - Hash, override values from Builder or set additional options.
    #   * <tt>:includes</tt> - Instance of SimpleJsonApi::Include or nil. Sets #includes.
    #   * <tt>:fields</tt> - Instance of SimpleJsonApi::Fields or nil. Sets #fields.
    #   * <tt>filter</tt> - Instance of SimpleJsonApi::Filter or nil. Sets #filter.
    #   * <tt>:paginator</tt> - Instance of SimpleJsonApi::Fields or nil. Sets #paginator.
    #   * <tt>:as_json_options</tt> - See options at SimpleJsonApi::BaseSerializer#as_json_options.
    def self.from_builder(builder, **options)
      opts = options.merge(fields: options[:fields] || builder.sparse_fields,
                           includes: options[:includes] || builder.includes,
                           paginator: options[:paginator] || builder.paginator,
                           filter: options[:filter] || builder.filter)
      new(builder.query, opts)
    end

    protected

    # Returns a new instance of SimpleJsonApi::AttributesBuilder for
    # the specified #fields <tt>type</tt>.
    #
    # * <tt>type</tt> - the resource type.
    #
    # i.e.,
    #
    #   # GET /articles?include=author&fields[articles]=title,body&fields[people]=name becomes:
    #   # fields = {'articles' => ['title', 'body'], 'people' => ['name']}
    #
    #   self.attributes_builder_for('articles')
    #     .add('title', @object.title)
    #     .add('body', @object.body)
    #     .add('created_at', @object.created_at)
    #
    def attributes_builder_for(type)
      SimpleJsonApi::AttributesBuilder.new(fields_for(type))
    end

    # Instance of SimpleJsonApi::MetaBuilder.
    #
    # i.e.,
    #
    #  self.meta_builder
    #     .add('total_records', 35)
    #  ...
    #  self.meta_builder
    #     .add('paging', 'showing 11 - 20')
    #     .meta # => { 'total_records': 35, 'paging': 'showing 11 - 20' }
    #
    def meta_builder
      @meta_builder ||= SimpleJsonApi::MetaBuilder.new
    end

    # Returns instance of SimpleJsonApi::RelationshipsBuilder.
    #
    # i.e.,
    #
    #  self.relationships_builder
    #     .relate(...)
    #     .relate_if(...)
    #     .relate_each(...)
    #  ...
    #  self.relationships_builder
    #     .include(...)
    #     .include_if(...)
    #     .include_each(...)
    #
    #  self.relationships_builder.relationships # get relationships section
    #  self.relationships_builder.included # get included section
    def relationships_builder
      @relationships_builder ||= SimpleJsonApi::RelationshipsBuilder.new(@includes)
    end

    # Returns the fields for a specific type. i.e., fields_for('articles') or nil
    # if type doesn't exist or fields is nil.
    def fields_for(type)
      @fields.respond_to?(:key) ? @fields[type.to_s] : nil
    end
  end
end
