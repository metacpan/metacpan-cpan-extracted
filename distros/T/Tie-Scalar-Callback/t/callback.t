#!/usr/bin/env perl
use v5.10;
use lib 'lib';
use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN { use_ok 'Tie::Scalar::Callback' }

my $coderef = sub {
	state $value  = 0.5;
	state $factor = 2;
	$value *= $factor;
	};

ok tie(my $doubler, 'Tie::Scalar::Callback', $coderef), 'creating a scalar with callback';
cmp_ok $doubler, '==', 1, 'scalar value is 1';
cmp_ok $doubler, '==', 2, 'scalar value is 2';
cmp_ok $doubler, '==', 4, 'scalar value is 4';
cmp_ok $doubler, '==', 8, 'scalar value is 8';

dies_ok { tie(my $halver, 'Tie::Scalar::Callback', "a") } 'dies on non-coderef arg';
dies_ok { tie(my $halver, 'Tie::Scalar::Callback', undef) } 'dies on undef';
dies_ok { tie(my $halver, 'Tie::Scalar::Callback') } 'dies on no args';

done_testing;
