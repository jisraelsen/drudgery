module Drudgery
  module Loaders
    class SQLite3Loader
      attr_reader :name

      def initialize(db, table)
        @db = db
        @db.results_as_hash = true
        @db.type_translation = true

        @table = table

        @name = "sqlite3:#{main_db_name}.#{@table}"
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

      def main_db_name
        main = @db.database_list.detect { |list| list['name'] == 'main' }

        if main['file'].empty?
          'memory'
        else
          File.basename(main['file']).split('.').first
        end
      end
    end
  end
end
