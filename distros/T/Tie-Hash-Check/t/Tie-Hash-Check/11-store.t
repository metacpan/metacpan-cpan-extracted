# Pragmas.
use strict;
use warnings;

# Modules.
use Tie::Hash::Check;
use Test::More 'tests' => 12;
use Test::NoWarnings;

# Test.
tie my %hash, 'Tie::Hash::Check', {};
is_deeply(
	\%hash,
	{},
	'Blank hash.',
);
my $obj = tied %hash;
isa_ok($obj, 'Tie::Hash::Check');
is_deeply(
	$obj,
	{
		'data' => {},
		'stack' => [],
	},
	'Blank hash object.',
);

# Test.
$hash{'one'} = 1;
is_deeply(
	\%hash,
	{
		'one' => 1,
	},
	'Hash with one element added.',
);
$obj = tied %hash;
isa_ok($obj, 'Tie::Hash::Check');
is_deeply(
	$obj,
	{
		'data' => {
			'one' => 1,
		},
		'stack' => [],
	},
	'Hash object with one element added.',
);

# Test.
$hash{'two'} = {
	'three' => 3,
};
is_deeply(
	\%hash,
	{
		'one' => 1,
		'two' => {
			'three' => 3,
		},
	},
	'Hash after second element added.',
);
$obj = tied %hash;
isa_ok($obj, 'Tie::Hash::Check');
is_deeply(
	$obj,
	{
		'data' => {
			'one' => 1,
			'two' => {
				'three' => 3,
			},
		},
		'stack' => [],
	},
	'Hash object after second element added.',
);
$obj = tied %{$hash{'two'}};
isa_ok($obj, 'Tie::Hash::Check');
is_deeply(
	$obj,
	{
		'data' => {
			'three' => 3,
		},
		'stack' => ['two'],
	},
	'Nested object after second element added.',
);
