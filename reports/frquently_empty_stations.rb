require 'rubygems'
require 'bundler'
Bundler.setup(:default)

require 'sqlite3'

db = SQLite3::Database.new('data.db')

puts "FREQUENTLY EMPTY STATIONS (PERCENT OF RECORDED TIMES)"

# thanks to https://twitter.com/Bipsterite for the query
rows = db.execute <<-SQL
  SELECT stations.label, (under_threshold_location.count * 100.0 / total_location.count) AS frequency
  FROM (
      SELECT station_id, COUNT(*) AS count
      FROM available_bikes
      GROUP BY station_id) AS total_location
    INNER JOIN (
      SELECT station_id, COUNT(*) AS count
      FROM available_bikes
      WHERE count < 3
      GROUP BY station_id) AS under_threshold_location
    ON total_location.station_id = under_threshold_location.station_id
    INNER JOIN stations ON stations.id = under_threshold_location.station_id
  ORDER BY frequency DESC
  LIMIT 10;
SQL

rows.each do |row|
  puts "#{row[0]}: #{row[1].round(1)}%"
end
