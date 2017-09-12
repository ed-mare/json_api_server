require 'rspec/expectations'

module CustomMatchers
  extend RSpec::Matchers::DSL
  include JsonHelper
  include UriHelper

  # i.e., expect(response.body).to be_same_json_as(expected_body)
  matcher :be_same_json_as do |expected|
    match { |actual| load_json(actual) == load_json(expected) }
  end

  # i.e., expect('http://foo/topics?page%5Blimit%5D=4&page%5Bnumber%5D=1').to have_query_parameter('filter[published]', '>1998-01-01')
  matcher :have_query_parameter do |expected_name, expected_value|
    match do |uri|
      # i.e., {"filter[published]"=>[">1998-01-01"], "filter[published1]"=>["<1999-12-31"], "page[limit]"=>["4"],
      # "page[number]"=>["1"], "sort"=>["-location"]}
      params = begin
                 query_params_from(uri)
               rescue
                 {}
               end
      params[expected_name].respond_to?(:include?) && params[expected_name].include?(expected_value)
    end
  end

  # Test if model record has preloaded association.
  # i.e., expect(comment).to have_loaded_association(:author).to eq(true) or
  # expect(topic).to have_loaded_association(:comments).to eq(true)
  matcher :have_loaded_association do |association|
    match { |record| record.association(association).instance_variable_get('@loaded') == true }
  end
end
