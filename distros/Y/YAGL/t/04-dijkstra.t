#!perl

use strict;
use warnings;
use lib 'lib';
use Test::More tests => 2;
use Cwd;
use YAGL;

my $g   = YAGL->new;
my $cwd = getcwd;

# --------------------------------------------------------------------
# Test #1
#
# A test based on a randomly generated CSV that I verified visually
# from the graphviz output.

$g->read_csv("$cwd/t/04-dijkstra.csv");

my $start = 'da1705';
my $end   = 'gk1114';

my @got = $g->dijkstra( $start, $end );

my $expected = [
    {
        'distance' => 0,
        'vertex'   => 'da1705'
    },
    {
        'distance' => 27,
        'vertex'   => 'je793'
    },
    {
        'vertex'   => 'qe5674',
        'distance' => 80
    },
    {
        'distance' => 166,
        'vertex'   => 'fj5687'
    },
    {
        'distance' => 251,
        'vertex'   => 'ft3255'
    },
    {
        'vertex'   => 'le2845',
        'distance' => 273
    },
    {
        'distance' => 367,
        'vertex'   => 'oh4681'
    },
    {
        'distance' => 412,
        'vertex'   => 'hz6259'
    },
    {
        'vertex'   => 'ey9821',
        'distance' => 469
    },
    {
        'distance' => 553,
        'vertex'   => 'yo6017'
    },
    {
        'vertex'   => 'qx2734',
        'distance' => 577
    },
    {
        'distance' => 605,
        'vertex'   => 'os1043'
    },
    {
        'distance' => 676,
        'vertex'   => 'gk1114'
    }
];

is_deeply( $expected, \@got,
    "Dijkstra's algorithm works as expected - test #1." );

# --------------------------------------------------------------------
# Test #2
#
# Another test based on a randomly generated CSV that I verified
# visually from the graphviz output.

my $h = YAGL->new;

$h->read_csv("$cwd/t/04-dijkstra-01.csv");

my ( $start_01, $end_01 ) = ( 'ur522', 'je6938' );

my @got_01 = $h->dijkstra( $start_01, $end_01 );

my $expected_01 = [
    {
        'vertex'   => 'ur522',
        'distance' => 0
    },
    {
        'vertex'   => 'vd8290',
        'distance' => 3963
    },
    {
        'distance' => 5766,
        'vertex'   => 'st8982'
    },
    {
        'distance' => 12620,
        'vertex'   => 'dt5095'
    },
    {
        'distance' => 21534,
        'vertex'   => 'qt1590'
    },
    {
        'distance' => 26852,
        'vertex'   => 'hc4163'
    },
    {
        'vertex'   => 'pt4689',
        'distance' => 27446
    },
    {
        'vertex'   => 'wd3567',
        'distance' => 35163
    },
    {
        'vertex'   => 'fm3308',
        'distance' => 36673
    },
    {
        'distance' => 40408,
        'vertex'   => 'xg6743'
    },
    {
        'vertex'   => 'je6938',
        'distance' => 47761
    }
];

is_deeply( $expected_01, \@got_01,
    "Dijkstra's algorithm works as expected - test #2." );

__END__

# Local Variables:
# compile-command: "cd .. && perl t/04-dijkstra.t"
# End:
