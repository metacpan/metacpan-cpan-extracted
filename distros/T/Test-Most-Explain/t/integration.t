use strict;
use warnings;
use Test::Most;
use Test::Warnings;

use lib 'lib';
use Test::Most::Explain qw(explain);

#------------------------------------------------------------
# Integration: scalar → array → hash → blessed → nested
# Ensures explain() behaves consistently across calls
#------------------------------------------------------------
subtest 'scalar → array → hash → blessed → nested (end‑to‑end)' => sub {

	# Scalar mismatch
	my $s = explain(1, 2);
	like($s, qr/Scalar/i, 'scalar diff labelled');
	like($s, qr/Got.*1/s, 'scalar got');
	like($s, qr/Expected.*2/s, 'scalar expected');

	# Array mismatch
	my $a = explain([1,2,3], [1,9,3]);
	like($a, qr/Array diff/i, 'array diff labelled');
	like($a, qr/2.*vs.*9/s, 'array differing element');

	# Hash mismatch
	my $h = explain({ a => 1, b => 2 }, { a => 1, b => 9 });
	like($h, qr/Hash diff/i, 'hash diff labelled');
	like($h, qr/b.*2.*9/s, 'hash differing key/value');

	# Blessed mismatch
	{
		package Local::Thing;
		sub new { bless { x => shift }, shift }
	}

	my $b = explain(Local::Thing->new(1), Local::Thing->new(2));
	like($b, qr/bless/i, 'blessed structure mentioned');
	like($b, qr/x.*1.*2/s, 'blessed differing internal value');

	# Nested mismatch
	my $n = explain(
		{ a => [1,2], b => { x => 1 } },
		{ a => [1,9], b => { x => 2 } },
	);

	like($n, qr/Array diff/i, 'nested array diff detected');
	like($n, qr/Hash diff/i,  'nested hash diff detected');
};

#------------------------------------------------------------
# Integration: repeated calls must not leak state
#------------------------------------------------------------
subtest 'repeated calls do not leak state' => sub {

	my $first  = explain(1, 2);
	my $second = explain(1, 2);

	isnt($first, undef, 'first call returns string');
	isnt($second, undef, 'second call returns string');

	is($first, $second, 'repeated calls produce identical output');
};

#------------------------------------------------------------
# Integration: diag hook must not interfere with explain()
#------------------------------------------------------------
subtest 'diag() hook does not break explain()' => sub {

	# Simulate a Test::More failure diag
	my $fake_diag = <<'END';
Failed test 'something'
#	 got: 'foo'
# expected: 'bar'
END

	# This should not die, warn, or alter explain()
	lives_ok {
		Test::Builder->new->diag($fake_diag);
	} 'diag hook survives fake failure';

	my $out = explain('foo', 'bar');
	like($out, qr/Scalar/i, 'explain still works after diag hook');
};

done_testing;
