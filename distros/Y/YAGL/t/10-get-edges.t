#!perl

use strict;
use warnings;
use experimentals;
use lib 'lib';
use Test::More tests => 1;
use Cwd;
use YAGL;

my $g   = YAGL->new;
my $cwd = getcwd;
$g->read_csv("$cwd/t/10-get-edges.csv");

my @expected = (
    [
        'yl4524', 'zw9308',
        {
            'weight' => '84'
        }
    ],
    [
        'kn534', 'zw9308',
        {
            'weight' => '78'
        }
    ],
    [
        'gt7079', 'zw9308',
        {
            'weight' => '96'
        }
    ],
    [
        'abc123', 'xyz789',
        {
            'weight' => '1000000'
        }
    ],
    [
        'I_AM_A_TEST',
        'abc123',
        {
            'weight' => '12345'
        }
    ]
);

my @got = $g->get_edges;

is_deeply( \@got, \@expected,
    qq[Getting the list of edges with ' get_edges ' works as expected] );
