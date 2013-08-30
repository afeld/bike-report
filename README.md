# NYC CitiBike Availability Data Scraper

Setup:

```bash
bundle
bundle exec ruby scrape.rb
```

The data will then be loaded into a [SQLite3](http://www.sqlite.org/) database, `data.db`.  You can explore it with `sqlite3 data.db`.

To run a particular report:

```bash
bundle exec ruby reports/REPORT_NAME.rb
```

## Resources

* https://github.com/noneck/CitiBike-OpenData-Law/wiki/CitiBike-NYC-Tools-and-Apps
* https://github.com/edgar/citibikenyc
* http://appservices.citibikenyc.com/data2/stations.php
* http://data.citibik.es/
