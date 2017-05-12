@echo off

    echo Starting the Pipe Server...
    start "Pipe Server" perl -Mblib server.pl


    echo Starting the Pipe Client...
    start "Pipe Client" perl -Mblib client.pl
