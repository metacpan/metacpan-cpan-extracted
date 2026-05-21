use warnings;
use strict;

use Test::More;
use Test::Warnings qw(warning);

BEGIN {
	use_ok('Test::MockModule') or BAIL_OUT "Could not load Test::MockModule";
}

package Test_Intro_Parent; ## no critic (Modules::RequireFilenameMatchesPackage)
our $VERSION = 1;
sub inherited_only { 'inherited_value' }

package Test_Intro; ## no critic (Modules::RequireFilenameMatchesPackage)
our @ISA = ('Test_Intro_Parent');
our $VERSION = 1;
sub foo { 'real_foo' }
sub bar { 'real_bar' }
sub baz { 'real_baz' }
package main;

# --- mocked_subs() ---

# GH #52: introspection of what's currently mocked

ok(Test::MockModule->can('mocked_subs'), 'mocked_subs() exists');

{
	my $mock = Test::MockModule->new('Test_Intro', no_auto => 1);

	my @empty = $mock->mocked_subs;
	is_deeply(\@empty, [], 'mocked_subs returns empty list when nothing mocked');

	$mock->mock('foo', sub { 'mocked' });
	my @one = $mock->mocked_subs;
	is_deeply(\@one, ['foo'], 'mocked_subs returns single mocked sub');

	$mock->mock('baz', sub { 'mocked' });
	$mock->mock('bar', sub { 'mocked' });
	my @multi = $mock->mocked_subs;
	is_deeply(\@multi, ['bar', 'baz', 'foo'], 'mocked_subs returns sorted list');

	$mock->unmock('baz');
	my @after_unmock = $mock->mocked_subs;
	is_deeply(\@after_unmock, ['bar', 'foo'], 'mocked_subs reflects unmock');

	$mock->unmock_all;
	my @after_all = $mock->mocked_subs;
	is_deeply(\@after_all, [], 'mocked_subs is empty after unmock_all');
}

# mocked_subs after scope exit (DESTROY calls unmock_all)
{
	my $mock = Test::MockModule->new('Test_Intro', no_auto => 1);
	$mock->mock('foo', sub { 'mocked' });
	my @before = $mock->mocked_subs;
	is(scalar @before, 1, 'one sub mocked before scope exit');
}
# After scope exit, a new mock object should have nothing mocked
{
	my $mock = Test::MockModule->new('Test_Intro', no_auto => 1);
	my @fresh = $mock->mocked_subs;
	is_deeply(\@fresh, [], 'new object after scope exit has no mocked_subs');
}

# --- original() when not mocked (GH #42) ---

{
	my $mock = Test::MockModule->new('Test_Intro', no_auto => 1);

	# original() on an unmocked sub should return the real sub
	my $orig = $mock->original('foo');
	is(ref $orig, 'CODE', 'original() returns coderef when not mocked');
	is($orig->(), 'real_foo', 'original() returns the actual sub when not mocked');

	# Now mock it, check original still works
	$mock->mock('foo', sub { 'mocked_foo' });
	my $orig_after_mock = $mock->original('foo');
	is(ref $orig_after_mock, 'CODE', 'original() returns coderef when mocked');
	is($orig_after_mock->(), 'real_foo', 'original() returns the real sub when mocked');

	# After unmock, original() should still work
	$mock->unmock('foo');
	my $orig_after_unmock = $mock->original('foo');
	is(ref $orig_after_unmock, 'CODE', 'original() returns coderef after unmock');
	is($orig_after_unmock->(), 'real_foo', 'original() returns real sub after unmock');
}

# original() with closure over $mock doesn't leak (GH #42 example)
{
	my $mock = Test::MockModule->new('Test_Intro', no_auto => 1);

	# Get original before mocking (new behavior: no warning)
	my $orig = $mock->original('bar');
	$mock->mock('bar', sub { 'prefix_' . $orig->() });
	is(Test_Intro::bar(), 'prefix_real_bar', 'original() before mock enables safe wrapping');
}

# original() carps on invalid subroutine name
{
	my $mock = Test::MockModule->new('Test_Intro', no_auto => 1);
	my $w = warning { eval { $mock->original('123bad') } };
	like("$w", qr/Please provide a valid function name/,
		'original() carps when subroutine name is invalid');
}

# original() falls through to SUPER for inherited subs not in target package (GH covers line 238)
{
	my $mock = Test::MockModule->new('Test_Intro', no_auto => 1);
	my $orig = $mock->original('inherited_only');
	is(ref $orig, 'CODE',
		'original() returns coderef for inherited (parent-only) sub');
	is($orig->(), 'inherited_value',
		'original() returns parent sub when target package has no own copy');
}

done_testing;
