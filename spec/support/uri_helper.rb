require 'cgi'
require 'uri'

module UriHelper
  # Returns something like {"filter[published]"=>[">1998-01-01"], "filter[published1]"=>["<1999-12-31"],
  #     page[limit]"=>["4"], "page[number]"=>["1"], "sort"=>["-location"]}
  def query_params_from(uri)
    CGI.parse(URI.parse(uri).query)
  end
end
