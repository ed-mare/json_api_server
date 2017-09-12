class PublisherSerializer < SimpleJsonApi::ResourceSerializer
  def links
    { self: File.join(base_url, "/publishers/#{@object.id}") }
  end

  def data
    {
      type: 'publishers',
      id: @object.id,
      attributes: attributes
    }
  end

  protected

  def attributes
    attributes_builder_for('publishers')
      .add('name', @object.name)
      .add('created_at', @object.created_at.try(:iso8601, 9))
      .add('updated_at', @object.updated_at.try(:iso8601, 9))
      .attributes
  end
end
