module Drudgery
  module Loaders
    class SQLite3Loader
      def initialize(db, table)
        @db = db
        @table = table
      end

      def load(records)
        columns = records.first.keys

        @db.transaction do |db|
          records.each do |record|
            db.execute(sql(columns), columns.map { |column| record[column] })
          end
        end
      end

      private
      def sql(columns)
        "INSERT INTO #{@table} (#{columns.map { |column| column }.join(', ')}) VALUES (#{columns.map { |column| '?' }.join(', ')})"
      end
    end
  end
end
