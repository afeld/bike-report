require 'rubygems'
require 'bundler'
Bundler.setup(:default)

require 'citibikenyc'
require 'faraday'
require 'sqlite3'


`rm -f data.db`
db = SQLite3::Database.new('data.db')

# http://www.sqlite.org/faq.html#q19
db.default_synchronous = 'OFF'

db.execute_batch <<-SQL
  CREATE TABLE stations (
    id INTEGER PRIMARY KEY,
    status VARCHAR(30),
    latitude FLOAT,
    longitude FLOAT,
    label VARCHAR(30) NOT NULL
  );

  CREATE TABLE available_bikes (
    station_id INTEGER NOT NULL,
    time INTEGER NOT NULL,
    count INTEGER NOT NULL
  );

  CREATE TABLE available_docks (
    station_id INTEGER NOT NULL,
    time INTEGER NOT NULL,
    count INTEGER NOT NULL
  );
SQL

stations = Citibikenyc.stations
stations['results'].each do |station|
  # save the station
  station_row = [
    station['id'],
    station['status'],
    station['latitude'],
    station['longitude'],
    station['label']
  ]
  db.execute("INSERT INTO stations (id, status, latitude, longitude, label) VALUES (?, ?, ?, ?, ?)", station_row)

  # get the metrics for the station
  name = station['label'].gsub(' ', '-')
  response = Faraday.get("http://data.citibik.es/render/") do |req|
    req.params = {
      format: 'json',
      from: '-1weeks',
      target: ["#{name}.available_bikes", "#{name}.available_docks"]
    }
  end

  # each target (metric)
  JSON.parse(response.body).each do |json|
    # sqlite doesnt seem to like adding too many values at once
    json['datapoints'].each_slice(500).each do |datapoints|
      values = datapoints.map { |datapoint|
        value = [
          station['id'],
          datapoint[1],
          datapoint[0]
        ]
        # values are missing for some datapoints
        if value.any?(&:nil?)
          nil
        else
          "(#{value.join(', ')})"
        end
      }.compact

      # check if there's any data to be inserted
      unless values.empty?
        table = json['target'].split('.').last
        statement = "INSERT INTO #{table} (station_id, time, count) VALUES #{values.join(', ')}"
        begin
          db.execute(statement)
        rescue => e
          puts statement
          raise e
        end
      end
    end
  end

  print '.'
end
