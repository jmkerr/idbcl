# idbcl [![Build Status](https://travis-ci.org/jmkerr/idbcl.svg?branch=master)](https://travis-ci.org/jmkerr/idbcl)
Tracks iTunes/macOS Music song play count and ratings.
* Reads song data from the iTunesLibrary Framework (macOS 10.14+).
* Stores song data in a SQLite3 database (`~/Library/Application Support/idbcl/records.sqlite3`):
  * Table: `Meta`, Columns: `PersistentID, AlbumTitle, Artist, BitRate, FileSize, Genre, Kind, SampleRate, Title, TotalTime, Year`
  * Table: `PlayCounts`, Columns: `PersistentID, Date, PlayCount`
  * Table: `Ratings`, Columns: `PersistentID, Date, Rating`
#### Usage:
* Build instructions in `.travis.yml`
