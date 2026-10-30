#!/usr/bin/env perl

# Transaction-flow tests: a logger is walked through its whole life, and
# each multi-step operation is broken part way through to prove it is all
# or nothing.
#
# The module has no database, but it does have four operations made of
# several steps, each of which can fail after an earlier step has run:
#
#   Operation     Steps                                       If a later step fails
#   ------------  ------------------------------------------  ---------------------------------
#   new()         validate -> copy options -> bless ->        no logger exists; the half-built
#                 language -> diag rule -> level              one is freed; nothing the caller
#                                                             passed has changed
#   clone         copy history -> build (as new) ->           the original is untouched; the
#                 carry over level and verbose                copied history is freed
#   log call      build entry -> store it -> print it         entry fails: nothing is stored;
#                                                             print fails: stored exactly once
#                                                             (it was logged; only the echo
#                                                             failed), the logger still works
#   assertion     check arguments -> compile pattern ->       before the result: no TAP result;
#                 search -> TAP result -> explain             after it: exactly one result; the
#                                                             stored messages never change
#
# Two more kinds of sequence:
#
#   rotation      log -> flush -> reopen -> log, repeated     one history, in order, nothing
#                                                             lost or doubled
#   hostile data  a log call whose data cannot be read        that entry is stored, in plain
#                 (a tied hash that dies, an object whose     form; the entries either side are
#                 text form dies, a cycle), between good ones untouched; nothing dies
#
# And one check of time-of-check to time-of-use: a value that changes each
# time it is read (a tied scalar) is read exactly once, so the value used is
# always the value that was checked.  The module has no files, so this is
# its only check-then-use.
#
# Logging is deliberately not idempotent: logging the same message twice
# stores it twice, as the code under test did log it twice.  Everything
# else (clear, flush, the setters, assertions, cloning without changes,
# building with the same options) gives the same state however many times
# it is repeated.

use strict;
use warnings;

use lib 't/lib';
use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Test::Memory::Cycle;
use Readonly;
use Scalar::Util qw(weaken refaddr);
use Capture qw(failing printed);

use Test::Log::Abstraction;

Readonly::Scalar my $CLASS => 'Test::Log::Abstraction';
Readonly::Scalar my $REPEATS => 3;	# runs of each repeated operation
Readonly::Scalar my $INJECTED => "injected failure\n";
Readonly::Scalar my $TRACE => 7;	# numeric level of 'trace', the default
Readonly::Scalar my $WARNING => 4;	# numeric level of 'warning'
Readonly::Hash my %LEVEL => (warn => $WARNING, notice => 5);
Readonly::Scalar my $SHOW_STATE => $ENV{'TEST_VERBOSE'};
Readonly::Scalar my $PLAIN_HASH => qr/HASH\(0x[0-9a-f]+\)/;

Readonly::Hash my %ENTRY_SCHEMA => (
	type => 'arrayref',
	schema => {
		type => 'hashref',
		schema => {
			level => { type => 'string' },
			message => { type => 'string' },
			fields => { type => 'hashref', optional => 1 },
		},
	},
);

sub quiet {
	return $CLASS->new(diag => 'none', verbose => 0, @_);
}

sub state_diag {
	my ($label, $value) = @_;

	diag(explain({ $label => $value })) if($SHOW_STATE);
	return;
}

# The state a test can see, as one comparable structure
sub snapshot {
	my $logger = shift;

	return {
		messages => [ map { +{ %{$_} } } @{$logger->messages()} ],
		count => $logger->count(),
		level => $logger->level(),
		verbose => $logger->verbose(),
		lang => $logger->lang(),
	};
}

# The invariant that must hold at every boundary: the stored messages are
# well formed, every way of asking how many there are agrees, and the
# settings are in range
sub invariant_holds {
	my ($logger, $where) = @_;

	subtest "invariant: $where" => sub {
		returns_ok($logger->messages(), \%ENTRY_SCHEMA, 'messages are well formed');
		my $count = scalar(@{$logger->messages()});
		is($logger->count(), $count, 'count() agrees with messages()');
		my $by_level = 0;
		my %levels = map { $_->{'level'} => 1 } @{$logger->messages()};
		$by_level += $logger->count($_) foreach(keys %levels);
		is($by_level, $count, 'the per-level counts add up to the total');
		ok(!grep({ $_->{'level'} ne lc($_->{'level'}) } @{$logger->messages()}), 'levels are stored in lower case');
		ok(($logger->level() >= 0) && ($logger->level() <= $TRACE), 'level in range');
		like($logger->verbose(), qr/\A[01]\z/, 'verbose is 0 or 1');
		memory_cycle_ok($logger, 'no cycles, so it is freed when dropped');
		state_diag($where, snapshot($logger));
	};
	return;
}

# How many test results Test::Builder has recorded so far
sub results {
	return Test::Builder->new()->current_test();
}

# ===========================================================================
# Phase 1: the whole lifecycle, in order
# ===========================================================================

subtest 'lifecycle: create, log, assert, change, clone, clear, reuse' => sub {
	# Create
	my $logger = quiet();
	returns_ok($logger, { type => 'object', isa => $CLASS }, 'created');
	ok($logger->empty('starts empty'), 'empty() passes');
	invariant_holds($logger, 'after new');

	# Log: plain, with fields, a misspelt level, chained
	$logger->info('starting')->warn('disk ', 'low', { free => 5 });
	my $misspelt = 'wran';
	printed { $logger->$misspelt('oops') };
	is($logger->count(), 3, 'three entries stored');
	is_deeply($logger->messages()->[1], { level => 'warn', message => 'disk low', fields => { free => 5 } }, 'fields stored with the message');
	invariant_holds($logger, 'after logging');

	# Assert: assertions read the history and never change it
	my $before = snapshot($logger);
	$logger->like(qr/disk low/, 'like finds it');
	$logger->unlike(qr/fatal/, 'unlike finds nothing');
	$logger->has_level('wran', 'misspelt level stored as called');
	is_deeply(snapshot($logger), $before, 'assertions changed nothing');

	# Change settings
	returns_ok($logger->level('warning'), { type => 'object', isa => $CLASS }, 'level set');
	is($logger->verbose(1), 1, 'verbose on');
	ok(!$logger->is_info() && $logger->is_warn(), 'the new level takes effect');
	is($logger->count(), 3, 'changing settings keeps the history');
	invariant_holds($logger, 'after changing settings');

	# Clone: same history and settings, but independent from now on
	my $clone = $logger->new(diag => 'all');
	is_deeply(snapshot($clone), snapshot($logger), 'the clone starts identical');
	isnt(refaddr($clone->messages()->[0]), refaddr($logger->messages()->[0]), 'with its own copies of the entries');
	invariant_holds($clone, 'clone, after cloning');

	# Clear the original: the clone keeps its history
	$logger->clear();
	ok($logger->empty('cleared'), 'the original is empty');
	is($clone->count(), 3, 'the clone still has three');
	invariant_holds($logger, 'after clear');

	# Reuse after clear: the logger works as new, keeping its settings
	printed { $logger->error('again') };
	is($logger->count(), 1, 'logging works after clear');
	is($logger->level(), $WARNING, 'and the level was kept');
	invariant_holds($logger, 'after reuse');
};

# ===========================================================================
# Phase 2: construction fails part way
# ===========================================================================

subtest 'new: a failure after the logger was blessed leaves nothing behind' => sub {
	my %options = (diag => ['warn'], i18n => { en => { captured => 'x' } }, level => 'bogus');
	my $diag_list = $options{'diag'};
	my $config_before = { %Test::Log::Abstraction::config };

	# The level is checked last, after the logger has been blessed and its
	# language and diag rule set: catch the half-built logger on the way
	my $half_built;
	around "${CLASS}::_diag_rule" => sub {
		my ($orig, $self, @args) = @_;
		$half_built = $self;
		weaken($half_built);
		return $orig->($self, @args);
	};
	throws_ok { $CLASS->new(%options) } qr/invalid syslog level 'bogus'/, 'the last step fails';
	restore_all();

	ok(!defined($half_built), 'the half-built logger was freed: no orphan');
	is_deeply($options{'diag'}, ['warn'], "the caller's diag list is unchanged");
	is(refaddr($options{'diag'}), refaddr($diag_list), '... and is the same list');
	is_deeply($options{'i18n'}, { en => { captured => 'x' } }, "the caller's i18n table is unchanged");
	is_deeply({ %Test::Log::Abstraction::config }, $config_before, '%config is unchanged');

	# The failure leaves no state behind: the next construction is normal
	my $logger = $CLASS->new(%options, level => 'info');
	is($logger->level(), 6, 'the same options with a good level work');
	invariant_holds($logger, 'after a failed new');
};

subtest 'new: a failure injected at each step is all or nothing' => sub {
	# Every step of _build, failed in turn: each must leave no logger and
	# no change to what the caller passed
	foreach my $step (qw(_validate _copy_tree _resolve_lang _diag_rule)) {
		my %options = (diag => 'all', i18n => { en => {} }, lang => 'en', level => 'warn');
		my $copy = { %options, i18n => { en => {} } };
		mock "${CLASS}::$step" => sub { die $INJECTED };
		my $logger;
		throws_ok { $logger = $CLASS->new(%options) } qr/\A\Q$INJECTED\E\z/, "$step fails: the error reaches the caller unchanged";
		restore_all();
		ok(!defined($logger), "$step fails: no logger");
		is_deeply(\%options, $copy, "$step fails: the caller's options are unchanged");
		ok(quiet()->empty(), "$step fails: the next logger is built normally");
	}
};

# ===========================================================================
# Phase 3: cloning fails part way
# ===========================================================================

subtest 'clone: a failure leaves the original exactly as it was' => sub {
	my $logger = quiet(level => 'notice');
	$logger->info('one', { id => 1 })->error('two');
	$logger->verbose(1);
	my $before = snapshot($logger);

	# Catch the copied history, so we can prove it is freed with the failure
	my $copied;
	around "${CLASS}::_build" => sub {
		my ($orig, $class, $options, $messages) = @_;
		$copied = $messages;
		weaken($copied);
		return $orig->($class, $options, $messages);
	};
	throws_ok { $logger->new(level => 'bogus') } qr/invalid syslog level 'bogus'/, 'a bad override fails the clone';
	restore_all();

	ok(!defined($copied), 'the copied history was freed: no orphan');
	is_deeply(snapshot($logger), $before, 'the original is unchanged');

	# A failure injected after the history was copied, inside the build
	mock "${CLASS}::_resolve_lang" => sub { die $INJECTED };
	throws_ok { $logger->new() } qr/\A\Q$INJECTED\E\z/, 'an injected failure in the build';
	restore_all();
	is_deeply(snapshot($logger), $before, 'the original is still unchanged');

	# And the clone works once nothing fails
	my $clone = $logger->new();
	is_deeply(snapshot($clone), $before, 'a later clone is a faithful copy');
	invariant_holds($logger, 'after failed clones');
};

# ===========================================================================
# Phase 4: a log call fails part way
# ===========================================================================

subtest 'log call: building the entry fails, so nothing is stored' => sub {
	my $logger = quiet();
	$logger->info('before');

	mock "${CLASS}::_entry" => sub { die $INJECTED };
	throws_ok { $logger->info('lost') } qr/\A\Q$INJECTED\E\z/, 'the error reaches the caller';
	restore_all();

	is($logger->count(), 1, 'no partial entry was stored');
	is($logger->messages()->[0]->{'message'}, 'before', 'the earlier entry is untouched');
	$logger->info('after');
	is($logger->count(), 2, 'the logger keeps working');
	invariant_holds($logger, 'after a failed entry');
};

subtest 'log call: printing fails, so the entry is stored exactly once' => sub {
	# The message was logged; only its echo to the TAP stream failed.  So
	# it stays in the history, once, and the failure is not hidden.
	my $logger = $CLASS->new(diag => 'all', verbose => 0);

	mock "${CLASS}::_emit" => sub { die $INJECTED };
	throws_ok { $logger->warn('echo fails') } qr/\A\Q$INJECTED\E\z/, 'the error reaches the caller';
	restore_all();

	is($logger->count(), 1, 'stored once, not lost and not twice');
	is($logger->messages()->[0]->{'message'}, 'echo fails', 'stored as logged');
	my $out = printed { $logger->warn('next') };
	is($out, "# next\n", 'printing works again');
	is($logger->count(), 2, 'and storing too');
	invariant_holds($logger, 'after a failed print');
};

# ===========================================================================
# Phase 5: an assertion fails part way
# ===========================================================================

subtest 'assertion: a failure before the result records no result' => sub {
	my $logger = quiet();
	$logger->info('x');
	my $before = snapshot($logger);

	# A real failure: the arguments are valid, but the pattern cannot compile
	my $results = results();
	throws_ok { $logger->like('(unclosed', 'never reported') } qr/invalid argument/, 'a bad pattern stops the assertion';
	is(results(), $results + 1, 'no TAP result from it (only from throws_ok)');

	# An injected failure in the search step
	$results = results();
	mock "${CLASS}::_regex" => sub { die $INJECTED };
	my $ok = eval { $logger->like(qr/x/, 'never reported'); 1 };
	my $error = $@;
	restore_all();
	is(results(), $results, 'no TAP result was recorded');
	ok(!$ok && ($error eq $INJECTED), 'the error reached the caller');
	is_deeply(snapshot($logger), $before, 'the stored messages are unchanged');
};

subtest 'assertion: a failure after the result records exactly one' => sub {
	# A TAP result cannot be taken back once printed.  What matters is that
	# there is exactly one, and that the history is still intact.
	my $logger = quiet();
	$logger->info('x');
	my $before = snapshot($logger);

	my $results = results();
	mock "${CLASS}::_explain" => sub { die $INJECTED };
	my ($ok, $error);
	failing(sub { $ok = eval { $logger->like(qr/absent/, 'fails, then explaining fails'); 1 }; $error = $@ });
	restore_all();

	is(results(), $results + 1, 'exactly one TAP result');
	ok(!$ok && ($error eq $INJECTED), 'the error reached the caller');
	is_deeply(snapshot($logger), $before, 'the stored messages are unchanged');
	invariant_holds($logger, 'after a failed explanation');
};

# ===========================================================================
# Phase 6: repeating an operation
# ===========================================================================

subtest 'idempotent: the same construction gives the same, separate logger' => sub {
	my %options = (diag => ['error'], lang => 'de', level => 'notice', verbose => 0);
	my @loggers = map { $CLASS->new(%options) } 1 .. $REPEATS;
	my $first = snapshot($loggers[0]);
	is_deeply(snapshot($_), $first, 'same state') foreach(@loggers[1 .. $#loggers]);

	# Separate: logging to one changes none of the others
	$loggers[0]->notice('only here');
	is($_->count(), 0, 'the others are not affected') foreach(@loggers[1 .. $#loggers]);
};

subtest 'idempotent: clear, flush, reopen, level, verbose' => sub {
	my $logger = quiet();
	$logger->info('a')->error('b');

	foreach my $run (1 .. $REPEATS) {
		returns_ok($logger->clear(), { type => 'object', isa => $CLASS }, "clear, run $run");
		is($logger->count(), 0, "empty after run $run");
	}

	$logger->info('kept');
	my $before = snapshot($logger);
	foreach my $run (1 .. $REPEATS) {
		is($logger->flush(), $logger, "flush, run $run");
		is($logger->reopen(), $logger, "reopen, run $run");
		is($logger->level('warning'), $logger, "level, run $run");
		is($logger->verbose(1), 1, "verbose, run $run");
	}
	is_deeply(snapshot($logger), { %{$before}, level => $WARNING, verbose => 1 }, 'repeating changed nothing more than once did');
	invariant_holds($logger, 'after repeated setters');
};

subtest 'idempotent: assertions give the same answer every time' => sub {
	my $logger = quiet();
	$logger->warn('disk full')->info('ok');
	my $before = snapshot($logger);

	my %answers;
	foreach my $run (1 .. $REPEATS) {
		my $results = results();
		push @{$answers{'like'}}, $logger->like(qr/disk/, "like, run $run");
		push @{$answers{'unlike'}}, $logger->unlike(qr/fatal/, "unlike, run $run");
		push @{$answers{'has_level'}}, $logger->has_level('warn', "has_level, run $run");
		push @{$answers{'count'}}, $logger->count('warn');
		is(results(), $results + 3, "run $run: one result per assertion, no more");
	}
	foreach my $method (sort keys %answers) {
		is(scalar(grep { $_ eq $answers{$method}->[0] } @{$answers{$method}}), $REPEATS, "$method: the same every time");
	}
	is_deeply(snapshot($logger), $before, 'the history is unchanged after all of them');
};

subtest 'idempotent: cloning without changes, again and again' => sub {
	my $logger = quiet(level => 'error');
	$logger->error('one', { n => 1 });
	my $before = snapshot($logger);

	# Each generation is cloned from the last: nothing drifts or is lost
	my $generation = $logger;
	foreach my $run (1 .. $REPEATS) {
		$generation = $generation->new();
		is_deeply(snapshot($generation), $before, "generation $run is identical");
	}
	is_deeply(snapshot($logger), $before, 'the original is unchanged');
	invariant_holds($generation, 'last generation');
};

subtest 'not idempotent, on purpose: logging twice stores twice' => sub {
	my $logger = quiet();
	$logger->warn('same') foreach(1 .. $REPEATS);
	is($logger->count('warn'), $REPEATS, 'one entry per call');
	is(scalar(grep { $_->{'message'} eq 'same' } @{$logger->messages()}), $REPEATS, 'all identical, none merged');
};

# ===========================================================================
# Phase 7: log rotation - flush and reopen between writes
# ===========================================================================

subtest 'rotation: flush and reopen between writes keep one history' => sub {
	# A program that rotates its logs calls flush() and reopen() between
	# writes.  Here they do nothing, so the history must read as if they
	# had never been called: every message once, in the order logged
	my $logger = quiet();
	my @expected;
	foreach my $run (1 .. $REPEATS) {
		$logger->info("before rotation $run");
		returns_ok($logger->flush(), { type => 'object', isa => $CLASS }, "run $run: flush returns the logger");
		returns_ok($logger->reopen(), { type => 'object', isa => $CLASS }, "run $run: reopen returns the logger");
		$logger->warn("after rotation $run");
		push @expected, "before rotation $run", "after rotation $run";
		invariant_holds($logger, "after rotation $run");
	}
	is_deeply([map { $_->{'message'} } @{$logger->messages()}], \@expected, 'every message once, in order');
	$logger->unlike(qr/\A(?:flush|reopen)\z/, 'neither was stored as a message');

	# A clone taken after rotating carries the same history
	is_deeply(snapshot($logger->new()), snapshot($logger), 'a clone after rotation is identical');
};

# ===========================================================================
# Phase 8: hostile data part way through a run
# ===========================================================================

subtest 'hostile data: an entry that cannot be read is stored, the others untouched' => sub {
	# Each of these log calls has data that dies or loops when it is read.
	# None may stop the run: each is stored, in Perl's plain form where it
	# cannot be read, and the good entries either side stay exactly as they
	# were.  The logger prints every level, so the echo is tested too.
	my $logger = $CLASS->new(diag => 'all', verbose => 0);
	tie my %unreadable, 'Local::UnreadableHash';
	my @cycle;
	push @cycle, \@cycle;
	my $error = 'caller error';
	local $@ = $error;

	my $out = printed {
		$logger->info('first');
		$logger->warn('fields', \%unreadable);
		$logger->error('object ', bless({}, 'Local::DyingText'));
		$logger->notice(\@cycle);
		$logger->info('last');
	};
	is($@, $error, "the caller's \$\@ survived the run");
	is($logger->count(), 5, 'five calls, five entries');
	my @message = map { $_->{'message'} } @{$logger->messages()};
	is($message[0], 'first', 'the entry before is untouched');
	like($message[1], qr/\Afields$PLAIN_HASH\z/, 'unreadable fields: kept in the message, in plain form');
	ok(!exists($logger->messages()->[1]->{'fields'}), '... and not stored as fields');
	like($message[2], qr/\Aobject Local::DyingText=$PLAIN_HASH\z/, 'an object whose text form dies: plain form');
	is($message[3], '[(cycle)]', 'a structure that contains itself: cut at the cycle');
	is($message[4], 'last', 'the entry after is untouched');
	is(scalar(() = $out =~ /^# /mg), 5, 'every entry was echoed');
	invariant_holds($logger, 'after hostile data');

	# The rest of the life goes on as normal
	$logger->has_level('error', 'assertions still work');
	my $clone = $logger->new();
	is_deeply(snapshot($clone), snapshot($logger), 'a clone copies the hostile entries too');
	$logger->clear();
	ok($logger->empty('cleared'), 'and clear() removes them');
	is($clone->count(), 5, 'from the original only');
};

# ===========================================================================
# Phase 9: time of check to time of use
# ===========================================================================

subtest 'TOCTOU: a value that changes when read is read once, checked and used' => sub {
	# A tied scalar returns the next value of its list each time it is
	# read.  If a method read it once to check it and again to use it, a
	# good first value could let a bad second one through.  Each method
	# copies its arguments on entry, so the copy is what is checked and
	# what is used: one read, and the result follows the first value
	my $logger = quiet();
	$logger->warn('w');
	$logger->error('e');
	my $tb = Test::Builder->new();
	my %case = (
		'count' => [sub { $logger->count($_[0]) }, ['warn', 'error', 'bogus'], 1],
		'has_level' => [sub { $tb->todo_start('result is not under test'); my $r = $logger->has_level($_[0]); $tb->todo_end(); $r }, ['warn', 'nolevel'], 1],
		'like' => [sub { $tb->todo_start('result is not under test'); my $r = $logger->like($_[0]); $tb->todo_end(); $r }, ['\Aw\z', '['], 1],
		'level' => [sub { $logger->level($_[0]); $logger->level() }, ['notice', 'bogus'], $LEVEL{'notice'}],
		'new: lang' => [sub { quiet(lang => $_[0])->lang() }, ['de', '!!!!', 'fr'], 'de'],
		'new: level' => [sub { quiet(level => $_[0])->level() }, ['warn', 'bogus'], $LEVEL{'warn'}],
		'new: country' => [sub { $CLASS->new(diag => 'none', verbose => 0, country => $_[0])->lang() }, ['FR', 'xyz'], 'fr'],
	);
	foreach my $name (sort keys %case) {
		my ($code, $values, $want) = @{$case{$name}};
		tie my $value, 'Local::Changing', @{$values};
		my $got;
		lives_ok { $got = $code->($value) } "$name: the changed value never reaches the use";
		is($got, $want, "$name: the result follows the value that was checked");
		is(tied($value)->{'reads'}, 1, "$name: read exactly once");
	}
	is($logger->count(), 2, 'the history was never changed');
	invariant_holds($logger, 'after the TOCTOU checks');
};

done_testing();

# A tied hash that dies as soon as it is read
package Local::UnreadableHash;

sub TIEHASH { return bless {}, shift }
sub FIRSTKEY { die "unreadable\n" }
sub SCALAR { die "unreadable\n" }

# An object whose text form dies
package Local::DyingText;

use overload '""' => sub { die "no text\n" }, fallback => 1;

# A scalar that returns the next of its values each time it is read, and
# counts the reads; the last value repeats
package Local::Changing;

sub TIESCALAR {
	my ($class, @values) = @_;

	return bless { values => \@values, reads => 0 }, $class;
}

sub FETCH {
	my $self = shift;

	my $index = $self->{'reads'}++;
	return $self->{'values'}->[($index > $#{$self->{'values'}}) ? -1 : $index];
}
