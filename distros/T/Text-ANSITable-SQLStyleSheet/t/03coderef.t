#!/usr/bin/env perl
use 5.018000;
use strict;
use warnings;
use Text::ANSITable::SQLStyleSheet;
use DBI;
use Test::More tests => 1;

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

my $t = Text::ANSITable::SQLStyleSheet->from_sth($sth, sub {
  
  my ($dbh) = @_;

  $dbh->sqlite_create_function('perl_sprintf', 2, sub {
    my ($format, @args) = @_;
    my $result = sprintf($format, @args);
    return "x" . $result;
  });

  my $sth = $dbh->prepare(q{
    SELECT
      *,
      JSON_OBJECT(
        'fgcolor',
        PRINTF(
          '%02x%02x%02x',
          128 + ABS(RANDOM()) % 128,
          128 + ABS(RANDOM()) % 128,
          128 + ABS(RANDOM()) % 128
        )
      ) AS __row_style
      ,
      JSON_OBJECT(
        'value',
        JSON_OBJECT(
          'value',
          perl_sprintf('%08x', value)
        )
      ) AS __cell_style
      
    FROM
      data
  });

  $sth->execute();

  return $sth;

});

is(
  $t->get_cell(2, 0),
  'x00000003',
  'cell_style value works'
);

