use strict;
use warnings;
use Test::More;
use Test::LatestPrereqs;

BEGIN {
  eval "require inc::Module::Install";
  plan skip_all => "this test requires Module::Install" if $@;
}

plan tests => 2;

no warnings 'redefine';

my ($pass, $fail);
*Test::LatestPrereqs::pass = sub (;$) { $pass++ };
*Test::LatestPrereqs::fail = sub (;$) { $fail++ };

all_prereqs_are_latest('t/ModuleInstall/Makefile.PL');

ok $pass == 2, "passes two tests as intended";
ok $fail == 1, "fails one test as intended";
