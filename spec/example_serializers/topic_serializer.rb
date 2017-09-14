# Model serailizer for Topic. Inherit from SimpleJsonApi::BaseSerializer.
class TopicSerializer < SimpleJsonApi::ResourceSerializer
  def links
    { self: File.join(base_url, "/topics/#{@object.id}") }
  end

  def data
    {
      type: 'topics',
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
    attributes_builder_for('topics')
      .add('book', @object.book)
      .add('author', @object.author)
      .add('quote', @object.quote)
      .add('character', @object.character)
      .add('location', @object.location)
      .add('published', @object.published)
      .add('created_at', @object.created_at.try(:iso8601, 9))
      .add('updated_at', @object.updated_at.try(:iso8601, 9))
      .attributes
  end

  def relationships
    @relationships ||= begin
      if relationship?('publisher')
        rb.relate('publisher', publisher_serializer(@object.publisher))
      end
      if relationship?('comments')
        rb.relate_each('comments', @object.comments) { |c| comment_serializer(c) }
      elsif relationship?('comments.includes')
        rb.include_each('comments.includes', @object.comments, type: 'comments',
                                                               relate: { include: [:relationship_data] }) { |c| comment_serializer(c) }
      end
      rb
    end
  end

  def publisher_serializer(publisher, as_json_options = nil)
    ::PublisherSerializer.new(publisher, includes: includes, fields: fields,
                                         as_json_options: as_json_options || { include: [:data] })
  end

  def comment_serializer(comment, as_json_options = nil)
    ::CommentSerializer.new(comment, includes: includes, fields: fields,
                                     as_json_options: as_json_options || { include: [:data] })
  end
end
