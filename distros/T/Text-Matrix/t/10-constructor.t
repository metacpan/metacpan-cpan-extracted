#!perl -T

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Text::Matrix;

my $rows = [ map { "Row $_" } ( 1..3 ) ];
my $cols = [ map { "Column $_" } ( 1..3 ) ];
my $data = [ [ 1..3 ], [ 4..6 ], [ 7..9 ] ];

my %test_options = (
    rows      => $rows,
    columns   => $cols,
    cols      => $cols,
    data      => $data,
    max_width => 80,
    spacer    => '  ',
    mapper    => sub { $_[ 0 ] + 1 },
    );

my $num_options = scalar( keys( %test_options ) );
my $tests_per_option = 4;

plan tests => 3 + ( $num_options * $tests_per_option );

my ( $matrix );

#
#  1-2:  Basic constructor.
lives_ok { $matrix = Text::Matrix->new(); } 'argless new() error-free';
is( ref( $matrix ), 'Text::Matrix', 'argless new() produced a Text::Matrix' );

foreach my $option ( sort( keys( %test_options ) ) )
{
    #
    #  +2: Constructors with options
    lives_ok { $matrix = Text::Matrix->new(
        $option => $test_options{ $option } ); }
        "new( $option => ... ) error-free";
    is( ref( $matrix ), 'Text::Matrix',
        "new( $option => ... ) produced a Text::Matrix" );

    #
    #  +2: Calling method directly acts as constructor
    lives_ok { $matrix = Text::Matrix->$option( $test_options{ $option } ); }
        "$option( ... ) error-free";
    is( ref( $matrix ), 'Text::Matrix',
        "$option( ... ) produced a Text::Matrix" );
}

#
#  3: unknown constructor option
throws_ok
    {
        $matrix = Text::Matrix->new(
            this_constructor_option_doesnt_exist => 1,
            );
    }
    qr{Unknown option 'this_constructor_option_doesnt_exist' at .*Text.*Matrix\.pm line},
    'error on construct with unknown option';
