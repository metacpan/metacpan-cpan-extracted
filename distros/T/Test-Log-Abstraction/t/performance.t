#!/usr/bin/env perl

# Regression tests for the performance fixes: the assertions must stop
# looking as soon as their answer is known, and only build the list of
# matches when they need it to explain a failure.  Each is checked by
# counting the work done, not by timing, so the tests are reliable on any
# machine.

use strict;
use warnings;

use lib 't/lib';
use Test::Most;
use Test::Mockingbird;
use Readonly;
use Capture qw(failing);

use Test::Log::Abstraction;

Readonly::Scalar my $CLASS => 'Test::Log::Abstraction';
Readonly::Scalar my $MESSAGES => 1_000;

# A logger holding $MESSAGES messages, the first of them 'needle'
sub haystack {
	my $logger = $CLASS->new(diag => 'none', verbose => 0);
	$logger->info('needle');
	$logger->info("hay $_") foreach 2 .. $MESSAGES;
	return $logger;
}

# A pattern that counts how many messages it is tried against.  It is
# anchored, so its code block runs once per message; and it decides the
# match in code, with no literal text, so perl cannot skip a message
# without running the counter
my $tries = 0;
my $counting = qr/\A(?{ $tries++ })(?(?{ index($_, 'needle') == 0 })|(?!))/;

subtest 'like() stops at the first match' => sub {
	my $logger = haystack();
	$tries = 0;
	ok($logger->like($counting, 'found in the first message'), 'passes');
	is($tries, 1, 'only the first message was tried, not all ' . $MESSAGES);
};

subtest 'unlike() looks at everything only when it must' => sub {
	my $logger = haystack();
	my $collected = spy "${CLASS}::_matching";

	$tries = 0;
	# No literal text in it, so perl cannot skip messages without running
	# the counter; the conditional then always fails
	my $absent = qr/\A(?{ $tries++ })(?(?{ 1 })(?!))/;
	ok($logger->unlike($absent, 'no match anywhere'), 'passes');
	is($tries, $MESSAGES, 'a pass needs every message tried, once each');
	is(scalar(my @calls = $collected->()), 0, 'and no list of matches is built');

	$tries = 0;
	my ($result) = failing(sub { $logger->unlike($counting) });
	ok(!$result, 'fails when there is a match');
	is(scalar(@calls = $collected->()), 1, 'the list of matches is built only to explain the failure');
	restore_all();
};

subtest 'has_level() stops at the first match' => sub {
	my $logger = haystack();
	# A package variable: use overload runs at compile time, so a closure
	# over a lexical here would count into a different copy
	$Local::CountingLevel::compared = 0;
	{
		package Local::CountingLevel;
		our $compared;
		use overload 'eq' => sub { $compared++; return "$_[0]->[0]" eq "$_[1]" }, '""' => sub { $_[0]->[0] }, fallback => 1;
	}
	# Swap each stored level for one that counts comparisons
	$_->{'level'} = bless(['info'], 'Local::CountingLevel') foreach @{$logger->{'messages'}};
	ok($logger->has_level('info', 'found at once'), 'passes');
	is($Local::CountingLevel::compared, 1, 'only the first message was compared');
};

done_testing();
