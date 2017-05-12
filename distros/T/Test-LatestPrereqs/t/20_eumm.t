use strict;
use warnings;
use Test::More tests => 2;
use Test::LatestPrereqs;

no warnings 'redefine';

my ($pass, $fail);
*Test::LatestPrereqs::pass = sub (;$) { $pass++ };
*Test::LatestPrereqs::fail = sub (;$) { $fail++ };

all_prereqs_are_latest('t/MakeMaker/Makefile.PL');

ok $pass == 2, "passes two tests as intended";
ok $fail == 1, "fails one test as intended";
