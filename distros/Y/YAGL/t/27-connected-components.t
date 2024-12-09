#!perl

use strict;
use warnings;
use lib 'lib';
use Test::More tests => 1;
use YAGL;
use Cwd;

my $cwd = getcwd;

my $g = YAGL->new;
$g->read_csv("$cwd/t/26-connected-components-00.csv");

my $expected
  = [['b', 'a', 'f', 'e', 'd', 'g', 'c'], ['j', 'k', 'l', 'm']];
my @got = $g->connected_components;

is_deeply(\@got, $expected,
    "Finding connected components of an unconnected graph");

# Local Variables:
# compile-command: "cd .. && perl t/27-connected-components.t"
# End:
