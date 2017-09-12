#++
# NOTE: it can cause issues in browsers: https://github.com/json-api/json-api/issues/1048
# __
module SimpleJsonApi # :nodoc:
  # http://jsonapi.org/format/#introduction -> JSON API requires use of the JSON API
  # media type (application/vnd.api+json) for exchanging data.
  #
  # Include this module in your config/initializers/mime_types.rb
  #
  # i.e,:
  #  # in config/initializers/mime_types.rb
  #  include SimpleJsonApi::MimeTypes
  module MimeTypes
    api_mime_types = %w[
      application/vnd.api+json
      text/x-json
      application/json
    ]
    Mime::Type.register 'application/vnd.api+json', :json, api_mime_types
  end
end
