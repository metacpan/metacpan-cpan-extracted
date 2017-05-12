#!/usr/bin/perl

use lib qw(../lib);
use strict;
use Sql::Simple;
use Test;
use Data::Dumper;

$Sql::Simple::RETURNSQL = 1;

BEGIN { plan tests => 3 }

# delete single where
# delete mass where
# delete complex where

my $valid = [
  "DELETE FROM randomtable WHERE\ncolumn1 = ? AND column2 = ? ",
  "DELETE FROM randomtable WHERE\ncolumn1 = ? AND column2 = ? ",
  "DELETE FROM randomtable WHERE\n( columna in (?,?,?,?,?,?,?,?) AND columnb in ( SELECT othertable.o FROM othertable WHERE columno = ?  ) ) OR\n( columnc = ? AND columnd like ?  ) "

];

my $test_list = [
  [ 
    'randomtable', 
    { 
      'column1' => 1, 
      'column2' => 2 
    }, 
    1 
  ],
  [ 
    'randomtable', 
    [ 
      { 'column1' => 1, 'column2' => 2 }, 
      { 'column1' => 3, 'column2' => 4 },
      { 'column1' => 5, 'column2' => 6 },
      { 'column1' => 7, 'column2' => 8 },
    ], 
    1 
  ],
  [
    'randomtable',
    [
      {
	'columna' => [ qw(a b c d 1 2 3 4) ],
	'columnb' => {
	  'table' => 'othertable',
	  'columns' => [ 'o' ],
	  'where' => {
	    'columno' => 'o1'
	  }
	},
      },
      {
	'columnc' => 'c',
	'columnd' => {
	  'op' => 'like',
	  'val' => '%d'
	},
      }
    ],
    1
  ]
];
 
my $test_hash = [
  { 
    'table' => 'randomtable', 
    'where' => { 
      'column1' => 1, 
      'column2' => 2 
    }, 
    'return' => 1 
  },
  { 
    'table' => 'randomtable', 
    'where' => [
      { 'column1' => 1, 'column2' => 2 },
      { 'column1' => 3, 'column2' => 4 },
      { 'column1' => 5, 'column2' => 6 },
    ],
    'return' => 1,
  },
  {
    'table' => 'randomtable',
    'where' => [
      {
	'columna' => [ qw(a b c d 1 2 3 4) ],
	'columnb' => {
	  'table' => 'othertable',
	  'columns' => [ 'o' ],
	  'where' => {
	    'columno' => 'o1'
	  }
	},
      },
      {
	'columnc' => 'c',
	'columnd' => {
	  'op' => 'like',
	  'val' => '%d'
	},
      }
    ],
    'return' => 1
  }
];

foreach my $c ( 0..2 ) {
  if ( Sql::Simple->delete(@{$test_list->[$c]}) eq $valid->[$c] && 
       Sql::Simple->delete(%{$test_hash->[$c]}) eq $valid->[$c] ) {
    ok(1);
  } else {
    my $q1 = Sql::Simple->delete( @{$test_list->[$c]});
    my $q2 = Sql::Simple->delete( %{$test_hash->[$c]});

    if ( $q1 eq $q2 ) {
      print "equals\n";
    } else {
      print "NOT equals\n";
    }

    #print "|" . Sql::Simple->delete( @{$test_list->[$c]}) . "|\n";
    #print "|" . Sql::Simple->delete( %{$test_hash->[$c]}) . "|\n";
    #print $valid->[0] . "\n";
    ok(0);
  }
}
