require 'rubygems'
require 'bundler'
Bundler.setup(:default)

require 'csv'
require 'sqlite3'

@db = SQLite3::Database.new('data.db')

def print_rows(name, rows)
  CSV.open("#{name}.csv", 'wb') do |csv|
    rows.each do |row|
      csv << [row[0], row[1].round(1)]
    end
  end
end

# thanks to https://twitter.com/Bipsterite for the original query

def run_query(name, under_threshold_sql)
  rows = @db.execute <<-SQL
    SELECT stations.label, (under_threshold_location.count * 100.0 / total_location.count) AS frequency
    FROM (
      -- total data points
      SELECT station_id, COUNT(*) AS count
      FROM available_bikes
      GROUP BY station_id
    ) AS total_location
    INNER JOIN (#{under_threshold_sql}) AS under_threshold_location
    ON total_location.station_id = under_threshold_location.station_id
    INNER JOIN stations ON stations.id = under_threshold_location.station_id
    WHERE stations.status = "In Service";
  SQL
  print_rows(name, rows)
end

def frequently_empty
  subquery = <<-SQL
    SELECT station_id, COUNT(*) AS count
    FROM available_bikes
    WHERE count < 2
    GROUP BY station_id
  SQL
  run_query('empty_frequency', subquery)
end

def frequently_full
  subquery = <<-SQL
    SELECT station_id, COUNT(*) AS count
    FROM available_bikes
    INNER JOIN stations
    ON available_bikes.station_id = stations.id
    -- open spots
    WHERE (stations.total_docks - available_bikes.count) < 2
    GROUP BY station_id
  SQL
  run_query('full_frequency', subquery)
end

frequently_empty
frequently_full
