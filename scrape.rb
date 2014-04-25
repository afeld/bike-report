require 'rubygems'
require 'bundler'
Bundler.setup(:default)

require 'json'
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
    total_docks INTEGER,
    latitude FLOAT,
    longitude FLOAT,
    label VARCHAR(30) NOT NULL
  );

  CREATE TABLE available_bikes (
    station_id INTEGER NOT NULL,
    time INTEGER NOT NULL,
    count INTEGER NOT NULL
  );
SQL

# http://citibikenyc.com/system-data
response = Faraday.get('http://citibikenyc.com/stations/json')
stations = JSON.parse(response.body)['stationBeanList']

stations.each do |station|
  # save the station
  station_row = [
    station['id'],
    station['statusValue'],
    station['totalDocks'],
    station['latitude'],
    station['longitude'],
    station['stationName']
  ]
  db.execute("INSERT INTO stations (id, status, total_docks, latitude, longitude, label) VALUES (?, ?, ?, ?, ?, ?)", station_row)

  # get the metrics for the station
  name = station['stationName'].gsub(' ', '-')
  # http://graphite.readthedocs.org/en/latest/render_api.html
  response = Faraday.get("http://data.citibik.es/render/") do |req|
    req.params = {
      format: 'json',
      from: '-1weeks',
      target: ["#{name}.available_bikes"]
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
