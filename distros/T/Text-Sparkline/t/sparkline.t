#!/usr/bin/perl

use warnings;
use strict;
use 5.010;

use Test::More tests => 11;

use Text::Sparkline;

BASICS: {
    my @values = ( 0 .. 8 );
    my $spark = Text::Sparkline::sparkline( \@values );
    is( $spark, '▁▂▃▄▅▆▇██' );
}

BASICS: {
    my @values = ( 0 .. 7, 8.1 );
    my $spark = Text::Sparkline::sparkline( \@values );
    is( $spark, '▁▁▂▃▄▅▆▇█' );
}

BASICS: {
    my @values = ( 0, 10, 12.5, 20, 87.5, 90, 100 );
    my $spark = Text::Sparkline::sparkline( \@values );
    is( $spark, '▁▁▂▂███' );
}

BASICS: {
    my @values = ( 0, 1, 0, 1 );
    my $spark = Text::Sparkline::sparkline( \@values );
    is( $spark, '▁█▁█' );
}

UNTRUNCATED_BLOCK: {
    my @values = 10000 .. 10008;
    my $spark = Text::Sparkline::sparkline( \@values );
    is( $spark, '█████████' );
}

TRUNCATED_BLOCK: {
    my @values = 10000 .. 10008;
    my $spark = Text::Sparkline::sparkline_truncated( \@values );
    is( $spark, '▁▂▃▄▅▆▇██' );
}

TRUNCATED_ALL_SAME_VALUE: {
    my @values = (100) x 10;
    my $spark = Text::Sparkline::sparkline_truncated( \@values );
    is( $spark, '██████████' );
}

INVALID_VALUES: {
    my @values = ( 14, undef, 27, -4, 8, 'q', 20 );
    my $spark = Text::Sparkline::sparkline( \@values );
    is( $spark, '▅ █ ▃ ▆', 'Spaces where invalid numbers are' );
}

ALL_INVALID_VALUES: {
    my @values = ( undef, -4, 'q', [ 'array ref' ], { hash => 'ref' } );
    my $spark = Text::Sparkline::sparkline( \@values );
    is( $spark, '     ', 'Five spaces for five invalid values' );
}

NO_VALUES: {
    my $spark = Text::Sparkline::sparkline( [] );
    is( $spark, '', 'We have an empty string' );
}

HEAVILY_WEIGHTED: {
    my @values = ( 0 .. 10, 100_000 );
    my $spark = Text::Sparkline::sparkline( \@values );
    is( $spark, '▁▁▁▁▁▁▁▁▁▁▁█', 'Big spike at the end' );
}


exit 0;
