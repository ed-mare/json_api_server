require 'bigdecimal'
require 'bigdecimal/util'
require 'date_core' # DateTime

#--
# TODO: verify it works in Rails, esp in_time_zone.
#++
module SimpleJsonApi # :nodoc:
  # Converts string params to data types.
  class Cast
    class << self
      def to(value, type = 'String')
        case type.to_s
        when 'String'
          apply_cast(value, :to_string)
        when 'Integer'
          apply_cast(value, :to_integer)
        when 'Date'
          apply_cast(value, :to_date)
        when 'DateTime'
          apply_cast(value, :to_datetime)
        when 'Float'
          apply_cast(value, :to_float)
        when 'BigDecimal'
          apply_cast(value, :to_decimal)
        else
          apply_cast(value, :to_string)
        end
      end

      # Calls to_s on object.
      def to_string(string)
        string.to_s
      end

      # Calls to_i on object. Returns zero if it can't be converted.
      def to_integer(string)
        string.to_i
      rescue
        0
      end

      # Calls to_f on object. Returns zero if it can't be converted.
      def to_float(string)
        string.to_f
      rescue
        0.0
      end

      # Converts to BigDecimal and calls to_f on it. Returns
      # zero if it can't be converted.
      def to_decimal(string)
        d = BigDecimal.new(string)
        d.to_f
      rescue
        0.0
      end

      # Calls Date.parse on string.
      # https://ruby-doc.org/stdlib-2.4.0/libdoc/date/rdoc/Date.html#method-c-parse
      def to_date(string)
        Date.parse(string)
      rescue
        nil
      end

      # Calls DateTime.parse on string. If datetime responds to
      # :in_time_zone[http://apidock.com/rails/v4.2.1/ActiveSupport/TimeWithZone/in_time_zone)],
      # it calls it.
      def to_datetime(string)
        d = DateTime.parse(string)
        d.respond_to?(:in_time_zone) ? d.in_time_zone : d
      rescue
        nil
      end

      protected

      # If val is an array, it casts each value. Otherwise, it casts the value.
      def apply_cast(val, cast_method)
        if val.respond_to?(:map)
          val.map { |v| send(cast_method, v) }
        else
          send(cast_method, val)
        end
      end
    end
  end
end
