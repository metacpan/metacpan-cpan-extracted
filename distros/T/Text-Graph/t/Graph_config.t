#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 24;

use Text::Graph;

{
    # test default construction
    my $graph = Text::Graph->new( 'Bar' );
    isa_ok( $graph, 'Text::Graph' );

    is( $graph->get_marker, '*', "Default Bar marker" );
    is( $graph->get_fill,   '*', "Default Bar fill" );
}

{
    # test Line construction
    my $graph = Text::Graph->new( 'Line' );
    isa_ok( $graph, 'Text::Graph' );

    is( $graph->get_marker, '*', "Default Line marker" );
    is( $graph->get_fill,   ' ', "Default Line fill" );
}

{
    # Test complete configuration
    my $graph = Text::Graph->new(
        'Bar',
        marker    => '+',
        fill      => '-',
        log       => 1,
        maxval    => 100,
        minval    => 2,
        maxlen    => 50,
        separator => ' :: ',
        right     => 1,
        showval   => 1
    );

    is( $graph->get_marker, '+', "New marker" );
    is( $graph->get_fill,   '-', "New fill" );

    # test Data Display Options
    ok( $graph->is_log, "is a log graph" );

    # test Data Limit Options
    is( $graph->get_maxlen, 50,  "max length is correct" );
    is( $graph->get_maxval, 100, "max value is correct" );
    is( $graph->get_minval, 2,   "min value is correct" );

    # test Graph Display Options
    is( $graph->get_separator, ' :: ', "Separator is set" );
    ok( $graph->is_right_justified, "right justified" );
    ok( $graph->show_value,         "show values" );
}

{
    # test individual flags
    my $graph = Text::Graph->new( 'Bar', log => 1 );

    # test Data Display Options
    ok( $graph->is_log,              "Display log" );
    ok( !$graph->is_right_justified, "Display labels left justified" );
    ok( !$graph->show_value,         "Don't show values" );
}

{
    my $graph = Text::Graph->new( 'Bar', right => 1 );

    # test Data Display Options
    ok( !$graph->is_log,            "Display linear" );
    ok( $graph->is_right_justified, "Display labels right justified" );
    ok( !$graph->show_value,        "Don't show values" );
}

{
    my $graph = Text::Graph->new( 'Bar', showval => 1 );

    # test Data Display Options
    ok( !$graph->is_log,             "Display linear" );
    ok( !$graph->is_right_justified, "Display labels left justified" );
    ok( $graph->show_value,          "Show values" );
}
