use v5.10;
use strict;
use warnings;

use Test::More;
use Value::Diff;

subtest 'testing hash - no diff' => sub {
	ok !diff({}, {}), 'empty hash is equal to empty hash';
	ok !diff({a => 1}, {a => 1}), 'hash with one element is equal to hash with one element';
	ok !diff({a => 1, b => 2}, {a => 1, b => 2}), 'hash with two elements is equal to hash with two elements';
	ok !diff({a => 1}, {a => 1, b => 2}), 'there is no diff if second hash has extra elements';

	ok !diff(
		{a => {b => {f => 'test', g => 1}}, c => {d => 1, e => 2}},
		{a => {b => {f => 'test', g => 1}}, c => {d => 1, e => 2}}
		),
		'deep nested ok';
};

subtest 'testing hash - diff' => sub {
	my $out;

	ok diff({a => 1}, {}, \$out), 'hash with one element is not equal to empty hash';
	is_deeply $out, {a => 1}, 'diff ok';

	ok diff({a => 1}, {a => 2}, \$out), 'hashes differ when one element differs (out of one)';
	is_deeply $out, {a => 1}, 'diff ok';

	ok diff({a => 1, b => 2}, {a => 1}, \$out), 'hashes differ when first hash has extra elements';
	is_deeply $out, {b => 2}, 'diff ok';

	ok diff({a => 1, b => undef}, {a => 1}, \$out), 'not existing keys are handled correctly';
	is_deeply $out, {b => undef}, 'diff ok';

	ok diff({a => 2, b => undef}, {a => 2, b => 'test'}, \$out),
		'hashes differ when one element differs (out of two)';
	is_deeply $out, {b => undef}, 'diff ok';

	ok diff(
		{a => {b => {f => 'test', g => 1}}, c => {d => 1, e => 2}},
		{a => {b => {f => 'test'}}, c => {d => 1, e => 2}}, \$out
		),
		'deep nested ok';
	is_deeply $out, {a => {b => {g => 1}}}, 'diff ok';
};

done_testing;

