#!perl
#
# 01-original.t - this is the original testsuite that was included
#

use 5.006;
use strict;
use warnings;

use Test::More 0.88 tests => 9;

use Text::Levenshtein qw(distance fastdistance);

is_deeply(distance("foo","four"),2,"Correct distance foo four");
is_deeply(distance("foo","foo"),0,"Correct distance foo foo");
is_deeply(distance("cow","cat"),2,"Correct distance cow cat");
is_deeply(distance("cat","moocow"),5,"Correct distance cat moocow");
is_deeply(distance("cat","cowmoo"),5,"Correct distance cat cowmoo");
is_deeply(distance("sebastian","sebastien"),1,"Correct distance sebastian sebastien");
is_deeply(distance("more","cowbell"),5,"Correct distance more cowbell");
my @foo = distance("foo","four","foo","bar");
my @bar = (2,0,3);
is_deeply(\@foo,\@bar,"Array test: Correct distances foo four foo bar");
is_deeply(fastdistance("foo","boo"),1,"Fast test: Correct distance foo boo");
