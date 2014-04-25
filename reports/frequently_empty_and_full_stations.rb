require 'rubygems'
require 'bundler'
Bundler.setup(:default)

require 'sqlite3'

@db = SQLite3::Database.new('data.db')

def print_rows(rows)
  rows.each do |row|
    puts "#{row[0].ljust(30)}#{row[1].round(1)}%"
  end
end

# thanks to https://twitter.com/Bipsterite for the original query

# TODO limit to in-service stations

puts "FREQUENTLY EMPTY STATIONS (PERCENT OF RECORDED TIMES)"
rows = @db.execute <<-SQL
  SELECT stations.label, (under_threshold_location.count * 100.0 / total_location.count) AS frequency
  FROM (
    -- total data points
    SELECT station_id, COUNT(*) AS count
    FROM available_bikes
    GROUP BY station_id
  ) AS total_location
  INNER JOIN (
    -- number below threshold
    SELECT station_id, COUNT(*) AS count
    FROM available_bikes
    WHERE count < 2
    GROUP BY station_id
  ) AS under_threshold_location
  ON total_location.station_id = under_threshold_location.station_id
  INNER JOIN stations ON stations.id = under_threshold_location.station_id
  ORDER BY frequency DESC
  LIMIT 10;
SQL
print_rows(rows)

puts "\nFREQUENTLY FULL STATIONS (PERCENT OF RECORDED TIMES)"
rows = @db.execute <<-SQL
  SELECT stations.label, (under_threshold_location.count * 100.0 / total_location.count) AS frequency
  FROM (
    -- total data points
    SELECT station_id, COUNT(*) AS count
    FROM available_bikes
    GROUP BY station_id
  ) AS total_location
  INNER JOIN (
    -- number below threshold
    SELECT station_id, COUNT(*) AS count
    FROM available_bikes
    INNER JOIN stations
    ON available_bikes.station_id = stations.id
    -- open spots
    WHERE (stations.total_docks - available_bikes.count) < 2
    GROUP BY station_id
  ) AS under_threshold_location
  ON total_location.station_id = under_threshold_location.station_id
  INNER JOIN stations ON stations.id = under_threshold_location.station_id
  ORDER BY frequency DESC
  LIMIT 10;
SQL
print_rows(rows)
