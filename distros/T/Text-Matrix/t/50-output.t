#!perl -T

use strict;
use warnings;

use Test::More;

use Text::Matrix;

my $rows = [ map { "Row $_" } ( 1..3 ) ];
my $cols = [ map { "Column $_" } ( 1..3 ) ];
my $data = [ [ 1..3 ], [ 4..6 ], [ 7..9 ] ];

plan tests => 11;

my ( $matrix, $constructor, $expected );

$constructor = sub
    {
        Text::Matrix->new(
            rows    => $rows,
            columns => $cols,
            data    => $data,
            );
    };

#
#  1: Basic output.
$matrix = $constructor->();
$expected = <<'EXPECTED';
      Column 1
      | Column 2
      | | Column 3
      | | |
      v v v

Row 1 1 2 3
Row 2 4 5 6
Row 3 7 8 9
EXPECTED
is( $matrix->matrix(), $expected, 'plain output' );

#
#  2: Mapped output using $_[ 0 ].
$matrix = $constructor->()->mapper( sub { $_[ 0 ] - 1 } );
$expected = <<'EXPECTED';
      Column 1
      | Column 2
      | | Column 3
      | | |
      v v v

Row 1 0 1 2
Row 2 3 4 5
Row 3 6 7 8
EXPECTED
is( $matrix->matrix(), $expected, 'mapped output ($_[ 0 ])' );

#
#  3: Mapped output.
$matrix = $constructor->()->mapper( sub { $_ - 1 } );
$expected = <<'EXPECTED';
      Column 1
      | Column 2
      | | Column 3
      | | |
      v v v

Row 1 0 1 2
Row 2 3 4 5
Row 3 6 7 8
EXPECTED
is( $matrix->matrix(), $expected, 'mapped output ($_)' );

#
#  4: Multi-character data output.
$matrix = $constructor->()->mapper( sub { $_[ 0 ] + 1 } );
$expected = <<'EXPECTED';
      Column 1
      |  Column 2
      |  |  Column 3
      |  |  |
      v  v  v

Row 1 2  3  4 
Row 2 5  6  7 
Row 3 8  9  10
EXPECTED
is( $matrix->matrix(), $expected, 'multi-character data output' );

#
#  5: Wrapped output, unwrapped.
$matrix = $constructor->()->max_width( 20 );
$expected = <<'EXPECTED';
      Column 1
      | Column 2
      | | Column 3
      | | |
      v v v

Row 1 1 2 3
Row 2 4 5 6
Row 3 7 8 9
EXPECTED
is( $matrix->matrix(), $expected, 'unwrapped max-width output' );

#
#  6: Wrapped output, wrapped into 2 sections.
$matrix = $constructor->()->max_width( 16 );
$expected = <<'EXPECTED';
      Column 1
      | Column 2
      | |
      v v

Row 1 1 2
Row 2 4 5
Row 3 7 8

      Column 3
      |
      v

Row 1 3
Row 2 6
Row 3 9
EXPECTED
is( $matrix->matrix(), $expected, 'wrapped max-width output (1)' );

#
#  7: Wrapped output, wrapped into 3 sections.
$matrix = $constructor->()->max_width( 15 );
$expected = <<'EXPECTED';
      Column 1
      |
      v

Row 1 1
Row 2 4
Row 3 7

      Column 2
      |
      v

Row 1 2
Row 2 5
Row 3 8

      Column 3
      |
      v

Row 1 3
Row 2 6
Row 3 9
EXPECTED
is( $matrix->matrix(), $expected, 'wrapped max-width output (2)' );

#
#  8: Wrapped output, unable to meet criteria.
$matrix = $constructor->()->max_width( 13 );
is( $matrix->matrix(), undef, 'undef on too-narrow' );

#
#  9: Mapped output, check scalar-context
$matrix = Text::Matrix->new(
    rows    => [ qw/1 2/ ],
    columns => [ qw/A B/ ],
    data    =>
        [
            [ qw/A1 B1/ ],
            [ qw/A2 B2/ ],
        ],
    mapper  => sub { reverse( $_ ) },
    );
$expected = <<'EXPECTED';
  A
  |  B
  |  |
  v  v

1 1A 1B
2 2A 2B
EXPECTED
is( $matrix->matrix(), $expected, 'mapper runs in scalar context' );

#
#  10: Double-spacer
$matrix = $constructor->()->spacer( '  ' );
$expected = <<'EXPECTED';
      Column 1
      |  Column 2
      |  |  Column 3
      |  |  |
      v  v  v

Row 1 1  2  3
Row 2 4  5  6
Row 3 7  8  9
EXPECTED
is( $matrix->matrix(), $expected, 'double-space spacer' );

#
#  11: Empty-spacer
$matrix = $constructor->()->spacer( '' );
$expected = <<'EXPECTED';
      Column 1
      |Column 2
      ||Column 3
      |||
      vvv

Row 1 123
Row 2 456
Row 3 789
EXPECTED
is( $matrix->matrix(), $expected, 'empty-string spacer' );
