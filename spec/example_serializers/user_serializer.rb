class UserSerializer < JsonApiServer::ResourceSerializer
  resource_type 'users'

  def links
    { self: File.join(base_url, "/users/#{@object.id}") }
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
      .add_multi(@object, 'email', 'first_name', 'last_name')
      .add('created_at', @object.created_at.try(:iso8601, 0))
      .add('updated_at', @object.updated_at.try(:iso8601, 0))
      .attributes
  end
end
