module JsonApiServer # :nodoc:
  # ==== Description
  #
  # Part of http://jsonapi.org/format/#fetching-includes:
  # "An endpoint may support an include request parameter to allow the client to
  # customize which related resources should be returned.""
  #
  #  ie., GET /articles/1?include=comments,comment.author,tags HTTP/1.1
  #
  # Use this class to build <tt>relationships</tt> and <tt>included</tt> sections
  # in serializers.
  #
  # ==== Examples
  #
  # Relate, relate conditionally, or relate a collection. In this example,
  # Publisher is added only if a condition is met (current user is an admin).
  #
  #  JsonApiServer::RelationshipsBuilder.new
  #    .relate('author', AuthorSerializer.new(@object.author))
  #    .relate_each('comments', @object.comments) {|c| CommentSerializer.new(c)}
  #    .relationships
  #
  #  # produces something like this if current user is an admin:
  #  # {
  #  #   "author"=>{
  #  #      {data: {type: "authors", id: 6, attributes: {first_name: "john", last_name: "Doe"}}}
  #  #   },
  #  #   "publisher"=>{
  #  #     {data: {type: "publishers", id: 1, attributes: {name: "abc"}}}
  #  #   },
  #  #   "comments"=>[
  #  #     {data: {type: "comments", id: 1, attributes: {title: "a", comment: "b"}}},
  #  #     {data: {type: "comments", id: 2, attributes: {title: "c", comment: "d"}}}
  #  #   ]
  #  # }
  #
  # <tt>relationships</tt> can include all relationship data or it can reference data in
  # <tt>included</tt>. To include and relate in one go, #include with the <tt>:relate</tt> option
  # which takes a BaseSerializer#as_json_options hash.
  #
  #  builder = JsonApiServer::RelationshipsBuilder.new
  #    .include('author', AuthorSerializer.new(@object.author),
  #        relate: { include: [:relationship_data] })
  #    .include_each('comments', @object.comments) {|c| CommentSerializer.new(c) }
  #
  #  builder.relationships
  #  # produces something like this if current user is an admin:
  #  # {
  #  #  "author" => {
  #  #    {data: {id: 6, type: "authors"}}
  #  #   },
  #  #  "publisher" => {
  #  #    {links: {self: 'http://.../publishers/1'}}
  #  #   }
  #  # }
  #
  #  builder.included
  #  # produces something like this:
  #  # [
  #  #   {type: "author", id: 6, attributes: {first_name: "john", last_name: "Doe"}},
  #  #   {type: "publisher", id: 1, attributes: {name: "abc"}},
  #  #   {type: "comments", id: 1, attributes: {title: "a", comment: "b"}},
  #  #   {type: "comments", id: 2, attributes: {title: "c", comment: "d"}}
  #  # ]
  #
  class RelationshipsBuilder
    def initialize
      @relationships = {}
      @included = []
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
      @included.uniq! if @included.respond_to?(:uniq!)
      @included
    end

    # Add relationships with this method.
    #
    # Arguments:
    #
    # - <tt>type</tt> - (String) Relationship type/name.
    # - <tt>serializer</tt> - (instance of serializer or something that responds to :as_json) Content.
    #
    # i.e.,
    #  JsonApiServer::RelationshipsBuilder.new(['comment.author'])
    #    .relate('author', author_serializer)
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
    #
    #  JsonApiServer::RelationshipsBuilder.new(['comment.author'])
    #     .relate('author', author_serializer)
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
    def relate(type, serializer)
      merge_relationship(type, serializer)
      self
    end

    # Add a collection to <tt>relationships</tt> with this method.
    #
    # Arguments:
    #
    # - <tt>type</tt> - (String) Relationship type/name.
    # - <tt>collection</tt> - Collection of objects to pass to serializer.
    # - <tt>block</tt> - Block that returns a serializer or something that repsonds_to as_json.
    #
    # i.e.,
    #  JsonApiServer::RelationshipsBuilder.new(['comments'])
    #    .relate_each('comments', @comments) { |c| CommentSerializer.new(c) }
    def relate_each(type, collection)
      collection.each { |item| relate(type, yield(item)) }
      self
    end

    # Add to <tt>included</tt> with this method.
    #
    # Arguments:
    #
    # - <tt>type</tt> - (String) Relationship type/name.
    # - <tt>serializer</tt> - (instance of serializer or something that responds to :as_json) - relationship content.
    # - <tt>options</tt> - (Hash) -
    #   - :relate (Hash) - Optional. Add to relationships. BaseSerializer#as_json_options hash, i.e, <tt>{ include: [:relationship_data] }</tt>.
    #
    # i.e.,
    #  # include and relate
    #  JsonApiServer::RelationshipsBuilder.new(['comment.author'])
    #    .include('author', author_serializer,
    #       relate: {include: [:relationship_data]})
    #
    #  # or just include
    #  JsonApiServer::RelationshipsBuilder.new(['author'])
    #     .include('author', author_serializer)
    def include(type, serializer, **options)
      merge_included(serializer)
      if options[:relate]
        serializer.as_json_options = options[:relate]
        relate(type, serializer)
      end
      self
    end

    # Add a collection to <tt>included</tt> with this method.
    #
    # Arguments:
    #
    # - <tt>type</tt> - (String) Relationship type/name.
    # - <tt>collection</tt> - Collection of objects to pass to block.
    # - <tt>options</tt> - (Hash) -
    #   - :relate (Hash) - Optional. Add to relationships. BaseSerializer#as_json_options hash, i.e, <tt>{ include: [:relationship_data] }</tt>.
    # - <tt>block</tt> - Block that returns a serializer or something that repsonds_to as_json.
    #
    # i.e.,
    #
    #  JsonApiServer::RelationshipsBuilder.new(['comments'])
    #     .include_each('comments', @comments) {|c| CommentSerializer.new(c)}
    #
    def include_each(type, collection, **options)
      collection.each { |item| include(type, yield(item), options) }
      self
    end

    protected

    def merge_relationship(type, value)
      content = value.as_json if value.respond_to?(:as_json)
      return if content.blank?

      if @relationships.key?(type)
        unless @relationships[type].is_a?(Array)
          @relationships[type] = [@relationships[type]]
        end
        @relationships[type].push(content)
      else
        @relationships.merge!(type => content)
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
