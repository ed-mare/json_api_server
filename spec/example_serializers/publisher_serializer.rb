class PublisherSerializer < SimpleJsonApi::ResourceSerializer
  resource_type 'publishers'

  def links
    { self: File.join(base_url, "/publishers/#{@object.id}") }
  end

  def data
    {
      type: self.class.type,
      id: @object.id,
      attributes: attributes
    }
  end

  protected

  def attributes
    attributes_builder
      .add('name', @object.name)
      .add('created_at', @object.created_at.try(:iso8601, 9))
      .add('updated_at', @object.updated_at.try(:iso8601, 9))
      .attributes
  end
end
