class MainController < ApplicationController
  include JsonApiServer::Controller::ErrorHandling

  def index
    render text: 'I am main.'
  end
end
