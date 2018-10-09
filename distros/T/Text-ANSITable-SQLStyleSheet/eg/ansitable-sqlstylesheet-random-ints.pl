#!/usr/bin/env perl
use 5.018000;
use strict;
use warnings;
use Text::ANSITable::SQLStyleSheet;
use DBI;

my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:');

my $sth = $dbh->prepare(q{
  WITH RECURSIVE
  ints AS (
    SELECT 1 AS value
    UNION ALL
    SELECT value + 1 AS value FROM ints
  )
  SELECT value FROM ints LIMIT 10
});

$sth->execute();

my $t = Text::ANSITable::SQLStyleSheet->from_sth($sth, q{
  SELECT
    *,
    JSON_OBJECT(
      'fgcolor',
      PRINTF(
        '%02x%02x%02x',
        ABS(RANDOM()) % 256,
        ABS(RANDOM()) % 256,
        ABS(RANDOM()) % 256
      )
    ) AS __row_style
  FROM
    data
});

print $t->draw;

