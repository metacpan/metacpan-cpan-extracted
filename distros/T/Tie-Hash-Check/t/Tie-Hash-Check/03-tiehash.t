# Pragmas.
use strict;
use warnings;

# Modules.
use English;
use Error::Pure::Utils qw(clean);
use Tie::Hash::Check;
use Test::More 'tests' => 19;
use Test::NoWarnings;

# Test.
tie my %hash1, 'Tie::Hash::Check', {};
is(ref \%hash1, 'HASH', 'Reference to blank hash.');
is_deeply(
	\%hash1,
	{},
	'Content of blank hash.',
);
my $obj = tied %hash1;
isa_ok($obj, 'Tie::Hash::Check');
is_deeply(
	$obj,
	{
		'data' => {},
		'stack' => [],
	},
	'Content of blank object.',
);

# Test.
tie my %hash2, 'Tie::Hash::Check', {
	'one' => 1,
	'two' => 2,
};
is(ref \%hash2, 'HASH', 'Reference to hash with two keys.');
is_deeply(
	\%hash2,
	{
		'one' => 1,
		'two' => 2,
	},
	'Content of hash with two keys.',
);
$obj = tied %hash2;
isa_ok($obj, 'Tie::Hash::Check');
is_deeply(
	$obj,
	{
		'data' => {
			'one' => 1,
			'two' => 2,
		},
		'stack' => [],
	},
	'Content of object with two hash keys.',
);

# Test.
tie my %hash3, 'Tie::Hash::Check', {
	'one' => {
		'two' => {
			'three' => 3,
		},
	},
};
is(ref \%hash3, 'HASH', 'Reference to hash with nested hash references.');
is_deeply(
	\%hash3,
	{
		'one' => {
			'two' => {
				'three' => 3,
			},
		},
	},
	'Content of hash with nested hash references.',
);
$obj = tied %hash3;
isa_ok($obj, 'Tie::Hash::Check');
is_deeply(
	$obj,
	{
		'data' => {
			'one' => {
				'two' => {
					'three' => 3,
				},
			},
		},
		'stack' => [],
	},
	'Content of object of hash with nested hash references.',
);
$obj = tied %{$hash3{'one'}};
isa_ok($obj, 'Tie::Hash::Check');
is_deeply(
	$obj,
	{
		'data' => {
			'two' => {
				'three' => 3,
			},
		},
		'stack' => ['one'],
	},
	'Content of nested object.',
);
$obj = tied %{$hash3{'one'}{'two'}};
isa_ok($obj, 'Tie::Hash::Check');
is_deeply(
	$obj,
	{
		'data' => {
			'three' => 3,
		},
		'stack' => ['one', 'two'],
	},
	'Content of nested object - second.',
);

# Test.
eval {
	tie my %hash1, 'Tie::Hash::Check', 'foo';
};
is($EVAL_ERROR, "Parameter isn't hash.\n", "Parameter isn't hash.");
clean();

# Test.
eval {
	tie my %hash1, 'Tie::Hash::Check', {}, 'foo';
};
is($EVAL_ERROR, "Stack isn't array.\n", "Stack isn't array.");
clean();
