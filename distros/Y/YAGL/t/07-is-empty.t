#!perl

use strict;
use warnings;
use lib 'lib';
use Test::More tests => 2;
use Cwd;
use YAGL;

my $cwd = getcwd;
my $g   = YAGL->new;

my $removed = 'sk132';

$g->read_csv("$cwd/t/07-is-empty.csv");

my $is_empty = $g->is_empty;

is( $is_empty, undef,
    "Checking a full graph with is_empty() returns false as expected" );

for my $vertex ( $g->get_vertices ) {
    $g->remove_vertex($vertex);
}

$is_empty = $g->is_empty;

is( $is_empty, 1,
    "Checking an empty graph with is_empty() returns true as expected" );
