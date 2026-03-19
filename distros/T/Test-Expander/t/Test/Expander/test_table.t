use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;
use Test::Expander::Constants qw( $FALSE $MSG_NO_TABLE_HEADER $TRUE );

plan( 2 );

my ( $expected, $table );

my $data = eval( join( '', <DATA> ) );
print '';
subtest success => sub {
  plan( 4 );

  $expected = {
    "'param2' omitted"             => { expected => $FALSE, param1 => 'abc',  param2 => undef },
    'both parameters set to true'  => { expected => $TRUE,  param1 => $TRUE,  param2 => $TRUE },
    'both parameters set to false' => { expected => $FALSE, param1 => $FALSE, param2 => $FALSE },
  };
  $table = [
    '+-----------------------------------------------------------+',
    '|                              |          | param  | param  |',
    '|                              | expected |   1    |   2    |',
    '|------------------------------+----------+--------+--------|',
   q(| 'param2' omitted             |  $FALSE  | 'abc'  |        |),
    '| both parameters set to true  |  $TRUE   | $TRUE  | $TRUE  |',
    '| both parameters set to false |  $FALSE  | $FALSE | $FALSE |',
    '+-----------------------------------------------------------+',
  ];
  is( { $METHOD_REF->( $table ) }, $expected, 'title is in line' );

  $table = [
    '+------------------------------+',
    '|            | param  | param  |',
    '|  expected  |   1    |   2    |',
    '|------------+--------+--------|',
    "|       'param2' omitted       |",
   q(|   $FALSE   | 'abc'  |        |),
    '|------------+--------+--------|',
    '| both parameters set to true  |',
    '|   $TRUE    | $TRUE  | $TRUE  |',
    '|------------+--------+--------|',
    '| both parameters set to false |',
    '|   $FALSE   | $FALSE | $FALSE |',
    '+------------------------------+',
  ];
  is( { $METHOD_REF->( $table ) }, $expected, 'title is out of line' );

  $expected = {};
  $table = [
    '+---------------------------------------------------------+',
    '|                              |          | param | param |',
    '|                              | expected |   1   |   2   |',
    '+---------------------------------------------------------+',
  ];
  is( { $METHOD_REF->( $table ) }, $expected, 'empty table' );

  my $mockThis = mock $CLASS => ( override => [ _load_tdt => sub { $table } ] );
  is( { $METHOD_REF->() }, $expected, 'table in a separate file' );
};

$expected = $MSG_NO_TABLE_HEADER =~ s/\n//r;
$table = [
  '+---------------------------------------------------------+',
  '+------------------------------+----------+-------+-------+',
];
throws_ok { $METHOD_REF->( $table ) } qr/$expected/, 'failure';

__DATA__
{
  'case 1' => [
    '+-----------------------------------------------------------+',
    '|                              |          | param  | param  |',
    '|                              | expected |   1    |   2    |',
    '|------------------------------+----------+--------+--------|',
    "| 'param2' omitted             |  $FALSE  | 'abc'  |        |",
    '| both parameters set to true  |  $TRUE   | $TRUE  | $TRUE  |',
    '| both parameters set to false |  $FALSE  | $FALSE | $FALSE |',
    '+-----------------------------------------------------------+',
  ],
  'case 2' => [
    '+------------------------------+',
    '|          |           | param |',
    '|          | expected  |   1   |',
    '|----------+-----------+-------|',
    "| error 1  | 'ERROR 1' |   2   |",
    "| error 2  | 'ERROR 2' |   3   |",
    '+------------------------------+',
  ],
}
