#!perl -T

use strict;
use warnings FATAL => 'all';
use Test::More tests => 4;
use Variable::Lazy::Guts 'lazy';

my $num = 1;
lazy my $foo, \@_, sub { $num++ };
$num++;
is($foo, 2, '$foo is 2') ;
is($num, 3, '$num is 3') ;
is($foo, 2, '$foo is still 2') ;
is($num, 3, '$num is still 3') ;
