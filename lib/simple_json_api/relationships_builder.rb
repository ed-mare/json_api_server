module SimpleJsonApi # :nodoc:
  # ==== Description
  #
  # Part of http://jsonapi.org/format/#fetching-includes:
  # "An endpoint may support an include request parameter to allow the client to
  # customize which related resources should be returned.""
  #
  #  ie., GET /articles/1?include=comments,comment.author,tags HTTP/1.1
  #
  # Use this class to build <tt>relationships</tt> and <tt>included</tt> sections
  # in serializers. It will add a relationship/include if it exists in the
  # #includes array (see #includes attribute).
  #
  # ==== Examples
  #
  # Relate, relate conditionally, or relate a collection. In this example, <tt>author</tt> is not
  # added because it's not in <tt>includes</tt>. Publisher is added only
  # if a condition is met (current user is an admin).
  #
  #  builder = SimpleJsonApi::RelationshipsBuilder.new(['comments', 'publisher'])
  #  builder.includes # => ['comments', 'publisher']
  #
  #  builder
  #    .relate('author', AuthorSerializer.new(@object.author))
  #    .relate_if('publisher', PublisherSerializer.new(@object.publisher),
  #         -> { current_user.admin? })
  #    .relate_each('comments', @object.comments) {|c| CommentSerializer.new(c)}
  #    .relationships
  #
  #  # produces something like this if current user is an admin:
  #  # {
  #  #   "comments"=>[
  #  #     {data: {type: "comments", id: 1, attributes: {title: "a", comment: "b"}}},
  #  #     {data: {type: "comments", id: 2, attributes: {title: "c", comment: "d"}}}
  #  #   ],
  #  #   "publisher"=>{
  #  #     {data: {type: "publishers", id: 1, attributes: {name: "abc"}}}
  #  #   }
  #  # }
  #
  # <tt>relationships</tt> can include all relationship data or it can reference data in
  # <tt>included</tt>. To include and relate in one go, #include with the <tt>:relate</tt> option
  # which takes a BaseSerializer#as_json_options hash.
  #
  #  builder = SimpleJsonApi::RelationshipsBuilder.new(['comments', 'publisher'])
  #  builder.includes # => ['comments', 'publisher']
  #
  #  builder
  #    .include('author', AuthorSerializer.new(@object.author),
  #        relate: { include: [:relationship_data] })
  #    .include_if('publisher', PublisherSerializer.new(@object.publisher),
  #        -> { current_user.admin? }, relate: { include: [:links] })
  #    .include_each('comments', @object.comments) {|c| CommentSerializer.new(c) }
  #
  #  builder.relationships
  #  # produces something like this if current user is an admin (relationship data):
  #  # {
  #  #  "publisher" => {
  #  #    {data: {type: "publishers", id: 1}}
  #  #   }
  #  # }
  #
  #  builder.included
  #  # produces something like this:
  #  # [
  #  #   {type: "publisher", id: 1, attributes: {name: "abc"}},
  #  #   {type: "comments", id: 1, attributes: {title: "a", comment: "b"}},
  #  #   {type: "comments", id: 2, attributes: {title: "c", comment: "d"}}
  #  # ]
  #
  class RelationshipsBuilder
    # (Array) Whitelisted includes. Should come from SimpleJsonApi::Include#includes.
    # From <tt>includes</tt> constructor parameter.
    attr_reader :includes

    # Arguments:
    #
    # - <tt>includes</tt> - (Array) Array of whitelisted includes (array of strings). Defaults to empty array.
    def initialize(includes = [])
      @relationships = {}
      @included = []
      @includes = includes.is_a?(Array) ? includes : []
    end

    # Returns <tt>relationships</tt> object. Relationships added with
    # #relate, #relate_if, #relate_each and #include (with <tt>:relate</tt> option).
    def relationships
      @relationships.each do |k, v|
        if v.respond_to?(:uniq!)
          v.uniq!
          @relationships[k] = v.first if v.length == 1
        end
      end
      @relationships
    end

    # Returns <tt>included</tt> object. Includes added with
    # #include, #include_if, #include_each.
    def included
      @included.uniq! if @included.respond_to?(:uniq)
      @included
    end

    # Add relationships with this method. Adds only if <tt>relationship</tt> is in #includes.
    #
    # Arguments:
    #
    # - <tt>relationship</tt> - (String) Relationship passed in with the request.
    # - <tt>serializer</tt> - (instance of serializer or something that responds to :as_json) Content.
    # - <tt>options</tt> - (Hash) -
    #   - :type (String) - Optional. <tt>type</tt> to use in relationships. <tt>type</tt> defaults to #relationship parameter.
    #
    # i.e.,
    #  SimpleJsonApi::RelationshipsBuilder.new(['comment.author'])
    #     .relate('comment.author', author_serializer)
    #
    #  # outputs something like...
    #  # { 'comment.author' => {
    #  #  :data => {
    #  #     :type => "people",
    #  #    :id => 6,
    #  #     :attributes => {:first_name=>"John", :last_name=>"Steinbeck"}
    #  #     }
    #  #   }
    #  # }
    #
    #  SimpleJsonApi::RelationshipsBuilder.new(['comment.author'])
    #     .relate('comment.author', author_serializer, type: 'author')
    #
    #  # outputs something like...
    #  # { 'author' => {
    #  #  :data => {
    #  #     :type => "people",
    #  #    :id => 6,
    #  #     :attributes => {:first_name=>"John", :last_name=>"Steinbeck"}
    #  #     }
    #  #   }
    #  # }
    def relate(relationship, serializer, **options)
      if relationship?(relationship)
        type = options[:type] || relationship
        merge_relationship(type, serializer)
      end
      self
    end

    # Add to <tt>relationships</tt> with this method. Adds if <tt>relationship</tt> is in #includes AND
    # proc returns true.
    #
    # Arguments:
    #
    # - <tt>relationship</tt> - (String) Relationship passed in with the request.
    # - <tt>serializer</tt> - (instance of serializer or something that responds to :as_json) - relationship content.
    # - <tt>proc</tt> - (Proc) - Proc that returns true or false.
    # - <tt>options</tt> - (Hash) -
    #   - :type (String) - Optional. Type to use in relationships. <tt>type</tt> defaults to #relationship parameter.
    #
    # i.e.,
    #  SimpleJsonApi::RelationshipsBuilder.new(['comment.author'])
    #     .relate_if('comment.author', author_serializer, -> { 1 == 1 })
    def relate_if(relationship, serializer, proc, **_options)
      relate(relationship, serializer) if proc.call == true
      self
    end

    # Add a collection to <tt>relationships</tt> with this method. Adds if <tt>relationship</tt> is in #includes.
    #
    # Arguments:
    #
    # - <tt>relationship</tt> - (String) Relationship passed in with the request.
    # - <tt>collection</tt> - Collection of objects to pass to serializer.
    # - <tt>options</tt> - (Hash) -
    #   - :type (String) - Optional. Type to use in relationships. <tt>type</tt> defaults to #relationship parameter.
    # - <tt>block</tt> - Block that returns a serializer or something that repsonds_to as_json.
    #
    # i.e.,
    #  SimpleJsonApi::RelationshipsBuilder.new(['comments'])
    #     .relate_each('comments', @comments) { |c| CommentSerializer.new(c) }
    def relate_each(relationship, collection, **options)
      collection.each { |item| relate(relationship, yield(item), options) }
      self
    end

    # Add to <tt>included</tt> with this method. Adds if <tt>relationship</tt> is in #includes.
    #
    # Arguments:
    #
    # - <tt>relationship</tt> - (String) Relationship passed in with the request.
    # - <tt>serializer</tt> - (instance of serializer or something that responds to :as_json) - relationship content.
    # - <tt>options</tt> - (Hash) -
    #   - :relate (Hash) - Optional. Add to relationships. BaseSerializer#as_json_options hash, i.e, <tt>{ include: [:relationship_data] }</tt>.
    #   - :type (String) - Optional. Type to use in relationships. <tt>type</tt> defaults to #relationship parameter.
    #
    # i.e.,
    #  # include and relate
    #  SimpleJsonApi::RelationshipsBuilder.new(['comment.author'])
    #     .include('comment.author', author_serializer,
    #          relate: {include: [:relationship_data]}, type: 'author')
    #
    #  # or just include
    #  SimpleJsonApi::RelationshipsBuilder.new(['author'])
    #     .include('author', author_serializer)
    def include(relationship, serializer, **options)
      if relationship?(relationship)
        merge_included(serializer)
        if options[:relate]
          serializer.as_json_options = options[:relate]
          relate(relationship, serializer, options)
        end
      end
      self
    end

    # Adds to <tt>included</tt> if proc returns true and <tt>relationship</tt> is in #includes.
    #
    # Arguments:
    #
    # - <tt>relationship</tt> - (String) Relationship passed in with the request.
    # - <tt>serializer</tt> - (instance of serializer or something that responds to :as_json) - relationship content.
    # - <tt>proc</tt> - (Proc) - Proc that returns true or false.
    # - <tt>options</tt> - (Hash) -
    #   - :relate (Hash) - Optional. Add to relationships. BaseSerializer#as_json_options hash, i.e, <tt>{ include: [:relationship_data] }</tt>.
    #   - :type (String) - Optional. Type to use in relationships. <tt>type</tt> defaults to #relationship parameter.
    #
    # i.e.,
    #  SimpleJsonApi::RelationshipsBuilder.new(['author'])
    #     .include_if('author', author_serializer, -> { 1 == 2 })
    def include_if(relationship, serializer, proc, **options)
      include(relationship, serializer, options) if proc.call == true
      self
    end

    # Add a collection to <tt>included</tt> with this method. Adds if <tt>relationship</tt> is in #includes.
    #
    # Arguments:
    #
    # - <tt>relationship</tt> - (String) Relationship passed in with the request.
    # - <tt>collection</tt> - Collection of objects to pass to block.
    # - <tt>options</tt> - (Hash) -
    #   - :relate (Hash) - Optional. Add to relationships. BaseSerializer#as_json_options hash, i.e, <tt>{ include: [:relationship_data] }</tt>.
    #   - :type (String) - Optional. Type to use in relationships. <tt>type</tt> defaults to #relationship parameter.
    # - <tt>block</tt> - Block that returns a serializer or something that repsonds_to as_json.
    #
    # i.e.,
    #
    #  SimpleJsonApi::RelationshipsBuilder.new(['comments'])
    #     .include_each('comments', @comments) {|c| CommentSerializer.new(c)}
    #
    def include_each(relationship, collection, **options)
      collection.each { |item| include(relationship, yield(item), options) }
      self
    end

    # Returns true if relationship is in #includes array.
    #
    # * <tt>relationship</tt> - Name of relationship. String or symbol.
    #
    # i.e.,
    #
    #   # GET /articles?include=comment.author,publisher becomes:
    #   # includes = ['comment.author', 'publisher']
    #
    #   self.relationship?('comment.author') # => true
    #   self.relationship?('addresses') # => false
    def relationship?(relationship)
      @includes.respond_to?(:include?) && @includes.include?(relationship.to_s)
    end

    protected

    def merge_relationship(relationship, value)
      content = value.as_json if value.respond_to?(:as_json)
      return if content.blank?

      if @relationships.key?(relationship)
        unless @relationships[relationship].is_a?(Array)
          @relationships[relationship] = [@relationships[relationship]]
        end
        @relationships[relationship].push(content)
      else
        @relationships.merge!(relationship => content)
      end
    end

    def merge_included(value)
      if value.respond_to?(:as_json)
        content = value.respond_to?(:as_json_options) ? value.as_json(include: [:data]) : value.as_json
        @included.push(content[:data]) if content.present?
      end
    end
  end
end
