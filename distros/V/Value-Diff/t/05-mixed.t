use v5.10;
use strict;
use warnings;

use Test::More;
use Value::Diff;

subtest 'testing objects' => sub {
	my $obj_a = bless {a => 1}, 'Value::Diff';
	my $obj_b = bless {a => 1}, 'Value::Diff';

	ok diff($obj_a, $obj_b), 'different objects can be compared (not as hash)';
	ok !diff($obj_a, $obj_a), 'same object is equal to itself';
};

subtest 'testing mixed - no diff' => sub {
	ok !diff({a => [1, 2, 3], b => \42, c => undef}, {a => [1, 2, 3], b => \42, c => undef}), 'mixed ok';
};

subtest 'testing mixed - diff' => sub {
	my $out;

	ok diff({a => [1, 2, 3], b => \42, c => undef}, {a => [1, 3], b => \42, c => undef}, \$out), 'mixed ok';
	is_deeply $out, {a => [2]}, 'diff ok';
};

done_testing;

