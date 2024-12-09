#!perl

use strict;
use warnings;
use lib 'lib';
use Test::More tests => 2;
use Cwd;
use YAGL;

my $cwd = getcwd;
my $g   = YAGL->new;

$g->read_csv("$cwd/t/08-is-complete.csv");

# --------------------------------------------------------------------

my $is_complete = $g->is_complete;

is( $is_complete, 1,
    "Checking a connected graph with is_complete() returns true as expected" );

# --------------------------------------------------------------------

$g->remove_vertex('a');
$g->add_vertex('d');

$is_complete = $g->is_complete;

is( $is_complete, undef,
    "Checking an unconnected graph with is_complete() returns false as expected"
);
