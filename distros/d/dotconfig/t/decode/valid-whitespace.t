use strict;
use warnings;
use t::Runner;
use Test::More;
use JSON();

run 'valid-whitespace-01', JSON::false;
run 'valid-whitespace-02', JSON::false;
run 'valid-whitespace-03', JSON::false;
run 'valid-whitespace-04', "hello";

done_testing;

