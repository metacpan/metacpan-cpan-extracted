use strict;
use warnings;
use t::Runner;
use Test::More;
use JSON();

run 'valid-true-01', JSON::true;

done_testing;

