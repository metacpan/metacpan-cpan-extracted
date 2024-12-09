#!perl

use strict;
use warnings;
use experimentals;
use lib 'lib';
use Test::More tests => 3;
use Cwd;
use YAGL;

my $g = YAGL->new;

my @new = (
    [ 'a', 'b', { weight => 1 } ],
    [ 'a', 'c', { weight => 2 } ],
    [ 'a', 'd', { weight => 3 } ],
    [ 'a', 'e', { weight => 3 } ],
);

$g->add_edges(@new);

my $degree = $g->get_degree('a');

is( $degree, 4,
    'Getting the degree of a vertex works, when the degree is greater than 0.'
);

# Vertex with degree 0

$g->add_vertex('f');
my $degree_f = $g->get_degree('f');
is( $degree_f, 0,
"Asking for the degree of a vertex with no neighbors returns 0, as expected."
);

# Undefined vertex

my $degree_foo = $g->get_degree('foo');
is( $degree_foo, undef,
    "Asking for the degree of a nonexistent vertex returns undef, as expected."
);
