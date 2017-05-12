use strict;
use warnings;
use t::Runner;
use Test::More;
use JSON();
use Math::BigInt;
use Math::BigFloat;

run 'valid-number-01', 100;
run 'valid-number-02', -100;
run 'valid-number-03', 3.14;
run 'valid-number-04', -10.34;
run 'valid-number-05', Math::BigInt->new('123456789012345678901234567890');
run 'valid-number-06', Math::BigInt->new('2.99792458e8');
run 'valid-number-07', Math::BigFloat->new('6.62606957e-34');
run 'valid-number-08', Math::BigFloat->new('-9.28476362e-24');

done_testing;

