#!/usr/bin/env perl
use 5.018000;
use strict;
use warnings;
use Text::ANSITable::SQLStyleSheet;
use DBI;
use Test::More tests => 3;

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
        printf('%08x', value)
      )
    ) AS __cell_style
    
  FROM
    data
});

like(
  $t->get_eff_row_style(3, 'fgcolor'),
  qr/^[0-9a-fA-F]{3,6}$/,
  'row style looks like hex number'
);

is(
  hex($t->get_eff_row_style(3, 'fgcolor')) & 0x808080,
  0x808080,
  'row style seems correctly computed'
);

is(
  $t->get_cell(2, 0),
  '00000003',
  'cell_style value works'
);

