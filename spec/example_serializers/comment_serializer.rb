class CommentSerializer < SimpleJsonApi::ResourceSerializer
  def links
    { self: File.join(base_url, "/comments/#{@object.id}") }
  end

  def data
    {
      type: 'comments',
      id: @object.id,
      attributes: attributes,
      relationships: relationships.relationships
    }
  end

  def included
    relationships.included
  end

  protected

  def attributes
    attributes_builder_for('comments')
      .add('title', @object.title)
      .add('comment', @object.comment)
      .add('created_at', @object.created_at.try(:iso8601, 9))
      .add('updated_at', @object.updated_at.try(:iso8601, 9))
      .attributes
  end

  def relationships
    @relationships ||= begin
      relationships_builder
        .relate('comment.author', user_serializer(@object.author), type: 'author')
        .include('comment.author.links', user_serializer(@object.author),
                 type: 'author', relate: { include: [:links] })
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
