# TODO: error message and internationalization.
# TODO: cache permitted inclusions?
module SimpleJsonApi # :nodoc:
  # ==== Description:
  #
  # Handles include parameters per JSON API spec http://jsonapi.org/format/#fetching-includes.
  #
  # An endpoint may support an include request parameter to allow the client to
  # customize which related resources should be returned.
  #  ie., GET /articles/1?include=comments,comment.author,tags HTTP/1.1
  #
  # This class (1) whitelists include params, (2) maintains an array of
  # permitted inclusions, and (3) generates a sub-query
  # if eagerloading is configured for inclusions.
  #
  # === Usage:
  #
  # An inclusion request looks like:
  #   /topics?include=author,comment.author,comments
  #
  # It is converted to an array of relationships:
  #   ['author', 'comment.author', 'comments']
  #
  # Includes are whitelisted with a configuration that looks like:
  #  {
  #    {'author': -> { includes(:author) }},
  #    {'comments': -> { includes(:comments) }},
  #    'comment.author'
  #  }
  #
  # In this example, author, comments, and comment.author are allowed includes. If
  # an unsupported include is requested, a SimpleJsonApi::BadRequest exception is
  # raised which renders a 400 error.
  #
  # A proc/lambda can be specified to eagerload relationships. Be careful,
  # to date, there is no way to apply limits to :includes.
  #
  # ==== Example:
  #  permitted = {
  #    {'author': -> { includes(:author) }},
  #    {'comments': -> { includes(:comments) }},
  #    'comment.author'
  #  }
  #
  #  # create instance
  #  include = SimpleJsonApi::Include.new(request, Topic, permitted)
  #
  #  # merge into master query
  #  recent_topics = Topic.recent.merge(include.query)
  #
  #  # use in serializers
  #  class CommentSerializer < SimpleJsonApi::ResourceSerializer
  #    def relationships
  #      if relationship?('comment.author') # relationship? is a helper methods in serializers.
  #        #...
  #      end
  #    end
  #  end
  #
  # ==== Note:
  # SimpleJsonApi::Builder class provides an easier way to use this class.
  #
  class Include
    # ActionDispatch::Request passed in constructor.
    attr_reader :request

    # Query parameters from #request.
    attr_reader :params

    # ActiveRecord::Base model passed in constructor.
    attr_reader :model

    # Include configs passed in constructor.
    attr_reader :permitted

    # Arguments:
    #
    # - <tt>request</tt> - ActionDispatch::Request
    # - <tt>model</tt> (ActiveRecord::Base) - Model to append queries to.
    # - <tt>permitted</tt> (Array) - Permitted inclusions. To eagerload the relationship, pass a proc:
    #
    # ===== Example:
    #
    # Eagerloads author, comments, comments -> authors.
    #
    #  [
    #    {'author': -> { includes(:author) }},
    #    {'comments': -> { includes(:comments) }},
    #    {'comments.author': -> {includes(comments: :author) }},
    #    'publisher.addresses'
    #  ]
    def initialize(request, model, permitted = [])
      @request = request
      @model = model
      @permitted = permitted.is_a?(Array) ? permitted : []
      @params = request.query_parameters
    end

    # Array of whitelisted include params. Raises SimpleJsonApi::BadRequest if
    # any #include_params is not whitelisted.
    #
    # ==== Examples
    #
    #   include=comments becomes ['comments']
    #   include=comments.author,tags becomes ['comments.author', 'tags']
    def includes
      include_params.select { |i| config_for(i).present? }
    end

    # Array of include params from the request.
    #
    # ===== Examples
    #
    #  include=comments becomes ['comments']
    #  include=comments.author,tags becomes ['comments.author', 'tags']
    def include_params
      @include_params ||= begin
        params[:include].present? ? params[:include].split(',').map!(&:strip) : []
      end
    end

    # Returns an ActiveRecord::Relation object (a query fragment). Returns nil
    # if no eagerloading is configured.
    def relation
      @relation ||= begin
        additions = false
        # TODO: merge! has unexpected results.
        frag = include_params.reduce(model.all) do |result, inclusion|
          config = config_for(inclusion)
          query = config.respond_to?(:keys) ? config.values.first : nil
          unless query.nil?
            additions = true
            result = result.merge(query)
          end
          result
        end
        additions ? frag : nil
      end
    end

    alias query relation

    protected

    # Returns config. Raises SimpleJsonApi::BadRequest if inclusion is not whitelisted.
    def config_for(inclusion)
      config = permitted.find do |v|
        inc = inclusion.to_s
        v.respond_to?(:keys) ? v.keys.first.to_s == inc : v.to_s == inc
      end
      if config.nil?
        msg = I18n.t('simple_json_api.render_400.inclusion', param: inclusion)
        raise SimpleJsonApi::BadRequest, msg
      end
      config
    end
  end
end
