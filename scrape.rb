require 'citibikenyc'
require 'faraday'
require 'sqlite3'

db = SQLite3::Database.new('data.db')

db.execute <<-SQL
  create table IF NOT EXISTS stations (
    citibike_id int,
    status varchar(30),
    latitude float,
    longitude float,
    label varchar(30)
  );

  create table IF NOT EXISTS available_bikes (
    station_id int,
    time int,
    count int
  );

  create table IF NOT EXISTS available_docks (
    station_id int,
    time int,
    count int
  );
SQL

stations = Citibikenyc.stations
stations['results'].each do |station|
  data = [
    station['id'],
    station['status'],
    station['latitude'],
    station['longitude'],
    station['label']
  ]
  db.execute("INSERT INTO stations (citibike_id, status, latitude, longitude, label) VALUES (?, ?, ?, ?, ?)", data)
end

# name = station['label'].gsub(' ', '-')
# data = Faraday.get("http://data.citibik.es/render/?target=#{name}.available_bikes&format=json&from=-2weeks")
# json = JSON.parse(data)
# json['datapoints'].each do |datapoint|
#   db.execute("INSERT INTO stations (citibike_id, status, latitude, longitude, label, address) VALUES (?, ?, ?, ?, ?, ?)", [data])
# end