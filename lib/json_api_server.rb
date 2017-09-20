require 'oj'
require 'will_paginate'
require 'logger'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/hash'
require 'active_support/inflector'

require 'json_api_server/version'
require 'json_api_server/api_version'
require 'json_api_server/exceptions'
require 'json_api_server/filter_builders'
require 'json_api_server/configuration'
require 'json_api_server/meta_builder'
require 'json_api_server/serializer'
require 'json_api_server/base_serializer'
require 'json_api_server/resource_serializer'
require 'json_api_server/resources_serializer'
require 'json_api_server/attributes_builder'
require 'json_api_server/relationships_builder'
require 'json_api_server/error'
require 'json_api_server/errors'
require 'json_api_server/validation_errors'
require 'json_api_server/paginator'
require 'json_api_server/pagination'
require 'json_api_server/sort_configs'
require 'json_api_server/sort'
require 'json_api_server/fields'
require 'json_api_server/cast'
require 'json_api_server/filter_config'
require 'json_api_server/filter_parser'
require 'json_api_server/filter'
require 'json_api_server/include'
require 'json_api_server/builder'

if defined?(Rails)
  require 'json_api_server/engine'
  require 'json_api_server/mime_types'
  require 'json_api_server/controller/error_handling'

  # https://github.com/ohler55/oj/blob/master/pages/Rails.md
  # gem 'oj_mimic_json' # we need this for Rails 4.1.x
  Oj.optimize_rails if Oj.respond_to?(:optimize_rails) # rails 5 but also rails 4?
end

module JsonApiServer # :nodoc:
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= JsonApiServer::Configuration.new
    end

    def configure
      yield configuration
    end

    def errors(errors)
      JsonApiServer::Errors.new(errors)
    end

    def validation_errors(model)
      JsonApiServer::ValidationErrors.new(model)
    end

    def paginator(current_page, total_pages, per_page, base_url, params = {})
      JsonApiServer::Paginator.new(current_page, total_pages, per_page, base_url, params)
    end

    # Convenience method to JsonApiServer.configuration.logger.
    def logger
      JsonApiServer.configuration.logger
    end
  end
end
