module SimpleJsonApi # :nodoc:
  # === Description
  #
  # JSON API Spec: http://jsonapi.org/format/#fetching-pagination - "Pagination links MUST
  # appear in the links object that corresponds to a collection. To paginate the primary data,
  # supply pagination links in the top-level links object."
  #
  # This class handles pagination. It (1) ensures <tt>page[number]</tt> is a positive integer,
  # (2) <tt>page[limit]</tt> doesn't exceed a maximum value and (3) generates a pagination sub-query
  # (to be merged into a master query). It uses the WillPaginate gem
  # https://rubygems.org/gems/will_paginate/versions/3.1.6.
  #
  # === Usage:
  #
  # A paginating request will look like:
  #   /comments?page[number]=1&page[limit]=10
  #
  # Where:
  #
  # - <b><tt>page[number]</tt></b> is the current page
  #
  # - <b><tt>page[limit]</tt></b> is number of records per page
  #
  # The class takes an ActiveDispatch::Request object, an ActiveRecord::Base model
  # (to generate a pagination sub-query) and two options:
  #
  # <b><tt>:max_per_page</tt></b> - maximum number of records per page which defaults to
  # SimpleJsonApi::Configuration#default_max_per_page.
  #
  # <b><tt>:default_per_page</tt></b> - number of records to show if not specified in <tt>page[limit]</tt>
  # defaults to SimpleJsonApi::Configuration#default_per_page).
  #
  # ===== Example:
  #
  # Create an instance in your controller:
  #
  #  pagination = SimpleJsonApi::Pagination.new(request, Comment, max_per_page: 50, default_per_page: 10)
  #
  # Merge pagination sub-query into your ActiveRecord query:
  #
  #   recent_comments = Comment.recent.merge(pagination.query)
  #
  # Get SimpleJsonApi::Paginator instance to create links in your JSON serializer:
  #
  #   paginator = pagination.paginator_for(recent_comments)
  #   paginator.as_json # creates JSON API links
  #
  # Pass paginator as param to a class inheriting from SimpleJsonApi::ResourcesSerializer and
  # it creates the links section for you.
  #
  #  class CommentsSerializer < SimpleJsonApi::ResourcesSerializer
  #    serializer CommentSerializer
  #  end
  #   serializer = CommentsSerializer.new(recent_comments, paginator: paginator)
  #
  # ==== Note:
  # SimpleJsonApi::Builder class provides an easier way to use this class.
  #
  class Pagination
    # ActionDispatch::Request passed in constructor.
    attr_reader :request

    # ActiveRecord::Base model passed in constructor.
    attr_reader :model

    # Query parameters from #request.
    attr_reader :params

    # Maximum records per page. Prevents users from requesting too many records. Passed
    # into constructor.
    attr_reader :max_per_page

    # Default number of records to show per page. If <tt>page[limit]</tt> is not present, it
    # will use this value. If this is not set, it will use
    # SimpleJsonApi.configuration.default_per_page.
    attr_reader :default_per_page

    # Arguments:
    # - <tt>request</tt> - ActionDispatch::Request
    # - <tt>model</tt> - ActiveRecord::Base model. Used to generate sub-query.
    # - <tt>options</tt> - (Hash)
    #   - :max_per_page (Integer) - Optional. Defaults to SimpleJsonApi.configuration.default_max_per_page.
    #   - :default_per_page (Integer) - Optional. Defaults to SimpleJsonApi.configuration.default_per_page.
    #
    def initialize(request, model, **options)
      @request = request
      @model = model
      @max_per_page = (options[:max_per_page] || self.class.default_max_per_page).to_i
      @default_per_page = (options[:default_per_page] || self.class.default_per_page).to_i
      @params = request.query_parameters
    end

    # Calls WillPaginate 'paginate' method with #page and #per_page. Returns an
    # ActiveRecord::Relation object (a query fragment) which can be
    # merged into another query with merge.
    #
    # ==== Example:
    #
    #  pagination = SimpleJsonApi::Pagination.new(request, Comment, options)
    #  recent_comments = Comment.recent.merge(pagination.relation)
    #
    def relation
      @relation ||= model.paginate(page: page, per_page: per_page)
    end

    alias query relation

    class << self
      # Default max per page. Defaults to SimpleJsonApi.configuration.default_max_per_page
      def default_max_per_page
        SimpleJsonApi.configuration.default_max_per_page
      end

      # Default per page. Defaults to SimpleJsonApi.configuration.default_per_page.
      def default_per_page
        SimpleJsonApi.configuration.default_per_page
      end
    end

    # Create an instance of SimpleJsonApi::Paginator for a WillPaginate collection. Returns
    # nil if not a WillPaginate collection.
    #
    # params:
    # - <tt>collection</tt> (WillPaginate collection) - i.e., Comment.recent.paginate(page: x, per_page: y)
    # - <tt>options</tt> (Hash):
    #  - <tt>per_page</tt> (Integer) - defaults to self.per_page.
    #  - <tt>base_url</tt> (String) - defaults to self.base_url (joins SimpleJsonApi.configuration.base_url with request.path).
    def paginator_for(collection, options = {})
      if collection.respond_to?(:current_page) && collection.respond_to?(:total_pages)
        # call to_i on WillPaginate::PageNumber which DelegateClass(Integer)
        # paginator(collection.current_page.to_i, collection.total_pages.to_i, options)
        # HACK: collection.current_page.to_i disappears when merged? works w/o merge.
        paginator(page, collection.total_pages.to_i, options)
      end
    end

    # Number of records per page. From query parameter <tt>page[limit]</tt>.
    def per_page
      @per_page ||= begin
        l = begin
              params[:page][:limit].to_i
            rescue
              default_per_page
            end
        l = [max_per_page, l].min
        l <= 0 ? default_per_page : l
      end
    end

    alias limit per_page

    # The current page number. From query parameter page[number]</tt>.
    def page
      @page ||= begin
        n = begin
              params[:page][:number].to_i
            rescue
              1
            end
        n <= 0 ? 1 : n
      end
    end

    alias number page

    # Joins SimpleJsonApi::Configuration#base_url with request.path.
    def base_url
      @base_url ||= File.join(SimpleJsonApi.configuration.base_url, request.path)
    end

    protected

    # Creates an instance of SimpleJsonApi::Paginator.
    #
    # params:
    # - <tt>current_page</tt> (Integer)
    # - <tt>total_pages</tt> (Integer)
    # - <tt>options</tt> (Hash):
    #  - <tt>per_page</tt> (Integer) - defaults to self.per_page.
    #  - <tt>base_url</tt> (String) - defaults to self.base_url (joins
    #                   SimpleJsonApi::Configuration#base_url with request.path.).
    def paginator(current_page, total_pages, options = {})
      per_page = options[:per_page] || self.per_page
      base_url = options[:base_url] || self.base_url
      SimpleJsonApi.paginator(current_page, total_pages, per_page,
                              base_url, params)
    end
  end
end
