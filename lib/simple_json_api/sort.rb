#--
# TODO:
#   - Does not return 400 Bad Request if sort attribute is not supported.
#   - Sort nested relationships specified with dot notation - topic.comments
#++
module SimpleJsonApi # :nodoc:
  # === Description:
  # Implements sort parameters per JSON API Spec:
  # http://jsonapi.org/format/#fetching-sorting.
  #
  # From the spec: "The sort order for each sort field MUST be ascending unless it is
  # prefixed with a minus (U+002D HYPHEN-MINUS, "-", in which case it MUST be
  # descending."
  #
  # This class (1) whitelists sort params, (2) optionally specifies a default order,
  # and (3) generates a sub-query based on these params.
  #
  # === Usage:
  #
  # A sort request will look like:
  #   /topics?sort=-created,title
  #
  # This gets converted to an array. Sort order is ASC by default. Minus = DESC.
  #   ['-created', 'title']
  #
  # Sort attributes are configured like so. <tt>:permitted</tt> are whitelisted attributes.
  # <tt>:default</tt> specifies the default sort order. If a user specifies sort params other
  # than those in <tt>:permitted</tt>, a SimpleJsonApi::BadRequest exception is
  # raised which renders a 400 error.
  #  {
  #    permitted: [:id, :title, { created: { col_name: :created_at}],
  #    default: { id: :desc }
  #  }
  # In this example, id, title and created (alias for created_at column)
  # are permitted sort params.
  #
  # ==== Example:
  #  # create sort options
  #  sort_options = {
  #    permitted: [:id, :title, { created: { col_name: :created_at}],
  #    default: { id: :desc }
  #  }
  #
  #  # create instance
  #  sort = SimpleJsonApi::Sort.new(request, Topic, sort_options)
  #
  #  # merge into master query
  #  recent_topics = Topic.recent.merge(sort.query)
  #
  #  # see sort params
  #  puts sort.sort
  #
  # ==== Note:
  # SimpleJsonApi::Builder class provides an easier way to use this class.
  #
  class Sort
    #--
    # ActiveRecord::QueryMethods order is defined order(*args)
    # i.e., User.order(:name, email: :desc)
    #++

    # Controller request object.
    attr_reader :request

    # Model passed in constructor.
    attr_reader :model

    # (Hash) Sort options. Specify the attributes that can be used in ActiveRecord
    # query method 'sort'. No sort attributes can be used except for those
    # specified here.
    #
    # - <tt>permitted</tt> - array of model attribute names
    # - <tt>default</tt> - used if no sort params are specified (or rejected)
    #
    # i.e.,
    #
    # Allows sorting on model attributes :id, :title, :created.
    # If no sort params are specified in the request, it sorts by 'id' desc.
    #
    #  {
    #    permitted: [:id, :title, { created: { col_name: :created_at}],
    #    default: { id: :desc }
    #  }
    attr_reader :options

    # Request query params (request.query_parameters).
    attr_reader :params

    # Params:
    #   - request - instance of request object
    #   - options - sort options. See #options documentation.
    def initialize(request, model, options = {})
      @request = request
      @model = model
      @options = options
      @params = request.query_parameters
    end

    # Returns an ActiveRecord::Relation if sort_params are present. Otherwise
    # returns nil. Instance is a query fragment intended to be merged into another
    # query.
    #
    # ==== Example:
    #
    #  sort = SimpleJsonApi::Sort.new(request, Comment, options)
    #  Comment.recent.merge!(sort.query)
    #
    def relation
      @relation ||= model.order(sort_params) if sort_params.present?
    end

    alias query relation

    # Sort query parameter params[:sort].
    def sort
      @sort ||= params[:sort].to_s
    end

    # Instance of SimpleJsonApi::SortConfigs based on #options.
    def configs
      @configs ||= SimpleJsonApi::SortConfigs.new(options)
    end

    # Calculated ActiveRecord 'order' parameters. Use in queries.
    def sort_params
      @sort_params ||= begin
        attrs = sort.split(',')
        sort_params = convert(attrs)
        sort_params.empty? ? configs.default_order : sort_params
      end
    end

    protected

    # Converts to ActiveRecord query order parameters; whitelists based on configs.
    # Raises SimpleJsonApi::BadRequest with descriptive message if attribute
    # is not whitelisted.
    def convert(attrs)
      whitelisted = []

      attrs.each do |attr|
        attr.strip!
        order = attr.start_with?('-') ? :desc : :asc
        attr_name = order == :desc ? attr.slice(1..attr.length) : attr
        config = configs.config_for(attr_name)
        if config.nil?
          raise SimpleJsonApi::BadRequest, "Sort param '#{attr_name}' is not supported."
        end
        whitelisted << { (config[:col_name] || config[:attr]) => order }
      end

      whitelisted
    end
  end
end
