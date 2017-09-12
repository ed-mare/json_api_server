require 'rails_helper'

class ApplicationController < ActionController::Base
  include SimpleJsonApi::Controller::ErrorHandling
end

# For testing custom locales variables.
class LocalesController < ApplicationController; end

RSpec.describe SimpleJsonApi::Controller::ErrorHandling, type: :controller do
  describe 'rescue_from StandardError' do
    controller do
      def index
        raise '500 error'
      end
    end

    it 'renders with render_500' do
      get :index
      expect(response).to have_http_status(500)

      # {
      #   ":jsonapi": {
      #     ":version": "1.0"
      #   },
      #   ":errors": [
      #     {
      #       ":status": 500,
      #       ":title": "Internal Server Error",
      #       ":detail": "The server encountered an unexpected error."
      #     }
      #   ]
      # }

      expected_body = SimpleJsonApi.errors(
        status: 500,
        title: 'Internal Server Error',
        detail: 'The server encountered an unexpected error.'
      ).to_json

      expect(response.body).to be_same_json_as(expected_body)
    end
  end

  describe 'rescue_from ActiveRecord::RecordNotFound' do
    controller do
      def index
        raise ActiveRecord::RecordNotFound
      end
    end

    it 'renders with render_404' do
      get :index
      expect(response).to have_http_status(404)

      # {
      #   ":jsonapi": {
      #     ":version": "1.0"
      #   },
      #   ":errors": [
      #     {
      #       ":status": 500,
      #       ":title": "Not Found",
      #       ":detail": "This resource does not exist."
      #     }
      #   ]
      # }

      expected_body = SimpleJsonApi.errors(
        status: 404,
        title: 'Not Found',
        detail: 'This resource does not exist.'
      ).to_json

      expect(response.body).to be_same_json_as(expected_body)
    end
  end

  describe 'rescue_from ActiveRecord::RecordNotUnique' do
    controller do
      def index
        raise ActiveRecord::RecordNotUnique
      end
    end

    it 'renders with render_409' do
      get :index
      expect(response).to have_http_status(409)

      # {
      #   ":jsonapi": {
      #     ":version": "1.0"
      #   },
      #   ":errors": [
      #     {
      #       ":status": 409,
      #       ":title": "Conflict",
      #       ":detail": "This resource already exists."
      #     }
      #   ]
      # }

      expected_body = SimpleJsonApi.errors(
        status: 409,
        title: 'Conflict',
        detail: 'This resource already exists.'
      ).to_json

      expect(response.body).to be_same_json_as(expected_body)
    end
  end

  describe 'rescue_from ActionController::UrlGenerationError' do
    controller do
      before_action { |_c| raise ActionController::UrlGenerationError }
      def index; end
    end

    it 'renders with render_404' do
      get :index
      expect(response).to have_http_status(404)

      # {
      #   ":jsonapi": {
      #     ":version": "1.0"
      #   },
      #   ":errors": [
      #     {
      #       ":status": 500,
      #       ":title": "Not Found",
      #       ":detail": "This resource does not exist."
      #     }
      #   ]
      # }

      expected_body = SimpleJsonApi.errors(
        status: 404,
        title: 'Not Found',
        detail: 'This resource does not exist.'
      ).to_json

      expect(response.body).to be_same_json_as(expected_body)
    end
  end

  describe 'rescue_from ActionController::RoutingError' do
    controller do
      def index; end
    end

    it 'renders with render_404' do
      pending('How to trigger an ActionController::RoutingError error?')
      get 'idontexist'
      expect(response).to have_http_status(404)

      # {
      #   ":jsonapi": {
      #     ":version": "1.0"
      #   },
      #   ":errors": [
      #     {
      #       ":status": 500,
      #       ":title": "Not Found",
      #       ":detail": "This resource does not exist."
      #     }
      #   ]
      # }

      expected_body = SimpleJsonApi.errors(
        status: 404,
        title: 'Not Found',
        detail: 'This resource does not exist.'
      ).to_json

      expect(response.body).to be_same_json_as(expected_body)
    end
  end

  describe 'rescue_from ActionController::UnknownFormat' do
    controller do
      before_action { |_c| raise ActionController::UnknownFormat }
      def index; end
    end

    it 'renders with render_unkown_format' do
      get :index, format: 'html'
      expect(response).to have_http_status(406)

      # {
      #   ":jsonapi": {
      #     ":version": "1.0"
      #   },
      #   ":errors": [
      #     {
      #       ":status": 406,
      #       ":title": "Unknown Format",
      #       ":detail": "Format %{name} is not supported for this endpoint."
      #     }
      #   ]
      # }

      expected_body = SimpleJsonApi.errors(
        status: 406,
        title: 'Unknown Format',
        detail: 'Format html is not supported for this endpoint.'
      ).to_json

      expect(response.body).to be_same_json_as(expected_body)
    end
  end

  describe 'rescue_from ActionController::UnknownController' do
    controller do
      before_action { |_c| raise ActionController::UnknownController }
      def index; end
    end

    it 'renders with render_404' do
      get :index, format: 'html'
      expect(response).to have_http_status(404)

      expected_body = SimpleJsonApi.errors(
        status: 404,
        title: 'Not Found',
        detail: 'This resource does not exist.'
      ).to_json

      expect(response.body).to be_same_json_as(expected_body)
    end
  end

  describe 'rescue_from SimpleJsonApi::BadRequest' do
    controller do
      before_action { |_c| raise SimpleJsonApi::BadRequest, 'Filter param foo is not supported.' }
      def index; end
    end

    it 'renders with render_400' do
      get :index
      expect(response).to have_http_status(400)

      # {
      #   ":jsonapi": {
      #     ":version": "1.0"
      #   },
      #   ":errors": [
      #     {
      #       ":status": 400,
      #       ":title": "Bad Request",
      #       ":detail": "Filter param foo is not supported."
      #     }
      #   ]
      # }

      expected_body = SimpleJsonApi.errors(
        status: 400,
        title: 'Bad Request',
        detail: 'Filter param foo is not supported.'
      ).to_json

      expect(response.body).to be_same_json_as(expected_body)
    end
  end

  describe 'I18n' do
    # test_app/config/locales/en.yml:
    #
    # en:
    #   hello: "Hello world"
    #   simple_json_api:
    #     controller:
    #       locales:
    #         name: 'sandwich'

    controller(LocalesController) do
      def index
        raise ActiveRecord::RecordNotUnique
      end

      def show
        raise ActiveRecord::RecordNotFound
      end
    end

    it 'picks up custom locales variable :name for RecordNotUnique' do
      get :index
      # puts response.body
      expect(response).to have_http_status(409)

      expected_body = SimpleJsonApi.errors(
        status: 409,
        title: 'Conflict',
        detail: 'This sandwich already exists.'
      ).to_json

      expect(response.body).to be_same_json_as(expected_body)
    end

    it 'picks up custom locales variable :name for RecordNotFound' do
      get :show, params: { id: 2 }
      # puts response.body
      expect(response).to have_http_status(404)

      expected_body = SimpleJsonApi.errors(
        status: 404,
        title: 'Not Found',
        detail: 'This sandwich does not exist.'
      ).to_json

      expect(response.body).to be_same_json_as(expected_body)
    end
  end
end
