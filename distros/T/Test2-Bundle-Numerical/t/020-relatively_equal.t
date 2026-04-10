use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
my $tol = relative_tolerance(4);
relatively_equal(1.0, 1.0 + $tol, 4, 'relatively_equal accepts close relative values');
relatively_equal(1000.0, 1000.0 + $tol * 1000 * 0.9, 4, 'relatively_equal accepts large magnitude values');
relatively_equal(0.1, 0.1 + $tol * 0.1, 4, 'relatively_equal accepts small magnitude values');
