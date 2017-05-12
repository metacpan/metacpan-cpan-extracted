#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 11;

use Text::Graph;

can_ok(
    'Text::Graph', qw(new get_marker get_fill is_log
        get_maxlen get_maxval get_minval
        get_separator is_right_justified show_value
        make_lines to_string)
);

# test default construction
my $graph = Text::Graph->new();
isa_ok( $graph, 'Text::Graph' );

is( $graph->get_marker, '*', "Default marker" );
is( $graph->get_fill,   '*', "Default fill" );

# test Data Display Options
ok( !$graph->is_log, "Default is linear" );

# test Data Limit Options
ok( !defined $graph->get_maxlen, "No max length" );
ok( !defined $graph->get_maxval, "No max value" );
ok( !defined $graph->get_minval, "No min value" );

# test Graph Display Options
is( $graph->get_separator, ' :', "Default separator" );
ok( !$graph->is_right_justified, "Default labels left justified" );
ok( !$graph->show_value,         "Default don't show values" );

