module JsonHelper
  def load_json(json, options = {})
    Oj.load(json, with_options(options))
  end

  def dump_json(hash, options = {})
    Oj.dump(hash, with_options(options))
  end

  def default_serializer_options
    JsonApiServer::Configuration::DEFAULT_SERIALIZER_OPTIONS
  end

  protected

  def with_options(options)
    options && options.empty? ? default_serializer_options : options
  end
end
