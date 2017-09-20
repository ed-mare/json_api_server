module JsonApiServer # :nodoc:
  # Class for building meta element.
  # http://jsonapi.org/format/#document-meta
  #
  # ==== Example
  #
  #  MetaBuilder.new
  #   .add('copyright', "Copyright 2015 Example Corp.")
  #   .add('authors', ["Yehuda Katz", "Steve Klabnik", "Dan Gebhardt", "Tyler Kellen"])
  #   .merge({a: 'something', b: 'something else'})
  #   .meta  # => { "copyright": "Copyright 2015 Example Corp.",
  #                  "authors": ["Yehuda Katz", "Steve Klabnik", "Dan Gebhardt", "Tyler Kellen"],
  #                  a: 'something',
  #                  b: 'something else'
  #               }
  #
  class MetaBuilder
    def initialize
      @hash = {}
    end

    # Add key and value.
    def add(key, value)
      @hash[key] = value
      self
    end

    # Push in multiple key/values with merge.
    def merge(hash)
      @hash.merge!(hash) if hash.respond_to?(:keys) && hash.any?
      self
    end

    # Returns a hash if it has values, nil otherwise.
    def meta
      @hash.any? ? @hash : nil
    end
  end
end
