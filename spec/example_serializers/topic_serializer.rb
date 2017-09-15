# Model serailizer for Topic. Inherit from SimpleJsonApi::BaseSerializer.
class TopicSerializer < SimpleJsonApi::ResourceSerializer
  set_type 'topics'

  def links
    { self: File.join(base_url, "/topics/#{@object.id}") }
  end

  def data
    Hash.new.tap do |h|
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
    attributes_builder_for(self.class.type)
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
