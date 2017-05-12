#!/usr/bin/env perl
use lib 'lib';
use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN { use_ok 'Tie::Scalar::Ratio' }

ok tie(my $doubler, 'Tie::Scalar::Ratio', 2, 1), 'creating a doubling scalar';
cmp_ok $doubler, '==', 1,  'value is 1';
cmp_ok $doubler, '==', 2,  'value is 2';
cmp_ok $doubler, '==', 4,  'value is 4';
cmp_ok $doubler, '==', 8,  'value is 8';
cmp_ok $doubler, '==', 16, 'value is 16';
cmp_ok $doubler = 100,'==', 100, 'set value as 100';

ok tie(my $halver, 'Tie::Scalar::Ratio', 0.5), 'creating a halving scalar';
cmp_ok $halver = 80, '==', 80, 'store value as 80';
cmp_ok $halver, '==', 40, 'value is 40';
cmp_ok $halver, '==', 20, 'value is 20';
cmp_ok $halver, '==', 10, 'value is 10';
cmp_ok $halver, '==', 5,  'value is 5';

dies_ok { tie(my $halver, 'Tie::Scalar::Ratio', "a", 80) } 'dies on non-numeric ratio';
dies_ok { tie(my $halver, 'Tie::Scalar::Ratio', undef) } 'dies on undef ratio';
dies_ok { tie(my $halver, 'Tie::Scalar::Ratio') } 'dies on no args';

done_testing;
