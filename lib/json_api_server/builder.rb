module JsonApiServer # :nodoc:
  # This class integrates JSON API features -- pagination, sorting, filters, inclusion of
  # related resources, and sparse fieldsets -- in one place. It collects data to be used
  # by serializers.
  #
  # - It merges JSON API sub-queries (i.e, filters, pagination, sorting, etc.) into a query.
  # - It provides convenience methods to requested sparse fields, includes and pagination.
  #
  # === Usage:
  #
  # The Builder class takes two arguments, (1) the controller request and (2) an
  # initial query (i.e., MyModel.all, MyModel.authorized_to(current_user), etc.).
  #
  # Add JSON API features appropriate for the request. These methods are chainable.
  # Except for sparse fields, JSON API features are configured; filter, include
  # and sort configurations whitelist attributes/behavior while pagination sets
  # defaults and limits on number of records to return.
  #
  # - <tt>add_pagination(pagination_options)</tt> - for collections
  # - <tt>add_filter(filter_options)</tt> - for collections
  # - <tt>add_include(include_options)</tt>
  # - <tt>add_sort(sort_options)</tt> - for collections
  # - <tt>add_fields</tt>
  #
  # Once features are added, their corresponding values can be accessed:
  #
  # - <tt>query</tt> - memoized merged query (merges initial request with sort, pagination, filters, includes sub-queries if any)
  # - <tt>paginator</tt> - Paginator class for pagination links.
  # - <tt>includes</tt> - Array of requested (whitelisted) includes (i.e, <tt>['comments', 'comment.author']</tt>)
  # - <tt>sparse_fields</tt> - Hash of type/fields (i.e., {'articles => ['title', 'body', 'author'], 'people' => ['name']})
  #
  # ===== Example
  #  attr_accessor :pagination_options, :sort_options, :filter_options, :include_options
  #
  #  before_action do |c|
  #    c.pagination_options = { default_per_page: 10, max_per_page: 60 }
  #    c.sort_options = {
  #     permitted: [:character, :location, :published],
  #     default: { id: :desc }
  #    }
  #    c.filter_options = [
  #     { id: { type: 'Integer' } },
  #     { published: { type: 'Date' } },
  #     :location,
  #     { book: { wildcard: :both } }
  #    ]
  #    c.include_options = [
  #                          {'publisher': -> { includes(:publisher) }},
  #                          {'comments': -> { includes(:comments) }},
  #                         'comment.author'
  #                       ]
  #  end
  #
  #  # A collection.
  #  def index
  #    builder = JsonApiServer::Builder.new(request, Topic.current)
  #     .add_pagination(pagination_options)
  #     .add_filter(filter_options)
  #     .add_include(include_options)
  #     .add_sort(sort_options)
  #     .add_fields
  #
  #   serializer = TopicsSerializer.from_builder(builder)
  #   render json: serializer.to_json, status: :ok
  #  end
  #
  #  # A resource.
  #  def show
  #    builder = JsonApiServer::Builder.new(request, Topic.find(params[:id]))
  #     .add_include(['publisher', 'comments', 'comments.includes'])
  #     .add_fields
  #
  #    serializer = TopicSerializer.from_builder(builder)
  #    render json: serializer.to_json, status: :ok
  #  end
  #
  class Builder
    # ActionDispatch::Request passed in constructor.
    attr_reader :request

    # ActiveRecord::Base model extracted from initial query passed in constructor.
    attr_reader :model

    #  JsonApiServer::Fields instance if #add_fields was called. nil otherwise.
    attr_reader :fields

    # JsonApiServer::Pagination instance if #add_pagination was called. nil otherwise.
    attr_reader :pagination

    # JsonApiServer::Filter instance if #add_filter was called. nil otherwise.
    attr_reader :filter

    # JsonApiServer::Include instance if #add_include was called. nil otherwise.
    attr_reader :include

    # JsonApiServer::Sort instance if #add_sort was called. nil otherwise.
    attr_reader :sort

    # Arguments:
    # - request - an ActionDispatch::Request
    # - query (ActiveRecord::Relation) - Initial query.
    def initialize(request, query)
      @request = request
      @initial_query = query
      @model = model_from_query(@initial_query)
    end

    # Merges pagination, filter, sort, and include sub-queries (if defined)
    # into the initial query. Returns an ActiveRecord::Relation object.
    def relation
      @relation ||= begin
        return @initial_query unless @initial_query.respond_to?(:where)

        %i[pagination filter include sort].each_with_object(@initial_query) do |method, query|
          frag = send(method).try(:relation)
          query.merge!(frag) if frag
        end
      end
    end

    alias query relation

    # Creates JsonApiServer::Pagination instance based on request, initial query
    # model and pagination options. Instance is available through
    # the #pagination attribute. For collections only.
    #
    # - <tt>options</tt> - JsonApiServer::Pagination options.
    def add_pagination(**options)
      @pagination = JsonApiServer::Pagination.new(request, model, options)
      self
    end

    # Creates JsonApiServer::Filter instance based on request, initial query
    # model and filter configs. Instance is available through
    # the #filter attribute.
    #
    # - <tt>permitted</tt> - JsonApiServer::Filter configs.
    def add_filter(permitted = [])
      @filter = JsonApiServer::Filter.new(request, model, permitted)
      self
    end

    # Creates JsonApiServer::Include instance based on request, initial query
    # model and include configs. Instance is available through
    # the #include attribute.
    #
    # - <tt>permitted</tt> - JsonApiServer::Include configs.
    def add_include(permitted = [])
      @include = JsonApiServer::Include.new(request, model, permitted)
      self
    end

    # Creates JsonApiServer::Sort instance based on request, initial query
    # model and sort options. Instance is available through
    # the #sort attribute.
    #
    # - <tt>options</tt> - JsonApiServer::Sort options.
    def add_sort(**options)
      @sort = JsonApiServer::Sort.new(request, model, options)
      self
    end

    # Creates JsonApiServer::Fields instance based on request. Instance is
    # available through the #fields attribute.
    def add_fields
      @fields = JsonApiServer::Fields.new(request)
      self
    end

    # JsonApiServer::Paginator instance for collection if #add_pagination
    # was called previously, nil otherwise.
    def paginator
      @pagination.try(:paginator_for, relation)
    end

    # (Array or nil) Whitelisted includes. An array of relationships (strings)
    # if #add_include was called previously, nil otherwise.
    # i.e,
    #  ['comments', 'comments.author']
    def includes
      @include.try(:includes)
    end

    # (Hash or nil) Sparse fields. Available if #add_fields was previously called.
    # i.e.,
    #  {'articles => ['title', 'body', 'author'], 'people' => ['name']}
    def sparse_fields
      @fields.try(:sparse_fields)
    end

    protected

    def model_from_query(query)
      if query.respond_to?(:klass)
        query.klass
      elsif query.respond_to?(:class)
        query.class
      end
    end
  end
end
