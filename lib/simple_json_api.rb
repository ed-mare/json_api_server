require 'oj'
require 'logger'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/hash'
require 'active_support/inflector'

require 'simple_json_api/version'
require 'simple_json_api/api_version'
require 'simple_json_api/exceptions'
require 'simple_json_api/filter_builders'
require 'simple_json_api/configuration'
require 'simple_json_api/meta_builder'
require 'simple_json_api/serializer'
require 'simple_json_api/base_serializer'
require 'simple_json_api/resource_serializer'
require 'simple_json_api/resources_serializer'
require 'simple_json_api/attributes_builder'
require 'simple_json_api/relationships_builder'
require 'simple_json_api/error'
require 'simple_json_api/errors'
require 'simple_json_api/validation_errors'
require 'simple_json_api/paginator'
require 'simple_json_api/pagination'
require 'simple_json_api/sort_configs'
require 'simple_json_api/sort'
require 'simple_json_api/fields'
require 'simple_json_api/cast'
require 'simple_json_api/filter_config'
require 'simple_json_api/filter_parser'
require 'simple_json_api/filter'
require 'simple_json_api/include'
require 'simple_json_api/builder'

if defined?(Rails)
  require 'simple_json_api/engine'
  require 'simple_json_api/mime_types'
  require 'simple_json_api/controller/error_handling'
end

module SimpleJsonApi # :nodoc:
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= SimpleJsonApi::Configuration.new
    end

    def configure
      yield configuration
    end

    def errors(errors)
      SimpleJsonApi::Errors.new(errors)
    end

    def validation_errors(model)
      SimpleJsonApi::ValidationErrors.new(model)
    end

    def paginator(current_page, total_pages, per_page, base_url, params = {})
      SimpleJsonApi::Paginator.new(current_page, total_pages, per_page, base_url, params)
    end

    # Convenience method to SimpleJsonApi.configuration.logger.
    def logger
      SimpleJsonApi.configuration.logger
    end
  end
end
