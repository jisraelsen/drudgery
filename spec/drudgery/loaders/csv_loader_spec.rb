require 'spec_helper'

module Drudgery
  module Loaders
    describe CSVLoader do
      describe '#name' do
        it 'returns csv:<file base name>' do
          loader = CSVLoader.new('tmp/people.csv')
          loader.name.must_equal 'csv:people.csv'
        end
      end

      describe '#col_sep' do
        it 'returns col_sep option' do
          loader = CSVLoader.new('tmp/people.csv', :col_sep => '|')
          loader.col_sep.must_equal '|'
        end
      end

      describe '#col_sep=' do
        it 'sets col_sep to provided character' do
          loader = CSVLoader.new('tmp/people.csv')
          loader.col_sep = '|'
          loader.col_sep.must_equal '|'
        end
      end

      describe '#load' do
        before do
          @file = 'tmp/test.csv'
          File.delete(@file) if File.exists?(@file)
        end

        after do
          File.delete(@file) if File.exists?(@file)
        end

        describe 'when columns separated by |' do
          it 'writes hash keys as header and records as rows' do
            record1 = { :a => 1, :b => 2 }
            record2 = { :a => 3, :b => 4 }
            record3 = { :a => 5, :b => 6 }

            loader = CSVLoader.new(@file, :col_sep => '|')
            loader.load([record1, record2])
            loader.load([record3])

            records = File.readlines(@file).map { |line| line.strip.split('|') }
            records.must_equal [%w[a b], %w[1 2], %w[3 4], %w[5 6]]
          end
        end

        it 'writes hash keys as header and records as rows' do
          record1 = { :a => 1, :b => 2 }
          record2 = { :a => 3, :b => 4 }
          record3 = { :a => 5, :b => 6 }

          loader = CSVLoader.new(@file)
          loader.load([record1, record2])
          loader.load([record3])

          records = File.readlines(@file).map { |line| line.strip.split(',') }
          records.must_equal [%w[a b], %w[1 2], %w[3 4], %w[5 6]]
        end
      end
    end
  end
end
