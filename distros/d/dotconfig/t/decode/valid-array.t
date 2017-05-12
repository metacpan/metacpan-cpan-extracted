use strict;
use warnings;
use t::Runner;
use Test::More;
use JSON();

run 'valid-array-01', [];
run 'valid-array-02', [ JSON::true ];
run 'valid-array-03', [ JSON::false ];
run 'valid-array-04', [ -100 ];
run 'valid-array-05', [ JSON::true, JSON::false ];
run 'valid-array-06', [ "Hello", [ "World", [ JSON::true ] ] ];
run 'valid-array-07-trailing-comma', [ "Hello", [ "World", [ JSON::true ] ] ];

done_testing;

