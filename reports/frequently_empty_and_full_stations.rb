require 'rubygems'
require 'bundler'
Bundler.setup(:default)

require 'csv'
require 'sqlite3'

@db = SQLite3::Database.new('data.db')

# thanks to https://twitter.com/Bipsterite for the original query
rows = @db.execute <<-SQL
  SELECT
    stations.label,
    stations.latitude,
    stations.longitude,
    (IFNULL(empty_points.count, 0) * 1.0 / total_location.count) AS empty_frequency,
    (IFNULL(full_points.count, 0) * 1.0 / total_location.count) AS full_frequency
  FROM (
    -- total data points
    SELECT
      station_id,
      COUNT(*) AS count
    FROM available_bikes
    GROUP BY station_id
  ) AS total_location
  LEFT OUTER JOIN (
    SELECT station_id, COUNT(*) AS count
    FROM available_bikes
    WHERE count < 2
    GROUP BY station_id
  ) AS empty_points
  ON total_location.station_id = empty_points.station_id
  LEFT OUTER JOIN (
    SELECT station_id, COUNT(*) AS count
    FROM available_bikes
    INNER JOIN stations
    ON available_bikes.station_id = stations.id
    -- open spots
    WHERE (stations.total_docks - available_bikes.count) < 2
    GROUP BY station_id
  ) AS full_points
  ON total_location.station_id = full_points.station_id
  INNER JOIN stations
  ON stations.id = total_location.station_id
  WHERE stations.status = "In Service";
SQL

CSV.open('results.csv', 'wb') do |csv|
  csv << ["Cross streets", "Latitude", "Longitude", "% of time empty", "% of time full"]
  rows.each do |row|
    csv << row
  end
end
