use strict;
use warnings;
use t::Runner;
use Test::More;
use JSON();

run 'valid-false-01', JSON::false;

done_testing;

