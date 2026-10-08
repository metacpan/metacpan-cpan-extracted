use strict;
use warnings;

use Test::Most;
use Test::Builder;
use_ok('Test::Log::Abstraction');

# prove -v exports TEST_VERBOSE=1, which would make every message print;
# these tests control verbosity explicitly.
$ENV{'TEST_VERBOSE'} = 0;
$ENV{'VERBOSE'} = 0;

# Capture: every level records, in order, without printing by default
{
	my $logger = Test::Log::Abstraction->new(diag => 'none');

	$logger->trace('t1');
	$logger->debug('d1');
	$logger->info('i1');
	$logger->notice('n1');
	$logger->warn('w1');
	$logger->error('e1');
	$logger->critical('c1');
	$logger->emergency('m1');

	my $messages = $logger->messages();
	is(scalar @{$messages}, 8, 'all eight messages captured');
	is_deeply([ map { $_->{'level'} } @{$messages}],
		[qw(trace debug info notice warn error critical emergency)],
		'messages keep call order');
	is($messages->[0]->{'message'}, 't1', 'message text captured');
	is($messages->[4]->{'message'}, 'w1', 'warn message captured');

	is($logger->count(), 8, 'count() counts everything');
	is($logger->count('error'), 1, 'count($level) counts one level');
	is($logger->count('debug'), 1, 'count(debug)');
	is($logger->count('fatal'), 0, 'count of a level never logged');
}

# Syslog aliases record under their own name
{
	my $logger = Test::Log::Abstraction->new(diag => 'none');

	$logger->err('e');
	$logger->crit('c');
	$logger->emerg('m');
	$logger->warning('w');
	$logger->informational('i');
	$logger->fatal('f');
	$logger->alert('a');
	$logger->panic('p');
	$logger->debug('d');

	is($logger->count(), 9, 'alias methods all record');
	is($logger->count('err'), 1, 'err alias');
	is($logger->count('crit'), 1, 'crit alias');
	is($logger->count('emerg'), 1, 'emerg alias');
}

# clear() empties and returns the logger for chaining
{
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	$logger->warn('w');
	is($logger->count(), 1, 'one message before clear');
	my $returned = $logger->clear();
	is($returned, $logger, 'clear() returns $self');
	is($logger->count(), 0, 'clear() empties the capture');
}

# Assertions report through Test::Builder and return their result.  Each
# call emits its own TAP test, so the failing paths are wrapped in TODO to
# keep this file green while still checking the return value.
{
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	my $tb = Test::Builder->new;
	$logger->warn('the widget was updated');

	ok($logger->like(qr/updated/, 'like() passes on a match'), 'like returns true on a match');

	$tb->todo_start('expected failure');
	my $no_match = $logger->like(qr/nonexistent/, 'like() fails on no match');
	$tb->todo_end();
	ok(!$no_match, 'like returns false when nothing matches');

	ok($logger->unlike(qr/fatal/, 'unlike() passes when nothing matches'), 'unlike returns true when nothing matches');

	$tb->todo_start('expected failure');
	my $did_match = $logger->unlike(qr/widget/, 'unlike() fails when something matches');
	$tb->todo_end();
	ok(!$did_match, 'unlike returns false when something matches');

	ok($logger->has_level('warn', 'has_level finds warn'), 'has_level returns true when present');

	$tb->todo_start('expected failure');
	my $missed = $logger->has_level('error', 'has_level misses error');
	$tb->todo_end();
	ok(!$missed, 'has_level returns false when absent');

	$tb->todo_start('expected failure');
	my $not_empty = $logger->empty('not empty');
	$tb->todo_end();
	ok(!$not_empty, 'empty returns false when messages exist');

	$logger->clear();
	ok($logger->empty('nothing logged'), 'empty() passes when empty');
	ok($logger->unlike(qr/widget/), 'unlike passes when empty');

	$tb->todo_start('expected failure');
	my $no_warn = $logger->has_level('warn');
	$tb->todo_end();
	ok(!$no_warn, 'has_level returns false when empty');
}

# like() croaks without a pattern; has_level croaks without a level
{
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	my $file = __FILE__;
	throws_ok { $logger->like() } qr/like\(\) needs a pattern at \Q$file\E/, 'like() needs a pattern';
	throws_ok { $logger->unlike() } qr/unlike\(\) needs a pattern at \Q$file\E/, 'unlike() needs a pattern';
	throws_ok { $logger->has_level() } qr/has_level\(\) needs a level name at \Q$file\E/, 'has_level() needs a level';
}

# verbose() get/set
{
	my $logger = Test::Log::Abstraction->new(diag => 'none');
	is($logger->verbose(), 0, 'verbose off');
	$logger->verbose(1);
	is($logger->verbose(), 1, 'verbose turned on');
	$logger->verbose(0);
	is($logger->verbose(), 0, 'verbose turned off');
}

# Message is a method on the logger, not a global
{
	my $a = Test::Log::Abstraction->new(diag => 'none');
	my $b = Test::Log::Abstraction->new(diag => 'none');
	$a->warn('only in a');
	is($a->count(), 1, 'logger A captured');
	is($b->count(), 0, 'logger B isolated from A');
}

done_testing();
