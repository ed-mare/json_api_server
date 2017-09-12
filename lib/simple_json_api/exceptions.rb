module SimpleJsonApi # :nodoc:
  # Exception thrown when something unsupported is requested, i.e., sort
  # by a field that's not supported. If SimpleJsonApi::Controller::ErrorHandling
  # is included in the controller, it will rescue and render a 400 error.
  class BadRequest < StandardError; end
end
