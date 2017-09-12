module SimpleJsonApi # :nodoc:
  # Base filter/query builder class. All should inherit from this class.
  class FilterBuilder
    # The filter attribute, i.e., filter[foo]
    attr_reader :attr
    # Casted value(s). If value included a common, an array of casted values.
    attr_reader :value
    # Instance of FilterConfig for the specific attribute/column.
    attr_reader :config
    # Column name in the database. Specified when the filter name in the query doesn't
    # match the column name in the database.
    attr_reader :column_name
    # Can be IN, <, >, <=, etc.
    attr_reader :operator

    def initialize(attr, value, operator, config)
      @attr = attr
      @value = value
      @config = config
      @column_name = @config.column_name
      @operator = operator
    end

    # Subclasses must implement. Can return an ActiveRecord::Relation or
    # nil.
    def to_query(_model)
      raise 'subclasses should implement this method.'
    end

    protected

    def full_column_name(model)
      "\"#{model.table_name}\".\"#{column_name}\""
    end

    # Delegate to protected method ActiveRecord::Base.sanitize_sql.
    # def sanitize_sql(condition)
    #   ActiveRecord::Base.send(:sanitize_sql, condition)
    # end

    # For queries where wildcards are appropriate. Adds wildcards
    # based on filter's configs.
    def add_wildcards(value)
      return value unless value.present?

      case config.wildcard
      when :left
        return "%#{value}"
      when :right
        return "#{value}%"
      when :both
        return "%#{value}%"
      else # none by default
        return value
      end
    end
  end

  # Query equality builder. i.e.. where(foo: 'bar').
  class SqlEql < FilterBuilder
    def to_query(model)
      model.where("#{full_column_name(model)} = ?", value)
    end
  end

  # Query comparison builder, .i.e., where('id > ?', '22').
  class SqlComp < FilterBuilder
    def self.allowed_operators
      ['=', '<', '>', '>=', '<=', '!=']
    end

    def to_query(model)
      if self.class.allowed_operators.include?(operator)
        model.where("#{full_column_name(model)} #{operator} ?", value)
      end
    end
  end

  # Query IN builder, .i.e., where('id IN (?)', [1,2,3]).
  class SqlIn < FilterBuilder
    def to_query(model)
      model.where("#{full_column_name(model)} IN (?)", value)
    end
  end

  # Query LIKE builder, .i.e., where('title LIKE ?', '%foo%').
  # Wildcards are added based on configs. Defaults to '%<value>%'
  class SqlLike < FilterBuilder
    def to_query(model)
      val = add_wildcards(value)
      model.where("#{full_column_name(model)} LIKE ?", val)
    end
  end

  # Query ILIKE builder, .i.e., where('title ILIKE ?', '%foo%').
  # Wildcards are added based on configs. Defaults to '%<value>%'
  # Postgres only. Case insensitive search.
  class PgIlike < FilterBuilder
    def to_query(model)
      val = add_wildcards(value)
      model.where("#{full_column_name(model)} ILIKE :val", val: val)
    end
  end

  # Searches a jsonb array ['foo', 'bar'].  If multiple values passed, it performs
  # an OR search ?|. Case sensitive search.
  # Postgres only.
  class PgJsonbArray < FilterBuilder
    #--
    # http://stackoverflow.com/questions/30629076/how-to-escape-the-question-mark-operator-to-query-postgresql-jsonb-type-in-r
    # https://www.postgresql.org/docs/9.4/static/functions-json.html
    #++
    def to_query(model)
      model.where("#{full_column_name(model)} ?| array[:name]", name: value)
    end
  end

  # Searches a jsonb array ['foo', 'bar']. The array is returned as text. It performs an
  # ILIKE %value%. Does not work with multiple values.
  # Postgres only.
  class PgJsonbIlikeArray < FilterBuilder
    def to_query(model)
      val = add_wildcards(value)
      model.where("#{full_column_name(model)}::text ILIKE :name", name: val)
    end
  end

  # Call a model singleton method to perform the query.
  class ModelQuery < FilterBuilder
    def to_query(model)
      method = config.method
      model.send(method, value) if method.present?
    end
  end
end
