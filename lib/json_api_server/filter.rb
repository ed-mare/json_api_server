module JsonApiServer # :nodoc:
  # Implements filter parameters per JSON API Spec: http://jsonapi.org/recommendations/#filtering.
  # The spec says: "The filter query parameter is reserved for filtering data. Servers
  # and clients SHOULD use this key for filtering operations."
  #
  #   ie., GET /topics?filter[id]=1,2&filter[book]=*potter
  #
  # This class (1) whitelists filter params and (2) generates a sub-query
  # based on filters. If a user requests an unsupported filter, a
  # JsonApiServer::BadRequest exception is raised which renders a 400 error.
  #
  # Currently supports only ActiveRecord::Relation. Filters are combined with AND.
  #
  # === Usage:
  #
  # A filter request will look like:
  #   /topics?filter[id]=1,2&filter[book]=*potter
  #
  # ==== Configurations:
  #
  # Configurations look like:
  #  [
  #   { id: { type: 'Integer' } },
  #   { tags: { builder: :pg_jsonb_ilike_array } },
  #   { published: { type: 'Date' } },
  #   { published1: { col_name: :published, type: 'Date' } },
  #   :location,
  #   { book: { wildcard: :both } },
  #   { search: { builder: :model_query, method: :search } }
  #  ]
  #
  # ====== whitelist
  # Filter attributes are whitelisted. Specify filters you want to support in filter configs.
  #
  # ====== :type
  # :type (data type) defaults to String. Filter values are cast to this type.
  # Supported types are:
  #
  # - String
  # - Integer
  # - Date (Note: invalid Date casts to nil)
  # - DateTime (Note: invalid DateTime casts to nil)
  # - Float (untested)
  # - BigDecimal (untested)
  #
  # ====== :col_name
  # If a filter name is different from its model column/attribute, specify the column/attribute with :col_name.
  #
  # ====== :wildcard
  # A filter can enable wildcarding with the <tt>:wildcard</tt> option. <tt>:both</tt> wildcards both
  # sides, <tt>:left</tt> wildcards the left, <tt>:right</tt> wildcards the right.
  # A user triggers wildcarding by preceding a filter value with a * character (i.e., *weather).
  #
  #  /comments?filter[comment]=*weather => "comments"."comment" LIKE '%weather%'
  #
  # Additional wildcard/like filters are available for Postgres.
  #
  # ILIKE for case insensitive searches:
  # - <tt>pg_ilike</tt>: JsonApiServer::PgIlike
  #
  # For searching a JSONB array - case sensitive:
  # - <tt>pg_jsonb_array</tt>: JsonApiServer::PgJsonbArray
  #
  # For searching a JSONB array - case insensitive:
  # - <tt>pg_jsonb_ilike_array</tt>: JsonApiServer::PgJsonbIlikeArray
  #
  #
  # ====== builder: :model_query
  #
  # A filter can be configured to call a model's singleton method.
  #
  # Example:
  #
  #  [
  #   { search: { builder: :model_query, method: :search } }
  #  ]
  #
  # Request:
  #
  #   /comments?filter[search]=tweet
  #
  # The singleton method <tt>search</tt> will be called on the model specified in the
  # filter constructor.
  #
  # ====== builder:
  #
  # Specify a specific filter builder to handle the query. The list of default builders
  # is in JsonApiServer::Configuration.
  #
  #  [
  #    { tags: { builder: :pg_jsonb_ilike_array } }
  #  ]
  #
  # As mentioned above, there are additional filter builders for Postgres. Custom filter builders
  # can be added. In this example, it's using the <tt>:pg_jsonb_ilike_array</tt> builder
  # which performs a case insensitve search on a JSONB array column.
  #
  # === Features
  #
  # ====== IN statement
  #
  # Comma separated filter values translate into an IN statement.
  #  /topics?filter[id]=1,2 => "topics"."id" IN (1,2)'
  #
  # ===== Operators
  #
  # The following operators are supported:
  #
  #   =, <, >, >=, <=, !=
  #
  # Example:
  #
  #  /comments?filter[id]=>=20
  #  # note: special characters should be encoded -> /comments?filter[id]=%3E%3D20
  #
  # ====== Searching a Range
  #
  # Searching a range can be achieved with two filters for the same model attribute
  # and operators:
  #
  # Configuration:
  #  [
  #   { published: { type: 'Date' } },
  #   { published1: { col_name: :published, type: 'Date' } }
  #  ]
  #
  # Request:
  #
  #  /topics?filter[published]=>1998-01-01&filter[published1]=<1999-12-31
  #
  # Produces a query like:
  #
  #  ("topics"."published" > '1998-01-01') AND ("topics"."published" < '1999-12-31')
  #
  # === Custom Filters
  #
  # Custom filters can be added. Filters should inherit from JsonApiServer::FilterBuilder.
  #
  # Example:
  #
  #  # In config/initializers/json_api_server.rb
  #
  #  # Create custom fitler.
  #  module JsonApiServer
  #   class MyCustomFilter < FilterBuilder
  #     def to_query(model)
  #       model.where("#{full_column_name(model)} LIKE :val", val: "%#{value}%")
  #     end
  #   end
  #  end
  #
  #  # Update :filter_builders attribute to include your builder.
  #  JsonApiServer.configure do |c|
  #   c.base_url = 'http://localhost:3001'
  #   c.filter_builders = c.filter_builders.merge(my_custom_builder: JsonApiServer::MyCustomFilter)
  #   c.logger = Rails.logger
  #  end
  #
  #  # and then use it in your controllers...
  #  #  c.filter_options = [
  #  #  { names: { builder: :my_custom_builder } }
  #  # ]
  #
  # ==== Note:
  #
  # - JsonApiServer::Builder class provides an easier way to use this class.
  #
  class Filter
    # ActionDispatch::Request passed in constructor.
    attr_reader :request

    # Query parameters from #request.
    attr_reader :params

    # ActiveRecord::Base model passed in constructor.
    attr_reader :model

    # Filter configs passed in constructor.
    attr_reader :permitted

    # Arguments:
    # - <tt>request</tt> - ActionDispatch::Request
    # - <tt>model</tt> - ActiveRecord::Base model. Used to generate sub-query.
    # - <tt>permitted</tt> (Array) - Defaults to empty array. Filter configurations.
    def initialize(request, model, permitted = [])
      @request = request
      @model = model
      @permitted = permitted.is_a?(Array) ? permitted : []
      @params = request.query_parameters
    end

    # Filter params from query parameters.
    def filter_params
      @filter ||= params[:filter] || {}
    end

    # Returns an ActiveRecord Relation object (query fragment) which can be
    # merged with another.
    def relation
      @conditions ||= begin
        filter_params.each_with_object(model.all) do |(attr, val), result|
          if attr.present? && val.present?
            query = query_for(attr, val)
            result.merge!(query) unless query.nil? # query.present? triggers a db call.
          end
        end
      end
    end

    alias query relation

    # Hash with filter meta information. It echos untrusted user input
    # (no sanitizing).
    #
    # i.e.,
    #  {
    #    filter: [
    #      'id: 1,2',
    #      'comment: *weather'
    #    ]
    #  }
    def meta_info
      @meta_info ||= begin
        { filter:
        filter_params.each_with_object([]) do |(attr, val), result|
          result << "#{attr}: #{val}" if attr.present? && val.present?
        end }
      end
    end

    protected

    # Use classes. Allow classes to be pushed in via initializers.
    def query_for(attr, val)
      config = config_for(attr)
      return nil if config.nil?
      parser = FilterParser.new(attr, val, model, config)
      parser.to_query
    end

    # Returns config information on permitted attributes. Raises
    # JsonApiServer::BadRequest with descriptive message if attribute
    # is not whitelisted.
    def config_for(attr)
      config = permitted.find do |a|
        attr == (a.respond_to?(:keys) ? a.keys.first : a).to_s
      end
      if config.nil?
        msg = I18n.t('json_api_server.render_400.filter', param: attr)
        raise JsonApiServer::BadRequest, msg
      end
      FilterConfig.new(config)
    end
  end
end
