#--
# TODO: https://github.com/ohler55/oj/issues/199
#++
module JsonApiServer # :nodoc:
  # ==== Description
  #
  # to_json serializer method. Used by the various serializers.
  module Serializer
    # Serializer options from JsonApiServer::Configuration#serializer_options.
    def serializer_options
      JsonApiServer.configuration.serializer_options
    end

    # Classes override.
    def as_json
      {}
    end

    # Serializes to JSON. Serializer options default to
    # JsonApiServer.configuration.serializer_options unless
    # alternate are specified with the <tt>options</tt> parameter.
    # Default options are:
    #   escape_mode: :xss_safe,
    #   time: :xmlschema,
    #   mode: :compat
    #
    # Parameters:
    # - options (Hash) - OJ serialization options: https://github.com/ohler55/oj#options. If none specified, it uses defaults.
    def to_json(**options)
      opts = options.empty? ? serializer_options : options
      Oj.dump(as_json, opts)
    end
  end
end
