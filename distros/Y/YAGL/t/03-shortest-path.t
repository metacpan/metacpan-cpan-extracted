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

$g->read_csv("$cwd/t/03-shortest-path.csv");

my $start = 'nt7054';
my $end   = 'cg7395';

my @got      = $g->find_path_between( $start, $end );
my @expected = (
    'nt7054', 'by4783', 'tw1797', 'ee5518', 'pw9636', 'up1194',
    'ow4375', 'mj5047', 'yf3600', 'pt6581', 'cg7395',
);

is_deeply( \@got, \@expected,
qq[Finding the shortest path between two nodes '$start' and '$end' works as expected]
);
