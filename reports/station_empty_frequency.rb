require 'rubygems'
require 'bundler'
Bundler.setup(:default)

require 'sqlite3'

db = SQLite3::Database.new('data1.db')

rows = db.execute <<-SQL
  SELECT (SELECT COUNT() FROM available_bikes WHERE count < 3) * 100.0 / (SELECT COUNT() FROM available_bikes);
SQL

puts "stations are near-empty #{rows[0][0].round(1)}% of the time"
