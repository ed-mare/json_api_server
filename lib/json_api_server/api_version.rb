module JsonApiServer # :nodoc:
  # JSON API version number. Currently 1.0.
  module ApiVersion
    def jsonapi
      { 'version' => '1.0' }
    end
  end
end
