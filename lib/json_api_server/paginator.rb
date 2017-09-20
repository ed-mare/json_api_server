module JsonApiServer # :nodoc:
  # Creates JSON API pagination entries per http://jsonapi.org/examples/#pagination.
  #
  # JsonApiServer::Paginator#as_json generates a hash like the following which can be
  # added to JsonApiServer::BaseSerializer#links section.
  #
  # - 'next' is nil when self is the last page.
  # - 'prev' is nil when self is the first page.
  #
  # ===== Example:
  #  "links": {
  #    "self": "http://example.com/articles?page[number]=3&page[limit]=5",
  #    "first": "http://example.com/articles?page[number]=1&page[limit]=5",
  #    "prev": "http://example.com/articles?page[number]=2&page[limit]=5",
  #    "next": "http://example.com/articles?page[number]=4&page[limit]=5",
  #    "last": "http://example.com/articles?page[number]=13&page[limit]=5"
  #  }
  class Paginator
    @attrs = %w[first last self next prev]

    # Params:
    # - <tt>current_page</tt> (Integer)
    # - <tt>total_pages</tt> (Integer)
    # - <tt>per_page</tt> (Integer)
    # - <tt>base_url</tt> (String) - Base url for resource, i.e., <tt>http://example.com/articles</tt>.
    # - <tt>params</tt> (Hash) - Request parameters. Pagination params are merged into these.
    def initialize(current_page, total_pages, per_page, base_url, params = {})
      @current_page = current_page
      @total_pages = total_pages
      @per_page = per_page
      @base_url = base_url
      @params = params
    end

    class << self
      attr_accessor :attrs
    end

    # First page url.
    def first
      @first ||= build_url(merge_params(1))
    end

    # Last page url.
    def last
      @last ||= build_url(merge_params(@total_pages))
    end

    # Current page url.
    def self
      @self ||= build_url(merge_params(@current_page))
    end

    # Next page url.
    def next
      @next ||= begin
        n = calculate_next
        n.nil? ? nil : build_url(merge_params(n))
      end
    end

    # Previous page url.
    def prev
      @prev ||= begin
        p = calculate_prev
        p.nil? ? nil : build_url(merge_params(p))
      end
    end

    # Returns hash:
    #  # i.e.,
    #  {
    #   self: "http://example.com/articles?page[number]=3&page[limit]=5",
    #   first: "http://example.com/articles?page[number]=1&page[limit]=5",
    #   prev: "http://example.com/articles?page[number]=2&page[limit]=5",
    #   next: "http://example.com/articles?page[number]=4&page[limit]=5",
    #   last: "http://example.com/articles?page[number]=13&page[limit]=5"
    #  }
    def as_json
      self.class.attrs.each_with_object({}) { |attr, acc| acc[attr] = send(attr); }
    end

    alias to_h as_json

    # Hash with pagination meta information. Useful for user interfaces, i.e.,
    # 'page #{current_page} of #{total_pages}'.
    #
    #  #i.e.,
    #  {
    #    links: {
    #        current_page: 2,
    #        total_pages: 13,
    #        per_page: 5
    #    }
    #  }
    def meta_info
      {
        'links' => {
          'current_page' => @current_page,
          'total_pages' => @total_pages,
          'per_page' => @per_page
        }
      }
    end

    protected

    # Merges pagination params with request params. Pagination params look like
    # this to page[number]=x&page[limit]=y.
    def merge_params(number)
      @params.merge(page: { number: number, limit: @per_page })
    end

    # Merges base_url with modified params. Params are Url encoded, i.e.,
    # page%5Blimit%5D=5&page%5Bnumber%5D=1
    def build_url(params)
      "#{@base_url}?#{params.to_query}"
    end

    # Calculates next page. Returns nil when value is invalid, i.e.,
    # exceeds total_pages.
    def calculate_next
      n = @current_page + 1
      n > @total_pages || n <= 0 ? nil : n
    end

    # Calculates previous page. Returns nil if value is invalid, i.e.,
    # less than or equal to 0.
    def calculate_prev
      p = @current_page - 1
      p <= 0 || p > @total_pages ? nil : p
    end
  end
end
