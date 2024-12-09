#!perl

use strict;
use warnings;
use lib 'lib';
use Test::More tests => 2;
use Cwd;
use YAGL;

my $cwd = getcwd;

my $g = YAGL->new;
$g->generate_random_vertices( { n => 1024, p => 0.1, max_weight => 100 } );

my @v1 = $g->get_vertices;
my @e1 = $g->get_edges;

my $tmpfile = "$cwd/t/02-serialize-graph-to-csv.csv";
$g->write_csv($tmpfile);

my $h = YAGL->new;
$h->read_csv($tmpfile);

unlink $tmpfile;

my @v2 = $h->get_vertices;
my @e2 = $h->get_edges;

is_deeply( \@v2, \@v1,
    "Graph built from CSV file has same vertices as its parent." );

is_deeply( \@e2, \@e1,
    "Graph built from CSV file has same edges as its parent." );
