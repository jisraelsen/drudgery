require 'spec_helper'

module Drudgery
  module Extractors
    describe CSVExtractor do
      before do
        @file = 'tmp/test.csv'
        File.delete(@file) if File.exists?(@file)

        File.open(@file, 'w') do |f|
          f.puts 'a,b'
          f.puts '1,2'
          f.puts '3,4'
          f.puts '5,6'
        end
      end

      after do
        File.delete(@file) if File.exists?(@file)
      end

      describe '#name' do
        it 'returns csv:<file base name>' do
          extractor = CSVExtractor.new('tmp/people.csv')
          extractor.name.must_equal 'csv:people.csv'
        end
      end

      describe '#col_sep' do
        it 'returns col_sep option' do
          extractor = CSVExtractor.new('tmp/people.csv', :col_sep => '|')
          extractor.col_sep.must_equal '|'
        end
      end

      describe '#col_sep=' do
        it 'sets col_sep to provided character' do
          extractor = CSVExtractor.new('tmp/people.csv')
          extractor.col_sep = '|'
          extractor.col_sep.must_equal '|'
        end
      end

      describe '#extract' do
        it 'yields each record hash and index' do
          extractor = CSVExtractor.new(@file)

          records = []
          indexes = []
          extractor.extract do |record, index|
            records << record
            indexes << index
          end

          records.must_equal([
            { 'a' => '1', 'b' => '2' },
            { 'a' => '3', 'b' => '4' },
            { 'a' => '5', 'b' => '6' }
          ])

          indexes.must_equal [0, 1, 2]
        end
      end

      describe '#record_count' do
        it 'returns count of CSV rows' do
          extractor = CSVExtractor.new(@file)
          extractor.record_count.must_equal 3
        end
      end
    end
  end
end
