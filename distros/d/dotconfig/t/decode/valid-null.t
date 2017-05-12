use strict;
use warnings;
use t::Runner;
use Test::More;
use JSON();

run 'valid-null-01', JSON::null;

done_testing;

