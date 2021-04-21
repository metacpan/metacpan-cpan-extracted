#!perl -w

use strict;
use Test::More;
use Test::Vars;

plan skip_all => "requires 5.26.0" if $] < 5.026;

vars_ok("t/lib/MySub.pm");

ok !exists $INC{"t/lib/MySub.pm"}, 'library is not loaded';

done_testing;
