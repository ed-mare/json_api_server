class UserSerializer < SimpleJsonApi::ResourceSerializer
  def links
    { self: File.join(base_url, "/users/#{@object.id}") }
  end

  def data
    {
      type: 'users',
      id: @object.id,
      attributes: attributes
    }
  end

  protected

  def attributes
    attributes_builder_for('users')
      .add('email', @object.email)
      .add('first_name', @object.first_name)
      .add('last_name', @object.last_name)
      .add('created_at', @object.created_at.try(:iso8601, 9))
      .add('updated_at', @object.updated_at.try(:iso8601, 9))
      .attributes
  end
end
