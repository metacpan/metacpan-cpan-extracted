#!perl -T

#  Tests the examples in the documentation.

use strict;
use warnings;

use Test::More;

use Text::Matrix;

plan tests => 12;

#
#  1-6:
#  Synopsis examples, was written to run in a single scope.
#  Ugly heredoc fudging is to make it easier to keep in sync
#  with the actual synopsis code.
#  I should really start using Dist::Zilla and the plugin for this soon.
{
    my ( $output, $expected );

    my $rows    = [ 'Row A', 'Row B', 'Row C', 'Row D' ];
    my $columns = [ 'Column 1', 'Column 2', 'Column 3' ];
    my $data    =
            [
                [ qw/Y Y Y/ ],
                [ qw/Y - Y/ ],
                [ qw/- Y -/ ],
                [ qw/- - -/ ],
            ];

    #  Standard OO form;
    my $matrix = Text::Matrix->new(
        rows    => $rows,
        columns => $columns,
        data    => $data,
        );
    $output = join( '', "Output:\n", $matrix->matrix() );

    ( $expected = <<'    EXPECTED' ) =~ s/^\s+#//gm;
    #Output:
    #      Column 1
    #      | Column 2
    #      | | Column 3
    #      | | |
    #      v v v
    #
    #Row A Y Y Y
    #Row B Y - Y
    #Row C - Y -
    #Row D - - -
    EXPECTED

    #
    #  +1
    is( $output, $expected, '"Standard OO form" synopsis example' );

    #  Anonymous chain form:
    $output = join( '', "Output:\n", Text::Matrix->columns( $columns )->rows( $rows )->
        data( $data )->matrix() );

    #
    #  +2
    is( $output, $expected, '"Anonymous chain form" synopsis example' );

    #  Shorter but equivilent:
    $output = join( '', "Output:\n", Text::Matrix->matrix( $rows, $columns, $data ) );

    #
    #  +3
    is( $output, $expected, '"Shorter but equivilent" synopsis example' );

    #  Paging by column width:
    $rows    = [ map { "Row $_" } ( 'A'..'D' ) ];
    $columns = [ map { "Column $_" } ( 1..20 ) ];
    $data    = [ ( [ ( 'Y' ) x @{$columns} ] ) x @{$rows} ];
    $output = join( '', "Output:\n<", ( '-' x 38 ), ">\n",
        Text::Matrix->max_width( 40 )->matrix( $rows, $columns, $data ) );

    ( $expected = <<'    EXPECTED' ) =~ s/^\s+#//gm;
    #Output:
    #<-------------------------------------->
    #      Column 1
    #      | Column 2
    #      | | Column 3
    #      | | | Column 4
    #      | | | | Column 5
    #      | | | | | Column 6
    #      | | | | | | Column 7
    #      | | | | | | | Column 8
    #      | | | | | | | | Column 9
    #      | | | | | | | | | Column 10
    #      | | | | | | | | | | Column 11
    #      | | | | | | | | | | | Column 12
    #      | | | | | | | | | | | | Column 13
    #      | | | | | | | | | | | | |
    #      v v v v v v v v v v v v v
    #
    #Row A Y Y Y Y Y Y Y Y Y Y Y Y Y
    #Row B Y Y Y Y Y Y Y Y Y Y Y Y Y
    #Row C Y Y Y Y Y Y Y Y Y Y Y Y Y
    #Row D Y Y Y Y Y Y Y Y Y Y Y Y Y
    #
    #      Column 14
    #      | Column 15
    #      | | Column 16
    #      | | | Column 17
    #      | | | | Column 18
    #      | | | | | Column 19
    #      | | | | | | Column 20
    #      | | | | | | |
    #      v v v v v v v
    #
    #Row A Y Y Y Y Y Y Y
    #Row B Y Y Y Y Y Y Y
    #Row C Y Y Y Y Y Y Y
    #Row D Y Y Y Y Y Y Y
    EXPECTED

    #
    #  +4
    is( $output, $expected, '"Paging by column width" synopsis example' );

    #  Just want the body?
    my $sections = Text::Matrix->new(
        rows    => $rows,
        columns => $columns,
        data    => $data,
        )->body();
    $output = join( '', "Output:\n", @{$sections} );

    ( $expected = <<'    EXPECTED' ) =~ s/^\s+#//gm;
    #Output:
    #Row A Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y
    #Row B Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y
    #Row C Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y
    #Row D Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y
    EXPECTED

    #
    #  +5
    is( $output, $expected, '"Just want the body?" synopsis example' );

    #  Multi-character data with a map function.
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
    $output = join( '', "Output:\n", $matrix->matrix() );

    ( $expected = <<'    EXPECTED' ) =~ s/^\s+#//gm;
    #Output:
    #  A
    #  |  B
    #  |  |
    #  v  v
    #
    #1 1A 1B
    #2 2A 2B
    EXPECTED

    #
    #  +6
    is( $output, $expected, '"Multi-character data with a map function" synopsis example' );
}

#
#  7-11: data() examples.
{
    my ( $expected, $output );

  {
    my $matrix = Text::Matrix->new(
        rows    => [ qw/1 2/ ],
        columns => [ qw/A B/ ],
        data    =>
            [
                [ qw/A1 B1/ ],
                [ qw/A2 B2/ ],
            ],
        );
    $output = $matrix->matrix();
  }

    $expected = <<'EXPECTED';
  A
  |  B
  |  |
  v  v

1 A1 B1
2 A2 B2
EXPECTED

    #
    #  +1
    is( $output, $expected, 'First data() example' );

  {
    #  Same as above.
    my $matrix = Text::Matrix->new(
        rows    => [ qw/1 2/ ],
        columns => [ qw/A B/ ],
        data    =>
            {
                1 =>
                    {
                        A => 'A1',
                        B => 'B1',
                    },
                2 =>
                    {
                        A => 'A2',
                        B => 'B2',
                    },
            },
        );
    $output = $matrix->matrix();
  }

    #
    #  +2
    is( $output, $expected, '"Same as above" data() example' );

  {
    #  Still the same as above...
    my $matrix = Text::Matrix->new(
        rows    => [ qw/1 2/ ],
        columns => [ qw/A B/ ],
        data    =>
            [
                {
                    A => 'A1',
                    B => 'B1',
                },
                {
                    A => 'A2',
                    B => 'B2',
                },
            ],
        );
    $output = $matrix->matrix();
  }

    #
    #  +3
    is( $output, $expected, '"Still the same as above..." data() example' );

  {
    #  or...
    my $matrix = Text::Matrix->new(
        rows    => [ qw/1 2/ ],
        columns => [ qw/A B/ ],
        data    =>
            {
                1 => [ qw/A1 B1/ ],
                2 => [ qw/A2 B2/ ],
            },
        );
    $output = $matrix->matrix();
  }

    #
    #  +4
    is( $output, $expected, '"or..." data() example' );

  {
    #  or even this if you're insane...
    my $matrix = Text::Matrix->new(
        rows    => [ qw/1 2/ ],
        columns => [ qw/A B/ ],
        data    =>
            {
                1 => [ qw/A1 B1/ ],
                2 =>
                    {
                        A => 'A2',
                        B => 'B2',
                    },
            },
        );
    $output = $matrix->matrix();
  }

    #
    #  +5
    is( $output, $expected, q{"or even this if you're insane..." data() example} );
}

#
#  12: mapper() example.
{
    my ( $expected, $output );

  {
    my $matrix = Text::Matrix->new(
        rows    => [ qw/1 2/ ],
        columns => [ qw/A B/ ],
        data    =>
            [
                [ qw/A1 B1/ ],
                [ qw/A2 B2/ ],
            ],
        mapper  => sub { reverse( $_ ) },
        );
    $output = $matrix->matrix();
  }

    $expected = <<'EXPECTED';
  A
  |  B
  |  |
  v  v

1 1A 1B
2 2A 2B
EXPECTED

    #
    #  +1
    is( $output, $expected, 'mapper() example' );
}
