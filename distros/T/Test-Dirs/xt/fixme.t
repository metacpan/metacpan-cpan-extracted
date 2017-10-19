use strict;
use warnings;
use Test::More;

eval "use Test::Fixme";
plan skip_all => "requires Test::Fixme to run"
    if $@;

run_tests();
