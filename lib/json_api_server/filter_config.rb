module JsonApiServer # :nodoc:
  # Configuration for a filter http://jsonapi.org/format/#fetching-filtering.
  #
  # Example filter configuration:
  #
  #  filter_options = [
  #       { id: { type: 'Integer' } },
  #       { tags: { builder: :pg_jsonb_ilike_array } },
  #       :body,
  #       { title: { wildcard: :right }},
  #       { search: { builder: :model_query, method: :search } },
  #       { created: { col_name: :created_at, type: 'DateTime' } }
  #   ]
  #
  class FilterConfig
    # Attribute used in queries. i.e., /path?filter[foo]=bar => foo
    attr_reader :attr
    # (optional) If the fitler name is not the same as the database column name,
    # map it. i.e., map :created to :created_at.
    # { created: { col_name: :created_at, type: 'DateTime' } }
    attr_reader :column_name
    # (optional) Data type. Specify data type class as string. i.e., 'String',
    # 'DateTime', 'Time', 'BigDecimal', etc. Defaults to 'String'.
    attr_reader :type
    # (optional) Symbol - the builder class to use for LIKE queries. Defaults
    # to :sql_like if not specified.
    attr_reader :like
    # (optional) Symbol - the builder class to use for IN queries. Defaults to
    # :sql_in if not specified.
    attr_reader :in
    # (optional) Symbol - the builder class to use for '=', '<', '>', '>=', '<=', '=',
    # '!<', '!>', '<>' queries. Defaults to :sql_comparison.
    attr_reader :comparison
    # (optional) Symbol - the builder class to use for all other queries. Defaults to
    # :sql_eql.
    attr_reader :default
    # (optional) Symbol - the builder class to use for all queries for the attribute.
    attr_reader :builder
    # (optional) Use with ModelQuery builder which calls a class method on the model.
    attr_reader :method
    # (optional) Symbol - :left, :right or :none. Defaults to wildcarding beginning
    # end of string, i.e., "%#{value}%",
    attr_reader :wildcard

    def initialize(config)
      if config.respond_to?(:keys)
        # i.e, c.filter_options = { permitted: [{created: {attr: :created_at, type: DateTime}}] }
        key, value = config.first
        @attr = key
        @column_name = value[:col_name] || @attr
        @type = value[:type] || self.class.default_type
        @like = value[:like]
        @in = value[:in]
        @comparison = value[:comparison]
        @default = value[:default]
        @builder = value[:builder]
        @wildcard = value[:wildcard]
        @method = value[:method]
      else
        # i.e., c.filter_options = { permitted: [:body] }
        @attr = @column_name = config
        @type = self.class.default_type
      end
    end

    # Default data type is String unless a filter config specifies.
    def self.default_type
      String
    end
  end
end
