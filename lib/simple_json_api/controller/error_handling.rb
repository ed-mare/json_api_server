module SimpleJsonApi # :nodoc:
  module Controller # :nodoc:
    # Handles common controller errors. Returns JsonApi errors http://jsonapi.org/format/#errors.
    #
    # === Usage
    #
    # To use, include the SimpleJsonApi::Controller::ErrorHandling module in your
    # base API controller class:
    #
    #   i.e.,
    #
    #   class Api::BaseController < ApplicationController
    #     include SimpleJsonApi::Controller::ErrorHandling
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
    #    simple_json_api:
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
        base.rescue_from SimpleJsonApi::BadRequest, with: :render_400
        base.rescue_from ActiveRecord::RecordNotFound, with: :render_404
        base.rescue_from ActiveRecord::RecordNotUnique, with: :render_409
        base.rescue_from ActionController::RoutingError, with: :render_404
        base.rescue_from ActionController::UrlGenerationError, with: :render_404
        base.rescue_from ActionController::UnknownController, with: :render_404
        base.rescue_from ActionController::UnknownFormat, with: :render_unknown_format
      end

      protected

      #--
      # http://ricostacruz.com/cheatsheets/rails-i18n.html
      # see http://stackoverflow.com/questions/33391908/how-to-use-i18n-from-controller-in-rails
      # http://apidock.com/rails/ActionView/Helpers/TranslationHelper/translate
      # TODO: how to use loc for message overrides.
      #++

      # Render 400 json and status.
      def render_400(exception = nil)
        message = (exception && exception.message) || I18n.t('simple_json_api.render_400.detail')
        errors = SimpleJsonApi.errors(
          status: 400,
          title: I18n.t('simple_json_api.render_400.title'),
          detail: message
        )
        render json: errors.to_json, status: 400
      end

      # Render 401 json and status.
      def render_401
        errors = SimpleJsonApi.errors(
          status: 401,
          title:  I18n.t('simple_json_api.render_401.title'),
          detail: I18n.t('simple_json_api.render_401.detail')
        )
        render json: errors.to_json, status: 401
      end

      # Render 403 json and status.
      def render_403
        errors = SimpleJsonApi.errors(
          status: 403,
          title: I18n.t('simple_json_api.render_403.title'),
          detail: I18n.t('simple_json_api.render_403.detail')
        )
        render json: errors.to_json, status: 403
      end

      # Render 404 json and status. Message customizable (see class description).
      def render_404(_exception = nil)
        errors = SimpleJsonApi.errors(
          status: 404,
          title: I18n.t('simple_json_api.render_404.title'),
          detail: I18n.t('simple_json_api.render_404.detail', name: _i18n_name)
        )
        render json: errors.to_json, status: 404
      end

      # Render 409 json and status. Message customizable (see class description).
      def render_409(_exception = nil)
        errors = SimpleJsonApi.errors(
          status: 409,
          title: I18n.t('simple_json_api.render_409.title'),
          detail: I18n.t('simple_json_api.render_409.detail', name: _i18n_name)
        )
        render json: errors.to_json, status: 409
      end

      # Render 422 json and status. For model validation error.
      def render_422(object)
        errors = SimpleJsonApi.validation_errors(object)
        render json: errors.to_json, status: 422
      end

      # Render 500 json. Logs exception.
      def render_500(exception = nil)
        SimpleJsonApi.logger.error(exception.try(:message))
        SimpleJsonApi.logger.error(exception.try(:backtrace))

        errors = SimpleJsonApi.errors(
          status: 500,
          title: I18n.t('simple_json_api.render_500.title'),
          detail: I18n.t('simple_json_api.render_500.detail')
        )
        render json: errors.to_json, status: 500
      end

      # Render 406 status code and message that the format is not supported.
      def render_unknown_format
        format = sanitize(params[:format]) || ''
        errors = SimpleJsonApi.errors(
          status: 406,
          title: I18n.t('simple_json_api.render_unknown_format.title'),
          detail: I18n.t('simple_json_api.render_unknown_format.detail', name: format)
        )
        render json: errors.to_json, status: 406
      end

      # Render 503 json and status (service unavailable).
      def render_503(message = nil)
        errors = SimpleJsonApi.errors(
          status: 500,
          title: I18n.t('simple_json_api.render_503.title'),
          detail: message || I18n.t('simple_json_api.render_503.detail')
        )
        render json: errors.to_json, status: 503
      end

      private

      def sanitize(string)
        ActionController::Base.helpers.sanitize(string.to_s)
      end

      def _i18n_name
        I18n.t("simple_json_api.controller.#{controller_name}.name", raise: true)
      rescue
        I18n.t('simple_json_api.variables.defaults.name')
      end
    end
  end
end
