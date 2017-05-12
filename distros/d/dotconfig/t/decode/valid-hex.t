use strict;
use warnings;
use t::Runner;
use Test::More;
use JSON();

run 'valid-hex-01', 0xdeadbeef;
run 'valid-hex-02', 0xdeadbeef;

done_testing;

