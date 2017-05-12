#!/usr/bin/env perl

use uni::perl ':dumper';
use lib::abs '../lib';
use Variable::Eject;

my $hash = {
	scalar => 'scalar value',
	array  => [1..3],
	hash   => { my => 'value' },
};
bless $hash, 'obj';
sub obj::param { $_[0]->{$_[1]}; }

eject(
	$hash => $scalar, @array, %hash,
);
eject ( $hash->param => $scalar, @array, %hash );
# Let's look
say $scalar;
say @array;
say keys %hash;

# Let's modify
$scalar .= ' modified';
shift @array;
$hash{another} = 1;

# Look at source
print dumper $hash;
