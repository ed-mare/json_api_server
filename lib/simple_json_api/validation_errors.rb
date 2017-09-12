module SimpleJsonApi # :nodoc:
  # Converts ActiveModel validations to JSON API Errors.
  # Spec:  http://jsonapi.org/format/#error-objects.
  #
  # Calling <tt>render_422(model_instance)</tt> in a controller will create an instance of
  # this class and render with appropriate headers.
  #
  # i.e,
  #
  #   def create
  #     topic = Topic.new(topic_params)
  #
  #     if topic.save
  #      serializer = TopicSerializer.new(topic)
  #      render json: serializer.to_json, status: :created
  #    else
  #      render_422(topic)
  #    end
  #   end
  class ValidationErrors
    include SimpleJsonApi::Serializer
    include SimpleJsonApi::ApiVersion

    def initialize(model)
      errors = get_errors(model)
      @errors = SimpleJsonApi::Errors.new(errors)
    end

    def as_json
      @errors.as_json
    end

    protected

    # Grabs the first error per attribute.
    # Spec -> status: the HTTP status code applicable to this problem, expressed as a string value.
    # http://jsonapi.org/format/#error-objects
    def get_errors(model)
      if model.respond_to?(:errors) && model.errors.respond_to?(:full_messages_for)
        model.errors.keys.map do |field|
          {
            'status' => '422',
            'source' => { 'pointer' => "/data/attributes/#{field}" },
            'title' => 'Invalid Attribute',
            'detail' => model.errors.full_messages_for(field).first
          }
        end
      end
    end
  end
end
