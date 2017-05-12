#!/usr/bin/env perl

use uni::perl;
use Test::More tests => 5;
use Test::NoWarnings;
use lib::abs '../lib';
use Variable::Eject;

my $hash = {
	scalar => 'scalar value',
	array  => [1..3],
	hash   => { my => 'value' },
};

eject(
	$hash => $scalar, @array, %hash,
);

is $scalar, 'scalar value', 'scalar ejected';
is_deeply \@array, [1..3], 'array ejected';
is_deeply \%hash, $hash->{hash}, 'hash ejected';

$scalar .= ' modified';
shift @array;
$hash{another} = 1;

is_deeply $hash, {
	scalar => 'scalar value modified',
	array  => [2..3],
	hash   => { my => 'value', another => 1 },
}, 'original modified';
