module JsonApiServer # :nodoc:
  # Configs that can be specified in a controller to enable sorting on attributes.
  # Specify permitted attributes for sorting. If an alias is used instead of an
  # attribute name, it can be mapped (see :created in example below).
  #
  # Example sort configuration:
  #
  # before_action do |c|
  #   c.sort_options = {
  #     permitted: [
  #       :id,
  #       :body,
  #       { created: { col_name: :created_at} }
  #     ],
  #     default: { id: :desc }
  #   }
  # end
  #
  # Config requirements - :permitted, :col_name and :default must be symbols.
  class SortConfigs
    # Config - permitted
    def initialize(configs)
      @configs = configs
    end

    # Attributes API users can sort against. Arrray of hashes -
    # [{attr: <required - attr as string>, col_name: <optional key - database column name as string> }, ...]
    def permitted
      @permitted ||= begin
        return [] unless @configs[:permitted].is_a?(Array)
        @configs[:permitted].map { |c| configs_from(c) }
      end
    end

    # Returns the config spec for an attributes. Returns nil if attribute
    # isn't permitted.
    def config_for(attr)
      permitted.find { |elem| elem[:attr] == attr.to_s }
    end

    def permitted?(attr)
      config_for(attr.to_s) != nil
    end

    # Default order specified in 'options' accessor. Specify ActiveRecord order params,
    # i.e., { id: :desc }
    # Defaults to empty array if none specified.
    def default_order
      @default = @configs[:default] || []
    end

    protected

    def configs_from(config)
      if config.respond_to?(:keys)
        key, value = config.first
        { attr: key.to_s, col_name: (value[:col_name] || key).to_s }
      else
        { attr: config.to_s }
      end
    end
  end
end
