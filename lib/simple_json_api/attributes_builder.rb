module SimpleJsonApi # :nodoc:
  # Related to sparse fieldsets. http://jsonapi.org/format/#fetching-sparse-fieldsets
  # "A client MAY request that an endpoint return only specific fields in the response on a per-type
  # basis by including a fields[TYPE] parameter."
  #
  # Use this class to build the <tt>attributes</tt> section in JSON API
  # serializers. It will only add attributes defined in #fields (sparse fieldset).
  # If #fields is nil (no requested sparse fieldset), it will add all attributes.
  #
  # ==== Examples
  #
  # This:
  #  /articles?include=author&fields[articles]=title,body,phone&fields[people]=name
  #
  # converts to:
  #   {'articles' => ['title', 'body', 'phone'], 'people' => ['name']}
  #
  # When <tt>fields</tt> is an array, only fields in the array should be added:
  #
  #  AttributesBuilder.new(['title', 'body', 'phone'])
  #    .add('title', @record.title)
  #    .add('body',  @record.body)
  #    .add_if('phone', @record.phone, -> { admin? })  # conditionally adding
  #    .add('isbn', @record.isbn)  # not in sparse fields array
  #    .attributes
  #
  #    # when non-admin
  #    # => {
  #    #      'title' => 'Everyone Poops',
  #    #      'body' => 'Taro Gomi'
  #    #   }
  #
  #    #    or...
  #
  #    # when admin
  #    # => {
  #    #      'title' => 'Everyone Poops',
  #    #       'body' => 'Taro Gomi',
  #    #       'phone' => '123-4567',
  #    #   }
  #
  # When <tt>fields</tt> is nil, all attributes are added.
  #
  #   AttributesBuilder.new
  #    .add('title', @record.title)
  #    .add('body',  @record.body)
  #    .add_if('phone', @record.phone, -> { admin? })  # conditionally adding
  #    .add('isbn', @record.isbn)
  #    .attributes
  #
  #    # when non-admin
  #    # => {
  #    #      'title' => 'Everyone Poops',
  #    #      'body' => 'Taro Gomi',
  #    #      'isbn' => '5555555'
  #    #    }
  #
  #    #    or...
  #
  #    # when admin
  #    # => {
  #    #       'title' => 'Everyone Poops',
  #    #       'body' => 'Taro Gomi',
  #    #       'phone' => '123-4567',
  #    #       'isbn' => '5555555'
  #    #    }
  #
  class AttributesBuilder
    # (Array or nil) fields (sparse fieldset) array passed in initialize.
    attr_reader :fields

    # * <tt>fields</tt> - Array of fields to display for a type. Defaults to nil. When nil, all fields are permitted.
    def initialize(fields = nil)
      @hash = {}
      @fields = fields
      @fields.map!(&:to_s) if @fields.respond_to?(:map)
    end

    # Adds attribute if attribute name is in <tt>fields</tt> array.
    #
    # i.e,
    #
    #  SimpleJsonApi::AttributesBuilder.new(fields)
    #   .add('name', @object.name)
    #   .attributes
    def add(name, value)
      @hash[name.to_s] = value if add_attr?(name)
      self
    end

    # Add multiple attributes.
    #
    # i.e,
    #
    #  SimpleJsonApi::AttributesBuilder.new(fields)
    #   .add_multi(@object, 'name', 'email', 'logins')
    #   .attributes
    def add_multi(object, *attrs)
      attrs.each {|attr| add(attr, object.send(attr)) }
      self
    end

    # Adds attribute if attribute name is in <tt>fields</tt> array *and* proc returns true.
    #
    # i.e,
    #
    #  SimpleJsonApi::AttributesBuilder.new(fields)
    #   .add_if('email', @object.email, -> { admin? })
    #   .attributes
    def add_if(name, value, proc)
      @hash[name] = value if add_attr?(name) && proc.call == true
      self
    end

    # Returns attributes as a hash.
    #
    # i.e.,
    #  {
    #    'title' => 'Everyone Poops',
    #    'body' => 'Taro Gomi',
    #    'phone' => '123-4567',
    #    'isbn' => '5555555'
    #  }
    def attributes
      @hash
    end

    protected

    # Returns true if @fields is not defined. If @fields is defined,
    # returns true if attribute name is included in the @fields array.
    def add_attr?(name)
      @fields.respond_to?(:include?) ? @fields.include?(name.to_s) : true
    end
  end
end
