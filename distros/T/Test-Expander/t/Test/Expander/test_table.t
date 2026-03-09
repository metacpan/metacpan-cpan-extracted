use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;
use Test::Expander::Constants qw( $MSG_NO_TABLE_HEADER );

plan( 2 );

my ( $expected, $table );

my $data = eval( join( '', <DATA> ) );
print '';
subtest success => sub {
  plan( 4 );

  $expected = {
    "'param2' omitted"             => { expected => 0, param1 => 'abc', param2 => undef },
    'both parameters set to true'  => { expected => 1, param1 => 1,     param2 => 1  },
    'both parameters set to false' => { expected => 0, param1 => 0,     param2 => 0  },
  };
  $table = [
    '+---------------------------------------------------------+',
    '|                              |          | param | param |',
    '|                              | expected |   1   |   2   |',
    '|------------------------------+----------+-------+-------|',
    "| 'param2' omitted             |     0    | 'abc' |       |",
    '| both parameters set to true  |     1    |   1   |   1   |',
    '| both parameters set to false |     0    |   0   |   0   |',
    '+---------------------------------------------------------+',
  ];
  is( { $METHOD_REF->( $table ) }, $expected, 'title is in line' );

  $table = [
    '+------------------------------+',
    '|            | param  | param  |',
    '|  expected  |   1    |   2    |',
    '|------------+--------+--------|',
    "|       'param2' omitted       |",
    "|     0      | 'abc'  |        |",
    '|------------+--------+--------|',
    '| both parameters set to true  |',
    '|     1      |    1   |    1   |',
    '|------------+--------+--------|',
    '| both parameters set to false |',
    '|     0      |    0   |    0   |',
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
    '+---------------------------------------------------------+',
    '|                              |          | param | param |',
    '|                              | expected |   1   |   2   |',
    '|------------------------------+----------+-------+-------|',
    "| 'param2' omitted             |     0    | 'abc' |       |",
    '| both parameters set to true  |     1    |   1   |   1   |',
    '| both parameters set to false |     0    |   0   |   0   |',
    '+---------------------------------------------------------+',
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
