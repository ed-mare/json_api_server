class FakeRequest
  attr_reader :query_parameters, :path

  def initialize(query_parameters, path = '/fake')
    @query_parameters = query_parameters.try(:with_indifferent_access)
    @path = path
  end
end
