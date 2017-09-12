module SimpleJsonApi # :nodoc:
  class MyCustomFilter < FilterBuilder
    def to_query(model)
      model.where("#{column_name} LIKE :val", val: "%#{value}%")
    end
  end
end

SimpleJsonApi.configure do |c|
  c.base_url = 'http://localhost:3001'
  c.filter_builders = c.filter_builders.merge(my_custom_builder: SimpleJsonApi::MyCustomFilter)
  c.logger = Rails.logger
end
