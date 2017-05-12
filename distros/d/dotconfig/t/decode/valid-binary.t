use strict;
use warnings;
use t::Runner;
use Test::More;
use JSON();

run 'valid-binary-01', 0b001001;
run 'valid-binary-02', 0b100100;

done_testing;

