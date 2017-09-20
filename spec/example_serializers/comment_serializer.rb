class CommentSerializer < JsonApiServer::ResourceSerializer
  resource_type 'comments'

  def links
    { self: File.join(base_url, "/comments/#{@object.id}") }
  end

  def data
    {}.tap do |h|
      h['type'] = self.class.type
      h['id'] = @object.id
      h['attributes'] = attributes
      h['relationships'] = inclusions.relationships if inclusions?
    end
  end

  def included
    inclusions.included if inclusions?
  end

  protected

  def attributes
    attributes_builder
      .add('title', @object.title)
      .add('comment', @object.comment)
      .add('created_at', @object.created_at.try(:iso8601, 9))
      .add('updated_at', @object.updated_at.try(:iso8601, 9))
      .attributes
  end

  def inclusions
    @inclusions ||= begin
      relationships_builder.relate('author', user_serializer(@object.author)) if
        relationship?('comment.author')
      if relationship?('comment.author.links')
        relationships_builder.include('author', user_serializer(@object.author),
                                      relate: { include: [:links] })
      end
      relationships_builder
    end
  end

  def user_serializer(user, as_json_options = { include: [:data] })
    ::UserSerializer.new(
      user,
      includes: includes,
      fields: fields,
      as_json_options: as_json_options
    )
  end
end
