require 'spec_helper'

module Drudgery
  describe Transformer do
    before do
      @transformer = Transformer.new
    end

    describe '#register' do
      it 'accepts processor as an argument' do
        processor = Proc.new { |data, cache| data }

        @transformer.register(processor)
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

          { :a => data[:a], :cached_a => cache[:a] }
        end

        @transformer.register(processor)
        @transformer.transform({ 'a' => 1 }).must_equal({ :a => 1, :cached_a => 1 })
        @transformer.transform({ 'a' => 2 }).must_equal({ :a => 2, :cached_a => 3 })
        @transformer.transform({ 'a' => 3 }).must_equal({ :a => 3, :cached_a => 6 })
      end

      it 'returns nil if any processor returns nil' do
        processor = Proc.new { |data, cache| nil }

        @transformer.register(processor)
        @transformer.transform({ 'a' => 1 }).must_be_nil
      end
    end
  end
end
