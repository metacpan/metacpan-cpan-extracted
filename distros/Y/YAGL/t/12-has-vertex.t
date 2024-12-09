#!perl

use strict;
use warnings;
use experimentals;
use lib 'lib';
use Test::More tests => 2;
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

my $has_a = $g->has_vertex('a');

isnt( $has_a, undef,
    'Checking whether an actually existing vertex exists works.' );

my $has_foo = $g->has_vertex('foo');

is( $has_foo, undef, 'Checking whether a nonexistent vertex exists works.' );
