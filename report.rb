require 'rubygems'
require 'bundler'
Bundler.setup(:default)

require 'sqlite3'

db = SQLite3::Database.new('data1.db')
puts "POINTS PER STATION"
rows = db.execute <<-SQL
  SELECT s.label, COUNT(*) FROM stations s LEFT JOIN available_bikes ab ON s.id = ab.station_id GROUP BY s.id;
SQL

rows.each do |row|
  puts "#{row[0]}: #{row[1]}"
end
