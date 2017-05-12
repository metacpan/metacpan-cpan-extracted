use strict;
use warnings;
use t::Runner;
use Test::More;
use JSON();

run 'valid-octal-01', 0123;
run 'valid-octal-02', 0456;

done_testing;

