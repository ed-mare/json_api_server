# Model serailizer for Topic. Inherit from JsonApiServer::BaseSerializer.
class TopicSerializer < JsonApiServer::ResourceSerializer
  resource_type 'topics'

  def links
    { self: File.join(base_url, "/topics/#{@object.id}") }
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
      .add_multi(@object, 'book', 'author', 'quote', 'character', 'location', 'published')
      .add('created_at', @object.created_at.try(:iso8601, 0))
      .add('updated_at', @object.updated_at.try(:iso8601, 0))
      .attributes
  end

  def inclusions
    @inclusions ||= begin
      rb.relate('publisher', publisher_serializer(@object.publisher)) if
        relationship?('publisher')
      if relationship?('comments')
        rb.relate_each('comments', @object.comments) { |c| comment_serializer(c) }
      elsif relationship?('comments.includes')
        rb.include_each('comments', @object.comments, relate: { include: [:relationship_data] }) { |c| comment_serializer(c) }
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
