module SimpleJsonApi # :nodoc:
  # Returns query_builder class for key specified.
  def self.filter_builder(key)
    SimpleJsonApi.configuration.filter_builders[key]
  end
  # Takes a filter param and associated config and creates an
  # ActiveRecord::Relation query which can be merged into a
  # master query. Part of http://jsonapi.org/recommendations/#filtering.
  class FilterParser
    # The filter name, i.e., :id, :title
    attr_reader :attr
    # The original filter value.
    attr_reader :value
    # Original value cast to the appropriate data type.
    attr_reader :casted_value
    # Model class or ActiveRecord_Relation. Queries are built using this model.
    attr_reader :model
    # Instance of FilterConfig for the filter.
    attr_reader :config
    # Query operator if one applies. i.e., IN, =, <, >, >=, <=, !=
    attr_reader :operator

    # parameters:
    #   - attr (String) - filter name as it appears in the url.
    #                    i.e., filter[tags]=art,theater => tags
    #   - value (String) - value from query, i.e., 'art,theater'
    #   - model (class or class name) - Model class or class name.
    #                    i.e., User or 'User'.
    #   - config (instance of FilterConfig) - filter config for the filter.
    def initialize(attr, value, model, config)
      @attr = attr
      @value = value
      @model = model.is_a?(Class) ? model : model.constantize
      @config = config
      parse
    end

    # Converts filter into an ActiveRecord::Relation where query which
    # can be merged with other queries.
    def to_query
      return nil if config.nil? # not a whitelisted attr
      klass = SimpleJsonApi.filter_builder(builder_key) || raise("Query builder '#{builder_key}' doesn't exist.")
      builder = klass.new(attr, casted_value, operator, config)
      builder.to_query(@model)
    end

    protected

    def builder_key
      return config.builder if config.builder.present?

      case operator
      when 'IN'
        config.in || configuration.default_in_builder
      when '*'
        config.like || configuration.default_like_builder
      when *SqlComp.allowed_operators
        config.comparison || configuration.default_comparison_builder
      else
        config.default || configuration.default_builder
      end
    end

    # Value, operator, or specified class.
    def parse
      if value.include?(',')
        arr = value.split(',')
        arr.map!(&:strip)
        @casted_value = cast(arr, config.type)
        @operator = 'IN'
      else
        value =~ /\A(!?[<|>]?=?\*?)(.+)/
        # SimpleJsonApi.logger.debug("VALUE IS #{Regexp.last_match(2)}")
        # SimpleJsonApi.logger.debug("CONFIG.TYPE IS #{config.type}")
        @casted_value = cast(Regexp.last_match(2), config.type)
        @operator = Regexp.last_match(1)
      end
    end

    def cast(value, type)
      SimpleJsonApi::Cast.to(value, type)
    end

    def configuration
      SimpleJsonApi.configuration
    end
  end
end
