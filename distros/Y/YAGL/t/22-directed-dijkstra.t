#!perl

use strict;
use warnings;
use lib 'lib';
use Test::More tests => 1;
use Cwd;
use YAGL;

my $g   = YAGL->new( is_directed => 1 );
my $cwd = getcwd;

# --------------------------------------------------------------------
# Test #1
#
# A test based on a randomly generated CSV that I verified visually
# from the graphviz output.

$g->read_csv("$cwd/t/22-directed-dijkstra-00.csv");

my $start = 'dl3326';
my $end   = 'kd3099';

my @got = $g->dijkstra( $start, $end );

my $expected = [
    {
        'vertex'   => 'dl3326',
        'distance' => 0
    },
    {
        'vertex'   => 'li2941',
        'distance' => 2879
    },
    {
        'distance' => 16329,
        'vertex'   => 'oq1768'
    },
    {
        'vertex'   => 'zy1581',
        'distance' => 80075
    },
    {
        'vertex'   => 'kd3099',
        'distance' => 159493
    }
];

is_deeply( $expected, \@got,
    "Dijkstra's algorithm works as expected - test #1." );
