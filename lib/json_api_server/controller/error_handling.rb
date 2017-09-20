module JsonApiServer # :nodoc:
  module Controller # :nodoc:
    # Handles common controller errors. Returns JsonApi errors http://jsonapi.org/format/#errors.
    #
    # === Usage
    #
    # To use, include the JsonApiServer::Controller::ErrorHandling module in your
    # base API controller class:
    #
    #   i.e.,
    #
    #   class Api::BaseController < ApplicationController
    #     include JsonApiServer::Controller::ErrorHandling
    #   end
    #
    # === I18n
    #
    # Messages are defined in config/locales/en.yml.
    #
    # Customize ActiveRecord::RecordNotFound and ActiveRecord::RecordNotUnique
    # messages to reference a resource by name.
    #
    # *Example:*
    #
    #  # Given a sandwiches controller...
    #  class Api::V1::SandwichesController < Api::BaseController
    #      ...
    #  end
    #
    #  # config/locales/en.yml
    #  en:
    #    json_api_server:
    #      controller:
    #        sandwiches:
    #          name: 'sandwich'
    #
    #  # messages now become:
    #  # 404 => "This sandwich does not exist."
    #  # 409 => "This sandwich already exists."
    module ErrorHandling
      def self.included(base)
        # Overrides of exception handling.
        base.rescue_from StandardError, with: :render_500
        base.rescue_from JsonApiServer::BadRequest, with: :render_400
        base.rescue_from ActionController::BadRequest, with: :render_400
        base.rescue_from ActiveRecord::RecordNotFound, with: :render_404
        base.rescue_from ActiveRecord::RecordNotUnique, with: :render_409
        base.rescue_from ActionController::RoutingError, with: :render_404
        base.rescue_from ActionController::UrlGenerationError, with: :render_404
        base.rescue_from ActionController::UnknownController, with: :render_404
        base.rescue_from ActionController::UnknownFormat, with: :render_unknown_format
      end

      protected

      # Render 400 json and status.
      def render_400(exception = nil)
        message = (exception && known?(exception) && exception.message) || I18n.t('json_api_server.render_400.detail')
        errors = JsonApiServer.errors(
          status: 400,
          title: I18n.t('json_api_server.render_400.title'),
          detail: message
        )
        render json: errors.to_json, status: 400
      end

      # Render 401 json and status.
      def render_401
        errors = JsonApiServer.errors(
          status: 401,
          title:  I18n.t('json_api_server.render_401.title'),
          detail: I18n.t('json_api_server.render_401.detail')
        )
        render json: errors.to_json, status: 401
      end

      # Render 403 json and status.
      def render_403
        errors = JsonApiServer.errors(
          status: 403,
          title: I18n.t('json_api_server.render_403.title'),
          detail: I18n.t('json_api_server.render_403.detail')
        )
        render json: errors.to_json, status: 403
      end

      # Render 404 json and status. Message customizable (see class description).
      def render_404(_exception = nil)
        errors = JsonApiServer.errors(
          status: 404,
          title: I18n.t('json_api_server.render_404.title'),
          detail: I18n.t('json_api_server.render_404.detail', name: _i18n_name)
        )
        render json: errors.to_json, status: 404
      end

      # Render 409 json and status. Message customizable (see class description).
      def render_409(_exception = nil)
        errors = JsonApiServer.errors(
          status: 409,
          title: I18n.t('json_api_server.render_409.title'),
          detail: I18n.t('json_api_server.render_409.detail', name: _i18n_name)
        )
        render json: errors.to_json, status: 409
      end

      # Render 422 json and status. For model validation error.
      def render_422(object)
        errors = JsonApiServer.validation_errors(object)
        render json: errors.to_json, status: 422
      end

      # Render 500 json. Logs exception.
      def render_500(exception = nil)
        JsonApiServer.logger.error(exception.try(:message))
        JsonApiServer.logger.error(exception.try(:backtrace))

        errors = JsonApiServer.errors(
          status: 500,
          title: I18n.t('json_api_server.render_500.title'),
          detail: I18n.t('json_api_server.render_500.detail')
        )
        render json: errors.to_json, status: 500
      end

      # Render 406 status code and message that the format is not supported.
      def render_unknown_format
        format = sanitize(params[:format]) || ''
        errors = JsonApiServer.errors(
          status: 406,
          title: I18n.t('json_api_server.render_unknown_format.title'),
          detail: I18n.t('json_api_server.render_unknown_format.detail', name: format)
        )
        render json: errors.to_json, status: 406
      end

      # Render 503 json and status (service unavailable).
      def render_503(message = nil)
        errors = JsonApiServer.errors(
          status: 500,
          title: I18n.t('json_api_server.render_503.title'),
          detail: message || I18n.t('json_api_server.render_503.detail')
        )
        render json: errors.to_json, status: 503
      end

      private

      def known?(exception)
        !(exception.class.name =~ /JsonApiServer::BadRequest/).nil?
      end

      def sanitize(string)
        ActionController::Base.helpers.sanitize(string.to_s)
      end

      def _i18n_name
        I18n.t("json_api_server.controller.#{controller_name}.name", raise: true)
      rescue
        I18n.t('json_api_server.variables.defaults.name')
      end
    end
  end
end
