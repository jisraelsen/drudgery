require 'spec_helper'

describe Drudgery::Transformer do
  before(:each) do
    @transformer = Drudgery::Transformer.new
  end

  describe '#initialize' do
    it 'initializes cache hash' do
      @transformer.instance_variable_get('@cache').must_equal({})
    end
  end

  describe '#register' do
    it 'sets processor with provided proc' do
      processor = Proc.new { |data, cache| data }

      @transformer.register(processor)

      # must_equal bug with comparing procs, so use assert_equal instead
      assert_equal @transformer.instance_variable_get('@processor'), processor
    end
  end

  describe '#transform' do
    it 'symbolizes data keys' do
      @transformer.transform({ 'a' => 1 }).must_equal({ :a => 1 })
    end

    it 'processes data with processor' do
      processor = Proc.new { |data, cache| data[:b] = 2; data }

      @transformer.register(processor)
      @transformer.transform({ 'a' => 1 }).must_equal({ :a => 1, :b => 2 })
    end

    it 'allows processor to use cache' do
      processor = Proc.new do |data, cache|
        cache[:a] ||= 0
        cache[:a] += data[:a]
      end

      @transformer.register(processor)
      @transformer.transform({ 'a' => 1 })
      @transformer.transform({ 'a' => 2 })
      @transformer.transform({ 'a' => 3 })
      @transformer.instance_variable_get('@cache').must_equal({ :a => 6 })
    end

    it 'returns nil if any processor returns nil' do
      processor = Proc.new { |data, cache| nil }

      @transformer.register(processor)
      @transformer.transform({ 'a' => 1 }).must_be_nil
    end
  end
end
