#! /bin/sh
dbicdump  -o dump_directory=./lib WebService::ReutersConnect::DB dbi:SQLite:share/concepts.db 
