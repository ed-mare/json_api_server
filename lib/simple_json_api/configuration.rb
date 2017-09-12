module SimpleJsonApi # :nodoc:
  # ==== Description
  #
  # Configurations for the gem.
  #
  # - Be sure to configure :base_url which defaults to nil.
  # - Logger defaults to Logger.new(STDOUT). If using Rails, configure to Rails.logger.
  # - Custom builders can be added to :filter_builders.
  # - Default builders can be substituted.
  #
  # ===== Example
  #
  #   # config/initializers/simple_json_api.rb
  #
  #   # example of custom filter builder
  #   module SimpleJsonApi
  #     class MyCustomFilter < FilterBuilder
  #       def to_query(model)
  #         model.where("#{column_name} LIKE :val", val: "%#{value}%")
  #       end
  #     end
  #   end
  #
  #   SimpleJsonApi.configure do |c|
  #     c.base_url = 'http://localhost:3001' # or ENV['HOSTNAME']
  #     c.filter_builders = c.filter_builders
  #       .merge({my_custom_builder: SimpleJsonApi::MyCustomFilter})
  #     c.logger = Rails.logger
  #   end
  #
  class Configuration
    # Root url i.e., http://www.example.com. Used in pagination links.
    attr_accessor :base_url

    # Pagination option. Default maximum number of records to show per page.
    # Defaults to 100.
    attr_accessor :default_max_per_page

    # Pagination option. Default number of records to show per page.
    # Defaults to 20.
    attr_accessor :default_per_page

    # JSON is serialized with OJ gem. Options are defined in DEFAULT_SERIALIZER_OPTIONS.
    attr_accessor :serializer_options

    # Defaults to sql_like: SimpleJsonApi::SqlLike. If using Postgres,
    # it can be replaced with pg_ilike: SimpleJsonApi::PgIlike.
    attr_accessor :default_like_builder

    # Defaults to sql_in: SimpleJsonApi::SqlIn. For IN (x,y,z) queries.
    attr_accessor :default_in_builder

    # Defaults to sql_comparison: SimpleJsonApi::SqlComp.
    # For <,>, <=, >=, etc. queries.
    attr_accessor :default_comparison_builder

    # Defaults to sql_eql: SimpleJsonApi::SqlEql.
    attr_accessor :default_builder

    # Defaults to DEFAULT_FILTER_BUILDERS.
    attr_accessor :filter_builders

    # Defaults to Logger.new(STDOUT)
    attr_accessor :logger

    # Serializer options for the OJ gem.
    DEFAULT_SERIALIZER_OPTIONS = {
      escape_mode: :xss_safe,
      time: :xmlschema,
      mode: :compat
    }.freeze

    # Default filter builders. For generating queries based on
    # on requested filters.
    DEFAULT_FILTER_BUILDERS = {
      sql_eql: SimpleJsonApi::SqlEql,
      sql_comparison: SimpleJsonApi::SqlComp,
      sql_in: SimpleJsonApi::SqlIn,
      sql_like: SimpleJsonApi::SqlLike,
      pg_ilike: SimpleJsonApi::PgIlike,
      pg_jsonb_array: SimpleJsonApi::PgJsonbArray,
      pg_jsonb_ilike_array: SimpleJsonApi::PgJsonbIlikeArray,
      model_query: SimpleJsonApi::ModelQuery
    }.freeze

    def initialize
      @base_url = nil
      @default_max_per_page = 100
      @default_per_page = 20
      @default_like_builder = :sql_like
      @default_in_builder = :sql_in
      @default_comparison_builder = :sql_comparison
      @default_builder = :sql_eql
      @serializer_options = DEFAULT_SERIALIZER_OPTIONS
      @filter_builders = DEFAULT_FILTER_BUILDERS
      @logger = Logger.new(STDOUT)
    end
  end
end
