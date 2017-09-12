require 'spec_helper'

describe SimpleJsonApi::Cast do
  describe '.to_string' do
    it 'calls to_s on object' do
      expect(SimpleJsonApi::Cast.to_string(nil)).to eq('')
      expect(SimpleJsonApi::Cast.to_string(1)).to eq('1')
      expect(SimpleJsonApi::Cast.to_string([1, 2, 3])).to eq('[1, 2, 3]')
      expect(SimpleJsonApi::Cast.to_string('my string')).to eq('my string')
    end
  end

  describe '.to_integer' do
    it 'calls to_i on object' do
      expect(SimpleJsonApi::Cast.to_integer(nil)).to eq(0)
      expect(SimpleJsonApi::Cast.to_integer('')).to eq(0)
      expect(SimpleJsonApi::Cast.to_integer('1')).to eq(1)
      expect(SimpleJsonApi::Cast.to_integer('-1')).to eq(-1)
      expect(SimpleJsonApi::Cast.to_integer('my string')).to eq(0)
    end

    it 'returns zero when it cannot be cast' do
      expect(SimpleJsonApi::Cast.to_integer([1, 2, 3])).to eq(0)
    end
  end

  describe '.to_float' do
    it 'calls to_f on object' do
      expect(SimpleJsonApi::Cast.to_float(nil)).to be(0.0)
      expect(SimpleJsonApi::Cast.to_float('')).to be(0.0)
      expect(SimpleJsonApi::Cast.to_float('1')).to be(1.0)
      expect(SimpleJsonApi::Cast.to_float('-1.226945')).to be(-1.226945)
      expect(SimpleJsonApi::Cast.to_float('my string')).to be(0.0)
    end

    it 'returns zero when it cannot be cast' do
      expect(SimpleJsonApi::Cast.to_float([1, 2, 3])).to be(0.0)
    end
  end

  describe '.to_decimal' do
    it 'calls Decimal.new(value).to_f on object' do
      expect(SimpleJsonApi::Cast.to_decimal('')).to be(0.0)
      expect(SimpleJsonApi::Cast.to_decimal('1')).to be(1.0)
      expect(SimpleJsonApi::Cast.to_decimal('-123.45678901234567890')).to be(-123.45678901234568)
      expect(SimpleJsonApi::Cast.to_decimal('my string')).to be(0.0)
    end

    it 'returns zero when it cannot be cast' do
      expect(SimpleJsonApi::Cast.to_decimal([1, 2, 3])).to be(0.0)
      expect(SimpleJsonApi::Cast.to_decimal(nil)).to be(0.0)
    end
  end

  describe '.to_date' do
    it 'calls Date.parse on object' do
      expect(SimpleJsonApi::Cast.to_date('2017-03-17')).to eq(Date.new(2017, 3, 17))
      expect(SimpleJsonApi::Cast.to_date('20170317T203909Z')).to eq(Date.new(2017, 3, 17))
      expect(SimpleJsonApi::Cast.to_date('2017-03-17T20:39:09+00:00')).to eq(Date.new(2017, 3, 17))
      expect(SimpleJsonApi::Cast.to_date('2017-03-17T20:39:09Z')).to eq(Date.new(2017, 3, 17))
    end

    it 'returns nil when it cannot be cast' do
      expect(SimpleJsonApi::Cast.to_date('')).to eq(nil)
      expect(SimpleJsonApi::Cast.to_date('[1,2,3]')).to eq(nil)
      expect(SimpleJsonApi::Cast.to_date(nil)).to eq(nil)
    end
  end

  describe '.to_datetime' do
    it 'calls DateTime.parse on object' do
      dt = DateTime.new(2001, 2, 3, 4, 5, 6)
      dt_tz_offset = DateTime.new(2001, 2, 3, 4, 5, 6, '-08:00')
      dt_wo_time = DateTime.new(2001, 2, 3)
      expect(SimpleJsonApi::Cast.to_datetime('2001-02-03T04:05:06+00:00')).to eq(dt)
      expect(SimpleJsonApi::Cast.to_datetime('2001-02-03T04:05:06-08:00')).to eq(dt_tz_offset)
      expect(SimpleJsonApi::Cast.to_datetime('2001-02-03')).to eq(dt_wo_time)
    end

    it 'returns nil when it cannot be cast' do
      expect(SimpleJsonApi::Cast.to_datetime('')).to eq(nil)
      expect(SimpleJsonApi::Cast.to_datetime('[1,2,3]')).to eq(nil)
      expect(SimpleJsonApi::Cast.to_datetime(nil)).to eq(nil)
    end
  end

  describe '.to' do
    it 'defaults to string' do
      expect(SimpleJsonApi::Cast.to(123)).to eq('123')
      expect(SimpleJsonApi::Cast.to(123, 'UnkownType')).to eq('123')
    end

    it 'casts input to specified type' do
      expect(SimpleJsonApi::Cast.to('123', 'Integer')).to be(123)
      expect(SimpleJsonApi::Cast.to(123, 'String')).to eq('123')
      expect(SimpleJsonApi::Cast.to('-1.226945', 'Float')).to be(-1.226945)
      expect(SimpleJsonApi::Cast.to('-123.45678901234567890', 'BigDecimal')).to be(-123.45678901234568)
      expect(SimpleJsonApi::Cast.to('20170317T203909Z', 'Date')).to eq(Date.new(2017, 3, 17))
      expect(SimpleJsonApi::Cast.to('2001-02-03T04:05:06-08:00', 'DateTime')).to eq(DateTime.new(2001, 2, 3, 4, 5, 6, '-08:00'))
    end

    it 'casts each element in an array to specified type' do
      expect(SimpleJsonApi::Cast.to(%w[1 2 3], 'Integer')).to eq([1, 2, 3])
      expect(SimpleJsonApi::Cast.to([1, 2, 3], 'String')).to eq(%w[1 2 3])
      expect(SimpleJsonApi::Cast.to(['-1.226945', '3.145987'], 'Float')).to eq([-1.226945, 3.145987])
      expect(SimpleJsonApi::Cast.to(['-123.45678901234567890', '345.8740109'], 'BigDecimal'))
        .to eq([-123.45678901234568, 345.8740109])
      expect(SimpleJsonApi::Cast.to(['20170317T203909Z', '2017-03-18T20:39:09+00:00'], 'Date'))
        .to eq([Date.new(2017, 3, 17), Date.new(2017, 3, 18)])
      expect(SimpleJsonApi::Cast.to(['2001-02-03T04:05:06-08:00', '2001-02-03T04:05:06+00:00'], 'DateTime'))
        .to eq([DateTime.new(2001, 2, 3, 4, 5, 6, '-08:00'), DateTime.new(2001, 2, 3, 4, 5, 6)])
    end
  end
end
