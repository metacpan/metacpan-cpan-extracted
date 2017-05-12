#!perl -w
use strict;
use Test::More;

plan( skip_all => "I don't have windows perl so skip and patch welcome" ) if $^O eq 'MSWin32';

use Time::List;

# test Time::List here
pass;

done_testing;
