require 'spec_helper'

describe Drudgery::Transformer do
  before(:each) do
    @transformer = Drudgery::Transformer.new
  end

  describe '#initialize' do
    it 'initializes processors array' do
      @transformer.instance_variable_get('@processors').must_equal []
    end

    it 'initializes cache hash' do
      @transformer.instance_variable_get('@cache').must_equal({})
    end
  end

  describe '#register' do
    it 'adds processor to processors array' do
      processor = Proc.new { |data, cache| data }

      @transformer.register(processor)
      @transformer.instance_variable_get('@processors').must_include processor
    end
  end

  describe '#transform' do
    it 'symbolizes data keys' do
      @transformer.transform({ 'a' => 1 }).must_equal({ :a => 1 })
    end

    it 'processes data in each processor' do
      processor = Proc.new { |data, cache| data[:b] = 2; data }

      @transformer.register(processor)
      @transformer.transform({ 'a' => 1 }).must_equal({ :a => 1, :b => 2 })
    end

    it 'allows processors to use cache' do
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

    it 'skips remaining processors and returns nil if any processor returns nil' do
      processor1 = Proc.new { |data, cache| nil }
      processor2 = Proc.new { |data, cache| raise 'should not get here' }

      @transformer.register(processor1)
      @transformer.register(processor2)
      @transformer.transform({ 'a' => 1 }).must_be_nil
    end
  end
end
