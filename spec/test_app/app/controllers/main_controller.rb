class MainController < ApplicationController
  include SimpleJsonApi::Controller::ErrorHandling

  def index
    render text: 'I am main.'
  end
end
