#! perl

use strict;
use warnings;
use Test::More 0.88 tests => 5;
use Text::Levenshtein qw/ distance fastdistance /;

my $distance;

eval { $distance = distance() };
ok($@ && $@ =~ m!takes 2 or more arguments!,
   "passing no arguments to distance() should croak");

eval { $distance = distance('pink') };
ok($@ && $@ =~ m!takes 2 or more arguments!,
   "passing one argument to distance() should croak");

eval { $distance = fastdistance() };
ok($@ && $@ =~ m!takes 2 or 3 arguments!,
   "passing no arguments to fastdistance() should croak");

eval { $distance = fastdistance('pink') };
ok($@ && $@ =~ m!takes 2 or 3 arguments!,
   "passing one argument to fastdistance() should croak");

eval { $distance = fastdistance('pink', 'blue', 'brown') };
ok($@ && $@ =~ m!takes 2 or 3 arguments!,
   "passing three argument to fastdistance() should croak");

