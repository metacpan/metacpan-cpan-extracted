#!/usr/bin/perl

use lib qw(../lib);
use strict;
use Sql::Simple;
use Test;

BEGIN { plan tests => 4 }

$Sql::Simple::RETURNSQL = 1;

my $valid = [
  "UPDATE randomtable SET column1 = ?, column2 = ? WHERE\nclause = ? ",
  "UPDATE randomtable SET column1 = ?, column2 = ? WHERE\nclause = ? ",
  "UPDATE randomtable SET column1 = ?, column2 = ? WHERE\nclause = ? ",
"UPDATE randomtable SET column1 = ?, column2 = ? WHERE
column4 in ( SELECT othertable.value1, othertable.value2 FROM othertable WHERE randomcolumn = ?  ) "
];

my $test_list = [
  [ 'randomtable', { 'column1' => 1, 'column2' => 2 }, { 'clause' => 3 } ],
  [ 
    'randomtable', { 'column1' => 1, 'column2' => 2 }, [
							 { 'clause' => 3 }, 
							 { 'clause' => 4 }, 
							 { 'clause' => 5 }, 
						       ]
  ],
  [
    'randomtable', 
    [
      { 'column1' => 1, 'column2' => 2 }, 
      { 'column1' => 3, 'column2' => 4 }, 
      { 'column1' => 5, 'column2' => 6 }, 
    ],
    [
      { 'clause' => 7 },
      { 'clause' => 8 },
      { 'clause' => 9 },
    ]
  ],
  [
    'randomtable', 
    { 'column1' => 1, 'column2' => 2 },
    { 
      'column4' => {
        'columns' => [ 'value1', 'value2' ],
        'table' => 'othertable',
        'where' => {
	  'randomcolumn' => 3
        }
      }
    }
  ]
];
 
my $test_hash = [
  {
    'table' => 'randomtable',
    'set' => { 'column1' => 1, 'column2' => 2 },
    'where'  => { 'clause' => 3 }
  },
  {
    'table' => 'randomtable',
    'set' => { 'column1' => 1, 'column2' => 2 },
    'where'  => [
      { 'clause' => 3 },
      { 'clause' => 4 },
      { 'clause' => 5 }
    ]
  },
  {
    'table' => 'randomtable',
    'set' => [
      { 'column1' => 1, 'column2' => 2 },
      { 'column1' => 3, 'column2' => 4 },
      { 'column1' => 5, 'column2' => 6 },
    ],
    'where'  => [
      { 'clause' => 7 },
      { 'clause' => 8 },
      { 'clause' => 9 }
    ]
  },
  {
    'table' => 'randomtable',
    'set' => { 'column1' => 1, 'column2' => 2 },
    'where' => {
      'column4' => {
        'columns' => [ 'value1', 'value2' ],
        'table' => 'othertable',
        'where' => {
	  'randomcolumn' => 3
        }
      }
    }
  }
];

foreach my $c ( 0..3 ) {
  if ( Sql::Simple->update(@{$test_list->[$c]}, 1) eq $valid->[$c] && 
       Sql::Simple->update(%{$test_hash->[$c]}, 'return' => 1) eq $valid->[$c] ) {
    ok(1);
  } else {
    #print Sql::Simple->update(@{$test_list->[$c]}, 1);
    #print Sql::Simple->update(%{$test_hash->[$c]}, 'return' => 1);
    ok(0);
  }
}
