require 'spec_helper'

describe SimpleJsonApi::Configuration do
  let(:config) { SimpleJsonApi::Configuration.new }

  describe '#base_url' do
    it 'defaults to nil' do
      expect(config.base_url).to eq(nil)
    end
  end

  describe '#default_max_per_page' do
    it 'defaults to 100' do
      expect(config.default_max_per_page).to eq(100)
    end
  end

  describe '#default_per_page' do
    it 'defaults to 20' do
      expect(config.default_per_page).to eq(20)
    end
  end

  describe '#serializer_options' do
    it 'defaults Oj serializer options to XSS safe and iso8601 (date/time)' do
      expect(config.serializer_options).to eq(escape_mode: :xss_safe, time: :xmlschema, mode: :compat)
    end
  end

  describe '#default_like_builder' do
    it 'defaults to :sql_like filter builder' do
      expect(config.default_like_builder).to eq(:sql_like)
    end
  end

  describe '#default_in_builder' do
    it 'defaults to :sql_in filter builder' do
      expect(config.default_in_builder).to eq(:sql_in)
    end
  end

  describe '#default_comparison_builder' do
    it 'defaults to :sql_comparison filter builder' do
      expect(config.default_comparison_builder).to eq(:sql_comparison)
    end
  end

  describe '#default_builder' do
    it 'defaults to :sql_eql filter builder' do
      expect(config.default_builder).to eq(:sql_eql)
    end
  end

  describe '#filter_builders' do
    it 'includes all the standard filter builders' do
      expect(config.filter_builders).to eq(sql_eql: SimpleJsonApi::SqlEql,
                                           sql_comparison: SimpleJsonApi::SqlComp,
                                           sql_in: SimpleJsonApi::SqlIn,
                                           sql_like: SimpleJsonApi::SqlLike,
                                           pg_ilike: SimpleJsonApi::PgIlike,
                                           pg_jsonb_array: SimpleJsonApi::PgJsonbArray,
                                           pg_jsonb_ilike_array: SimpleJsonApi::PgJsonbIlikeArray,
                                           model_query: SimpleJsonApi::ModelQuery)
    end
  end
end
