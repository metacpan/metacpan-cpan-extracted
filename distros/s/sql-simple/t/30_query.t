#!/usr/bin/perl

use lib qw(../lib);
use strict;
use Sql::Simple;
use Data::Dumper;
use Test;

$Sql::Simple::RETURNSQL = 1;

  # 1. scalar column list (no where clause)
  # 2. array ref column list (no where clause)
  # 3. hash alias column list (no where clause)
  # 4. where clause (is null)
  # 5. where clause (like)
  # 6. where clause (simple)
  # 7. where clause (or clause)
  # 8. where clause (sub query)
  # 9. where clause ('in' statement)
  # 10. table join
  # 11. super complex (all above + order)
  # 12. forced table prefix column list
  # 13. join on same table

BEGIN { plan tests => 12 }

my $valid = [
  'SELECT randomtable.column1, randomtable.column2 FROM randomtable ',
  'SELECT randomtable.column1, randomtable.column2 FROM randomtable ',
  'SELECT randomtable.COLUMN1 as column1, randomtable.COLUMN2 as column2 FROM randomtable ',
  'SELECT randomtable.column1, randomtable.column2 FROM randomtable WHERE column1 IS NULL ',
  'SELECT randomtable.column1, randomtable.column2 FROM randomtable WHERE column1 LIKE ?  ',
  'SELECT randomtable.column1, randomtable.column2 FROM randomtable WHERE column1 = ? ',
  "SELECT randomtable.column1, randomtable.column2 FROM randomtable WHERE ( column1 = ? ) OR\n( column2 = ? ) ",
  "SELECT randomtable.column1, randomtable.column2 FROM randomtable WHERE column1 in ( SELECT column3 FROM othertable WHERE column4 = ?  ) ",
  'SELECT randomtable.column1, randomtable.column2 FROM randomtable WHERE column1 in (?,?) ',
  "SELECT column1, column2 FROM randomtable\nINNER JOIN othertable ON randomtable.column1 = othertable.column3 AND randomtable.column2 = othertable.column4 ",

  'SELECT 5 + 5 as column2, column1 FROM randomtable
INNER JOIN othertable ON randomtable.column1 = othertable.column3 
INNER JOIN othertable ON randomtable.column2 = othertable.column4 WHERE ( column10 LIKE ?  AND column11 = ? AND column9 IS NULL ) OR
( column12 in ( SELECT columna FROM anothertable WHERE columnb = ?  ) ) OR
( column13 in (?,?) ) ',

  'SELECT mytable.one, mytable.two, mytable.three, othertable.one, othertable.two, othertable.three FROM mytable,othertable WHERE mytable.pk = othertable.sk ',
];

my $test_list = [
  [ "column1, column2", 'randomtable', undef, undef, 1 ], 
  [ [ qw(column1 column2) ], 'randomtable', undef, undef, 1 ],
  [ { 'COLUMN1' => 'column1', 'COLUMN2' => 'column2' }, 'randomtable', undef, undef, 1 ],
  [ [ qw(column1 column2) ], 'randomtable', { 'column1' => \'IS NULL' }, undef, 1 ],
  [ [ qw(column1 column2) ], 'randomtable', { 'column1' => { 'op' => 'LIKE', 'val' => '%value%' } }, undef, 1 ],
  [ [ qw(column1 column2) ], 'randomtable', { 'column1' => 'value' }, undef, 1 ],
  [ [ qw(column1 column2) ], 'randomtable', [ { 'column1' => 'value' }, { 'column2' => 'value' } ], undef, 1 ],
  [ [ qw(column1 column2) ], 'randomtable', { 'column1' => { 'table' => 'othertable', 'columns' => 'column3', 'where' => { 'column4' => 'value' } } }, undef, 1 ],
  [ [ qw(column1 column2) ], 'randomtable', { 'column1' => [ qw(value1 value2) ] }, undef, 1 ],
  # 9
  [ 
    [ qw(column1 column2) ], 
    [
      'randomtable', { 'table' => 'othertable', 'on' => { 'randomtable.column1' => 'othertable.column3', 'randomtable.column2' => 'othertable.column4' } }
    ],
  ],
  # 10
  [ 
    { 'column1' => undef, '5 + 5' => 'column2' }, 
    [ 'randomtable', 
      { 'table' => 'othertable', 'on' => { 'randomtable.column1' => 'othertable.column3' } }, 
      { 'table' => 'othertable', 'on' => { 'randomtable.column2' => 'othertable.column4' } } 
    ],
    [
      { 
        'column9' => \'IS NULL',
        'column10' => { 'op' => 'LIKE', 'val' => '%value%' },
        'column11' => 'value',
      },
      {
        'column12' => { 'table' => 'anothertable', 'columns' => 'columna', 'where' => { 'columnb' => 'value' } }
      },
      {
	'column13' => [ qw(value3 value4) ],
      }
    ],
  ],
  [
    { 'mytable' => [qw(one two three)], 'othertable' => [qw(one two three)] },
    [ 'mytable', 'othertable' ],
    { 'mytable.pk' => \'othertable.sk' }
  ]
];
 
my $test_hash = [
  { 'columns' => 'column1, column2', 'table' => 'randomtable' },
  { 'columns' => [ qw(column1 column2) ], 'table' => 'randomtable' },
  { 'columns' => { 'COLUMN1' => 'column1', 'COLUMN2' => 'column2' }, 'table' => 'randomtable' },
  { 'columns' => [ qw(column1 column2) ], 'table' => 'randomtable', 'where' => { 'column1' => \'IS NULL' } },
  { 'columns' => [ qw(column1 column2) ], 'table' => 'randomtable', 'where' => { 'column1' => { 'op' => 'LIKE', 'val' => '%value%' } } },
  { 'columns' => [ qw(column1 column2) ], 'table' => 'randomtable', 'where' => { 'column1' => 'value' } },
  { 'columns' => [ qw(column1 column2) ], 'table' => 'randomtable', 'where' => [ { 'column1' => 'value' }, { 'column2' => 'value' } ] },
  { 'columns' => [ qw(column1 column2) ], 'table' => 'randomtable', 'where' => { 'column1' => { 'table' => 'othertable', 'columns' => 'column3', 'where' => { 'column4' => 'value' } } } },
  { 'columns' => [ qw(column1 column2) ], 'table' => 'randomtable', 'where' => { 'column1' => [ qw(value1 value2) ] } },
  # 9
  { 
    'columns' => [ qw(column1 column2) ], 
    #'table' => { 'randomtable.column1' => 'othertable.column3', 'randomtable.column2' => 'othertable.column4' }, 
    'table' => [ 'randomtable', { 'table' => 'othertable', 'on' => { 'randomtable.column1' => 'othertable.column3', 'randomtable.column2' => 'othertable.column4' } } ],
  },
  # 10
  { 
    'columns' => { 'column1' => undef, '5 + 5' => 'column2' }, 
    'table' => [ 'randomtable', 
      { 'table' => 'othertable', 'on' => { 'randomtable.column1' => 'othertable.column3' } }, 
      { 'table' => 'othertable', 'on' => { 'randomtable.column2' => 'othertable.column4' } } 
    ],
    'where' => [
      { 
        'column9' => \'IS NULL',
        'column10' => { 'op' => 'LIKE', 'val' => '%value%' },
        'column11' => 'value',
      },
      {
        'column12' => { 'table' => 'anothertable', 'columns' => 'columna', 'where' => { 'columnb' => 'value' } }
      },
      {
	'column13' => [ qw(value3 value4) ],
      }
    ],
  },
  {
    'columns' => { 'mytable' => [qw(one two three)], 'othertable' => [qw(one two three)] },
    'table' => [ qw(mytable othertable) ],
    'where' => {
      'mytable.pk' => \'othertable.sk'
    },
  }
];

foreach my $c ( 0..$#{$valid} ) {

  if ( Sql::Simple->query(@{$test_list->[$c]}) eq $valid->[$c] ) {
    if ( Sql::Simple->query(%{$test_hash->[$c]}) eq $valid->[$c] ) {
      ok(1);
    } else {
      warn "list is ok, hash is broke";
      print Dumper(Sql::Simple->query(undef, @{$test_list->[$c]})) . "\n";
      print Dumper(Sql::Simple->query(undef, %{$test_hash->[$c]})) . "\n";
      print Dumper($valid->[$c]) . "\n";
      die();
      ok(0);
    }
  } else {
    #open(FILE, ">FOO");
    #print "\n";
    #print Dumper(Sql::Simple->query(undef, @{$test_list->[$c]})) . "\n";
    #print Dumper(Sql::Simple->query(undef, %{$test_hash->[$c]})) . "\n";
    #print Dumper($valid->[$c]) . "\n";
    #die();
    #close FILE;
    #die();
    #print Dumper(Sql::Simple->query(undef, %{$test_hash->[$c]}));
    #print "\n\nmatch!\n" if ( Sql::Simple->query(@{$test_list->[$c]}) eq Sql::Simple->query(%{$test_hash->[$c]}) );
    ok(0);
  }
}
