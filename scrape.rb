require 'rubygems'
require 'bundler'
Bundler.require(:default)

`rm -f data.db`
db = SQLite3::Database.new('data.db')

db.execute <<-SQL
  create table stations (
    id int,
    status varchar(30),
    latitude float,
    longitude float,
    label varchar(30)
  );
SQL

db.execute <<-SQL
  create table available_bikes (
    station_id int,
    time int,
    count int
  );
SQL

db.execute <<-SQL
  create table available_docks (
    station_id int,
    time int,
    count int
  );
SQL

stations = Citibikenyc.stations
stations['results'].each do |station|
  station_row = [
    station['id'],
    station['status'],
    station['latitude'],
    station['longitude'],
    station['label']
  ]
  db.execute("INSERT INTO stations (id, status, latitude, longitude, label) VALUES (?, ?, ?, ?, ?)", station_row)

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
        if value.any?(&:nil?)
          nil
        else
          "(#{value.join(', ')})"
        end
      }.compact.join(', ')

      table = json['target'].split('.').last
      statement = "INSERT INTO #{table} (station_id, time, count) VALUES #{values}"
      begin
        db.execute(statement)
      rescue => e
        puts statement
        raise e
      end
    end
  end

  print '.'
end
