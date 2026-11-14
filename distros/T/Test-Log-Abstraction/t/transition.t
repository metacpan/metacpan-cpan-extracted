#!/usr/bin/env perl

# State transition tests: the state machine in the POD's STATE DIAGRAM,
# checked edge by edge.
#
#   States:   (none)     before new(), or after new() croaked
#             EMPTY      a logger with no stored messages
#             CAPTURING  a logger with one or more stored messages
#             DESTROYED  the last reference has gone
#
#   Edges:    (none)    --new(valid)-----------------------> EMPTY
#             (none)    --new(invalid)---------------------> (none), croak
#             EMPTY     --level method / unknown method----> CAPTURING
#             CAPTURING --level method / unknown method----> CAPTURING (+1)
#             CAPTURING --clear()--------------------------> EMPTY
#             either    --verbose(), level(), read-only----> same state
#                         (read-only includes i18n(), and DESTROY()
#                         called directly)
#             either    --bad argument / not a logger------> same state, croak
#             either    --$logger->new()-------------------> new logger, same state
#             either    --last reference goes--------------> DESTROYED
#             (none)    --i18n() or _emit() on the class---> (none), no logger
#
# The state is never read from inside the object: it is worked out from
# what the public API reports, and every way of asking must agree.

use strict;
use warnings;

use lib 't/lib';
use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Test::Mockingbird::TimeTravel ();	# its restore_all() would clash with Test::Mockingbird's
use Readonly;
use Errno qw(ENOENT);
use Scalar::Util qw(weaken);
use Capture qw(failing printed);

use Test::Log::Abstraction;

Readonly::Scalar my $CLASS => 'Test::Log::Abstraction';
Readonly::Scalar my $EMPTY => 'EMPTY';
Readonly::Scalar my $CAPTURING => 'CAPTURING';
Readonly::Scalar my $MESSAGE => 'payload';
Readonly::Scalar my $UNKNOWN => 'wran';	# a misspelt level
Readonly::Scalar my $TRACE => 7;	# the default level number
Readonly::Scalar my $ERROR => 3;	# the level number of 'error'
Readonly::Scalar my $MAX_SHOWN => 200;	# characters of a name repeated in a notice
Readonly::Scalar my $SHOW_STATE => $ENV{'TEST_VERBOSE'};
Readonly::Scalar my $MODULE_FILE => $INC{'Test/Log/Abstraction.pm'};
Readonly::Scalar my $EPOCH => '2026-01-01T00:00:00Z';	# any fixed moment
Readonly::Scalar my $DECADE => 3653;	# days, to jump far past any plausible timeout
Readonly::Scalar my $INNER => 'inner';


# Every level method, and whether the default diag rule ('warning' and
# more severe) prints it
Readonly::Hash my %PRINTED_BY_DEFAULT => (
	trace => 0, debug => 0, info => 0, informational => 0, notice => 0,
	warn => 1, warning => 1, error => 1, err => 1, critical => 1, crit => 1,
	fatal => 1, alert => 1, emergency => 1, emerg => 1, panic => 1,
);
Readonly::Array my @PREDICATES => qw(is_trace is_debug is_info is_notice is_warn is_error is_critical is_alert is_emergency);

# The part of the diagram each public method plays.  Every method the POD
# documents must be here, and every one here must be in the POD: a method
# added without a place in the diagram is an FSM discrepancy.
#   store    EMPTY or CAPTURING -> CAPTURING, one more message
#   clear    EMPTY or CAPTURING -> EMPTY
#   setting  same state, same messages; a setting changes
#   assert   same state; one TAP result
#   read     same state; nothing printed, no TAP result
#   print    same state; prints (the subclass hook _emit)
#   copy     same state; a new logger in that state
#   end      called directly: same state
Readonly::Hash my %ROLE => (
	(map { $_ => 'store' } qw(trace debug info notice warn error fatal critical alert emergency AUTOLOAD)),
	clear => 'clear',
	verbose => 'setting', level => 'setting',
	(map { $_ => 'assert' } qw(like unlike has_level empty)),
	(map { $_ => 'read' } qw(messages count lang flush reopen i18n), @PREDICATES),
	_emit => 'print',
	new => 'copy',
	DESTROY => 'end',
);

# Out of the way of a developer's environment
delete local $ENV{'TEST_VERBOSE'};
delete local $ENV{'VERBOSE'};

# A logger with the default diag rule, and verbose off
sub fresh {
	return $CLASS->new(verbose => 0, @_);
}

# A logger in the CAPTURING state, printing nothing
sub capturing {
	my $logger = $CLASS->new(diag => 'none', verbose => 0, @_);
	$logger->info($MESSAGE);
	return $logger;
}

# The state, worked out from the public API.  count(), empty-ness of
# messages() and empty() must agree, or the state is not well defined.
sub state_of {
	my $logger = shift;

	my $count = $logger->count();
	my $listed = scalar(@{$logger->messages()});
	die "count() says $count but messages() has $listed" if($count != $listed);
	return $count ? $CAPTURING : $EMPTY;
}

# Everything that could change, for "nothing changed" checks
sub snapshot {
	my $logger = shift;

	return {
		state => state_of($logger),
		messages => [ map { +{ %{$_} } } @{$logger->messages()} ],
		level => $logger->level(),
		verbose => $logger->verbose(),
		lang => $logger->lang(),
	};
}

# Test::Most exports show(), so this has another name
sub show_state {
	my ($label, $logger) = @_;

	diag(explain({ $label => snapshot($logger) })) if($SHOW_STATE);
	return;
}

sub results {
	return Test::Builder->new()->current_test();
}

# ===========================================================================
# Creation
# ===========================================================================

subtest "State: (none) -> Trigger: new(valid) -> State: $EMPTY" => sub {
	foreach my $options ([], [diag => 'all'], [level => 'error', verbose => 1], [lang => 'de', country => 'FR']) {
		my $logger = $CLASS->new(@{$options});
		returns_ok($logger, { type => 'object', isa => $CLASS }, 'a logger is made: ' . explain($options));
		is(state_of($logger), $EMPTY, '... in EMPTY');
	}
	# The documented side effects: options checked, language, diag rule and
	# level chosen
	my $logger = $CLASS->new(lang => 'de', level => 'error', diag => 'none');
	is($logger->lang(), 'de', 'language chosen');
	is($logger->level(), $ERROR, 'level chosen');
	my $out = printed { $logger->emergency('x') };
	is($out, '', 'diag rule chosen (none: not even emergency is printed)');
};

subtest 'State: (none) -> Trigger: new(invalid) -> croak, no logger' => sub {
	my %invalid = (
		'bad level' => [level => 'bogus'],
		'bad diag' => [diag => 'loud'],
		'bad diag type' => [diag => {}],
		'bad lang' => [lang => '!!'],
		'bad country' => [country => 'GBR'],
		'bad i18n' => [i18n => 'not a hash'],
	);
	foreach my $case (sort keys %invalid) {
		my $logger;
		throws_ok { $logger = $CLASS->new(@{$invalid{$case}}) } qr/\A\Q$CLASS\E: /, "$case: croaks";
		ok(!defined($logger), "$case: no logger made");
	}
};

subtest "Negative: new() cannot create a logger outside $EMPTY" => sub {
	# Internal state is kept apart from options, so an option cannot start
	# a logger with messages already in it
	my $logger = $CLASS->new(messages => [{ level => 'info', message => 'planted' }]);
	is(state_of($logger), $EMPTY, "a 'messages' option is ignored: still EMPTY");
};

# ===========================================================================
# Storing messages
# ===========================================================================

subtest "State: $EMPTY -> Trigger: level method -> State: $CAPTURING" => sub {
	foreach my $method (sort keys %PRINTED_BY_DEFAULT) {
		my $logger = fresh();
		local $@ = 'earlier error';
		local $! = ENOENT;
		my $errno = "$!";
		my $out = printed { $logger->$method($MESSAGE) };
		is(state_of($logger), $CAPTURING, "$method: now CAPTURING");
		is_deeply($logger->messages(), [{ level => $method, message => $MESSAGE }], "$method: stored under its own name");
		is($out, $PRINTED_BY_DEFAULT{$method} ? "# $MESSAGE\n" : '', "$method: printed only if the diag rule allows");
		is($@, 'earlier error', "$method: \$\@ kept");
		is("$!", $errno, "$method: \$! kept");
	}
	# verbose overrides the diag rule
	my $logger = fresh(diag => 'none', verbose => 1);
	is(printed { $logger->trace($MESSAGE) }, "# $MESSAGE\n", 'verbose: printed whatever the diag rule');
};

subtest "State: $EMPTY -> Trigger: warn() and above, no arguments -> State: $EMPTY" => sub {
	# As in Log::Abstraction: no arguments at warn or above logs nothing,
	# while the less serious levels store an empty message.  The levels at
	# warn or above are exactly those the default diag rule prints.
	foreach my $method (sort keys %PRINTED_BY_DEFAULT) {
		my $logger = fresh();
		my $out = printed { is($logger->$method(), $logger, "$method(): returns the logger") };
		if($PRINTED_BY_DEFAULT{$method}) {
			is(state_of($logger), $EMPTY, "$method(): still EMPTY");
			is($out, '', "$method(): nothing printed");
		} else {
			is(state_of($logger), $CAPTURING, "$method(): CAPTURING");
			is_deeply($logger->messages(), [{ level => $method, message => '' }], "$method(): an empty message");
		}
	}
	# An unknown method is still a mistake worth reporting, with or without
	# arguments
	my $logger = fresh(diag => 'none');
	printed { $logger->$UNKNOWN() };
	is(state_of($logger), $CAPTURING, 'an unknown method with no arguments is still stored');
};

subtest "State: $EMPTY -> Trigger: unknown method (AUTOLOAD) -> State: $CAPTURING" => sub {
	# 'always print', even with nothing else printed
	my $logger = fresh(diag => 'none');
	my $out = printed { $logger->$UNKNOWN($MESSAGE) };
	is(state_of($logger), $CAPTURING, 'now CAPTURING');
	is_deeply($logger->messages(), [{ level => $UNKNOWN, message => $MESSAGE }], 'stored under the name called');
	is($out, "# $CLASS: no method '$UNKNOWN'\n", 'the notice is printed although diag is none');

	# The diagram's side effect: the name in the notice is escaped and cut,
	# while the message is stored under the name exactly as called
	my $hostile = "a\nok 1" . ('x' x $MAX_SHOWN);
	my $other = fresh(diag => 'none');
	$out = printed { $other->$hostile($MESSAGE) };
	is($other->messages()->[0]->{'level'}, $hostile, 'a hostile name is stored as called');
	is(scalar($out =~ tr/\n//), 1, 'but its notice is one line');
	like($out, qr/no method 'a\\x0Aok 1x+\.\.\.'\n\z/, 'escaped and cut, as the diagram says');
	is(length(($out =~ /no method '(.*)\.\.\.'/)[0]), $MAX_SHOWN, "cut to $MAX_SHOWN characters");
};

subtest "State: $CAPTURING -> Trigger: warn() and above, no arguments -> State: $CAPTURING (+0)" => sub {
	# The '(or CAPTURING)' half of the diagram's no-argument rule: at warn
	# or above, nothing is added; below it, one empty message
	foreach my $method (sort keys %PRINTED_BY_DEFAULT) {
		my $logger = capturing();
		my $before = snapshot($logger);
		$logger->$method();
		is(state_of($logger), $CAPTURING, "$method(): still CAPTURING");
		if($PRINTED_BY_DEFAULT{$method}) {
			is_deeply(snapshot($logger), $before, "$method(): nothing added");
		} else {
			is_deeply($logger->messages()->[-1], { level => $method, message => '' }, "$method(): one empty message added");
		}
	}
};

subtest "State: $CAPTURING -> Trigger: level or unknown method -> State: $CAPTURING (+1)" => sub {
	my $logger = capturing();
	my $before = $logger->count();
	$logger->error('two');
	is(state_of($logger), $CAPTURING, 'still CAPTURING after a level method');
	is($logger->count(), $before + 1, 'one more message');
	printed { $logger->$UNKNOWN('three') };
	is(state_of($logger), $CAPTURING, 'still CAPTURING after an unknown method');
	is($logger->count(), $before + 2, 'one more again');
	is_deeply([ map { $_->{'message'} } @{$logger->messages()} ], [$MESSAGE, 'two', 'three'], 'oldest first, none lost');
};

# ===========================================================================
# Clearing
# ===========================================================================

subtest "State: $CAPTURING -> Trigger: clear() -> State: $EMPTY" => sub {
	my $logger;
	printed { $logger = capturing(level => 'error', verbose => 1); $logger->warn('more') };
	returns_ok($logger->clear(), { type => 'object', isa => $CLASS }, 'returns the logger');
	is(state_of($logger), $EMPTY, 'now EMPTY');
	is($logger->level(), $ERROR, 'the level is kept');
	is($logger->verbose(), 1, 'verbose is kept');
	ok($logger->empty('empty() agrees'), 'empty() passes');
};

subtest "State: $EMPTY -> Trigger: clear() -> State: $EMPTY" => sub {
	# The diagram's self-loop on EMPTY: nothing to delete, so nothing
	# changes, and the logger is returned for chaining
	my $logger = fresh();
	my $before = snapshot($logger);
	is($logger->clear(), $logger, 'accepted, returns the logger');
	is_deeply(snapshot($logger), $before, 'still EMPTY, nothing changed');
};

subtest "Negative: no way back to $EMPTY except clear()" => sub {
	my $logger = capturing();
	# The list from messages() is a copy: emptying it does not empty the logger
	@{$logger->messages()} = ();
	is(state_of($logger), $CAPTURING, 'emptying the copy from messages(): still CAPTURING');
	# Neither settings, nor reads, nor a clone, nor flush empty it
	$logger->level('emergency');
	$logger->verbose(0);
	$logger->flush();
	$logger->count();
	$logger->new(messages => []);
	is(state_of($logger), $CAPTURING, 'setters, flush, count and cloning: still CAPTURING');
};

# ===========================================================================
# Changes allowed in both states
# ===========================================================================

foreach my $state ($EMPTY, $CAPTURING) {
	subtest "State: $state -> Trigger: verbose(1) / verbose(0) -> State: $state" => sub {
		my $logger = ($state eq $EMPTY) ? fresh(diag => 'none') : capturing();
		my $messages = snapshot($logger)->{'messages'};
		is($logger->verbose(1), 1, 'verbose on');
		is(state_of($logger), $state, "still $state");
		is_deeply(snapshot($logger)->{'messages'}, $messages, 'messages unchanged');
		$logger->clear() if($state eq $EMPTY);	# only to look at printing below
		is(printed { $logger->debug('seen') }, "# seen\n", 'from now on: every message is printed');
		$logger->clear() if($state eq $EMPTY);
		is($logger->verbose(0), 0, 'verbose off');
		is(state_of($logger), $state, "still $state");
		is(printed { $logger->debug('unseen') }, '', 'from now on: the diag rule decides');
	};

	subtest "State: $state -> Trigger: level('error') -> State: $state" => sub {
		my $logger = ($state eq $EMPTY) ? fresh(diag => 'none') : capturing();
		my $before = snapshot($logger);
		is($logger->level('error'), $logger, 'returns the logger');
		is($logger->level(), $ERROR, 'level number = 3');
		is_deeply(snapshot($logger), { %{$before}, level => $ERROR }, "still $state, only the level changed");
		# The is_* answers change
		is_deeply({ map { $_ => $logger->$_() } @PREDICATES },
			{ is_trace => 0, is_debug => 0, is_info => 0, is_notice => 0, is_warn => 0, is_error => 1, is_critical => 1, is_alert => 1, is_emergency => 1 },
			'is_* answers follow the level');
		# Nothing is hidden: a less severe message is still stored
		my $count = $logger->count();
		$logger->trace('below the level');
		is($logger->count(), $count + 1, 'a message below the level is still stored');
	};

	subtest "State: $state -> Trigger: level('bogus') -> State: $state" => sub {
		my $logger = ($state eq $EMPTY) ? fresh() : capturing();
		my $before = snapshot($logger);
		my $result = 'unset';
		warning_like { $result = $logger->level('bogus') } qr/invalid syslog level 'bogus'/, 'a warning';
		is($result, undef, 'returns undef');
		is_deeply(snapshot($logger), $before, "still $state, nothing changed");
	};
}

# ===========================================================================
# Read-only calls in both states
# ===========================================================================

foreach my $state ($EMPTY, $CAPTURING) {
	subtest "State: $state -> Trigger: like, unlike, has_level, empty -> State: $state" => sub {
		my $logger = ($state eq $EMPTY) ? fresh(diag => 'none') : capturing();
		my $before = snapshot($logger);
		my $has = ($state eq $CAPTURING);

		# Each makes exactly one TAP result.  Assertions that are meant to
		# fail in this state are run with failing(), which also returns
		# what was printed to explain the failure.
		my %assertions = (
			like => sub { $logger->like(qr/\Q$MESSAGE\E/) },
			unlike => sub { $logger->unlike(qr/\Q$MESSAGE\E/) },
			has_level => sub { $logger->has_level('info') },
			empty => sub { $logger->empty() },
		);
		my %passes = (like => $has, unlike => !$has, has_level => $has, empty => !$has);
		foreach my $method (sort keys %assertions) {
			my $results = results();
			if($passes{$method}) {
				ok($assertions{$method}->(), "$method passes in $state");
				is(results(), $results + 2, "$method: one TAP result (plus this file's own)");
			} else {
				my ($result, $out) = failing($assertions{$method});
				ok(!$result, "$method fails in $state");
				is(results(), $results + 2, "$method: one TAP result (plus this file's own)");
				my $heading = $has ? '1 message (?:was captured|matched):' : 'no messages were captured';
				like($out, qr/\Q$CLASS\E: $heading/, "$method: the failure is explained");
			}
			is_deeply(snapshot($logger), $before, "$method: still $state, nothing changed");
		}
	};

	subtest "State: $state -> Trigger: count, messages, lang, is_*, flush, reopen, i18n -> State: $state" => sub {
		my $logger = ($state eq $EMPTY) ? fresh() : capturing();
		my $before = snapshot($logger);
		my $results = results();
		my $out = printed {
			$logger->count();
			$logger->count('info');
			$logger->messages();
			$logger->lang();
			$logger->$_() foreach(@PREDICATES);
			$logger->flush();
			$logger->reopen();
			$logger->i18n('no_method', { method => $UNKNOWN });
		};
		is(results(), $results, 'no TAP results');
		is($out, '', 'nothing printed');
		is_deeply(snapshot($logger), $before, "still $state, nothing changed");
		is($logger->flush(), $logger, 'flush returns the logger');
		is($logger->reopen(), $logger, 'reopen returns the logger');
		is($logger->i18n('no_method', { method => $UNKNOWN }), "$CLASS: no method '$UNKNOWN'", 'i18n returns the text');
	};

	subtest "State: $state -> Trigger: DESTROY() called directly -> State: $state" => sub {
		# Only the last reference going away ends a logger; calling DESTROY
		# by hand does nothing, so the logger is still alive and usable
		# Made inside printed(): with diag 'all', capturing()'s own message
		# would otherwise reach the TAP output
		my $logger;
		printed { $logger = ($state eq $EMPTY) ? fresh(diag => 'all') : capturing(diag => 'all') };
		my $before = snapshot($logger);
		my $out = printed { $logger->DESTROY() };
		is($out, '', 'nothing printed');
		is_deeply(snapshot($logger), $before, "still $state, nothing changed");
		printed { $logger->info('afterwards') };
		is($logger->count(), scalar(@{$before->{'messages'}}) + 1, 'and it still logs');
	};

	subtest "State: $state -> Trigger: bad argument -> croak, State: $state" => sub {
		my $logger = ($state eq $EMPTY) ? fresh() : capturing();
		my $before = snapshot($logger);
		my %bad = (
			'like(undef)' => [sub { $logger->like(undef) }, qr/like\(\) needs a pattern/],
			'unlike(undef)' => [sub { $logger->unlike(undef) }, qr/unlike\(\) needs a pattern/],
			'has_level(undef)' => [sub { $logger->has_level(undef) }, qr/has_level\(\) needs a level name/],
			'like(malformed)' => [sub { $logger->like('(') }, qr/invalid argument/],
			'like(reference)' => [sub { $logger->like([]) }, qr/invalid argument/],
			'count(reference)' => [sub { $logger->count({}) }, qr/invalid argument/],
			'empty(reference name)' => [sub { $logger->empty([]) }, qr/invalid argument/],
			'clone(bad level)' => [sub { $logger->new(level => 'bogus') }, qr/invalid syslog level/],
		);
		foreach my $case (sort keys %bad) {
			my $results = results();
			throws_ok { $bad{$case}->[0]->() } $bad{$case}->[1], "$case croaks";
			is(results(), $results + 1, "$case: no TAP result of its own");
			is_deeply(snapshot($logger), $before, "$case: still $state, nothing changed");
		}
	};
}

subtest 'Negative: no transition from something that is not a logger' => sub {
	# A real logger, to prove none of these calls reaches it
	my $logger = capturing();
	my $before = snapshot($logger);
	my %invocants = (
		'the class name' => $CLASS,
		'undef' => undef,
		'a plain reference' => {},
		"another class's object" => bless({}, 'Local::Other'),
	);
	# Every trigger in the diagram that is a method call
	my @triggers = ('info', 'warn', $UNKNOWN, 'clear', 'verbose', 'level', 'like', 'unlike', 'has_level', 'empty', 'count', 'messages', 'lang', 'flush', 'reopen', 'is_info');
	foreach my $who (sort keys %invocants) {
		foreach my $method (@triggers) {
			# Called as a function, so that undef and plain references can
			# be the invocant; an unknown name goes through AUTOLOAD
			my $code = ($method eq $UNKNOWN) ? sub { no strict 'refs'; local $Test::Log::Abstraction::AUTOLOAD = "${CLASS}::$UNKNOWN"; Test::Log::Abstraction::AUTOLOAD($invocants{$who}, $MESSAGE) }	## no critic (ProhibitNoStrict)
				: do { no strict 'refs'; my $sub = \&{"${CLASS}::$method"}; sub { $sub->($invocants{$who}, qr/x/) } };	## no critic (ProhibitNoStrict)
			throws_ok { $code->() } qr/\Q$CLASS\E: \Q$method\E\(\) must be called on an object, not on the class/, "$method on $who: croaks";
		}
	}
	is_deeply(snapshot($logger), $before, 'the real logger was never touched');
};

subtest 'State: (none) -> Trigger: i18n() or _emit() on the class -> State: (none)' => sub {
	# The one exception to "not a logger: croak".  Both are methods for
	# subclasses, and work on the class name, so no logger is needed - and
	# none is made
	my $made = spy "${CLASS}::_build";
	my $text;
	lives_ok { $text = $CLASS->i18n('no_method', { method => $UNKNOWN }) } 'i18n on the class: no croak';
	is($text, "$CLASS: no method '$UNKNOWN'", '... and it returns the text');
	my $returned;
	my $out = printed { $returned = $CLASS->_emit($MESSAGE) };
	is($out, "# $MESSAGE\n", '_emit on the class: prints');
	is($returned, $CLASS, '... and returns the class name');
	my @built = $made->();
	restore_all();
	is(scalar(@built), 0, 'no logger was built for either');
};

# ===========================================================================
# Copying
# ===========================================================================

foreach my $state ($EMPTY, $CAPTURING) {
	subtest "State: $state -> Trigger: \$logger->new(%options) -> new logger in $state" => sub {
		my $logger = ($state eq $EMPTY) ? fresh(diag => 'none') : capturing();
		$logger->level('error');
		$logger->verbose(1);
		my $before = snapshot($logger);

		my $copy = $logger->new();
		is(state_of($copy), $state, "the copy is in $state");
		is_deeply(snapshot($copy), $before, 'with copies of the messages, and the same verbose and level');
		is_deeply(snapshot($logger), $before, 'the original did not change');

		my $changed = $logger->new(level => 'trace', verbose => 0);
		is($changed->level(), $TRACE, 'new values given: level');
		is($changed->verbose(), 0, 'new values given: verbose');
		is(state_of($changed), $state, "still a copy in $state");

		show_state('original', $logger);
		show_state('copy', $copy);

		# The two are separate from now on
		printed { $copy->warn('copy only') };
		is_deeply(snapshot($logger), $before, 'logging to the copy does not change the original');
		$logger->clear();
		is($copy->count(), scalar(@{$before->{'messages'}}) + 1, 'clearing the original does not change the copy');
	};
}

# ===========================================================================
# End
# ===========================================================================

foreach my $state ($EMPTY, $CAPTURING) {
	subtest "State: $state -> Trigger: last reference goes -> State: DESTROYED" => sub {
		my $logger;
		printed { $logger = ($state eq $EMPTY) ? fresh(diag => 'all', verbose => 1) : capturing(diag => 'all', verbose => 1) };
		my $watch = $logger;
		weaken($watch);

		# DESTROY must not reach AUTOLOAD, which would store and print
		my $record = spy "${CLASS}::_record";
		my $emit = spy "${CLASS}::_emit";
		my $out = printed { undef $logger };
		my @recorded = $record->();
		my @emitted = $emit->();
		restore_all();

		ok(!defined($watch), 'destroyed');
		is($out, '', 'nothing printed');
		is(scalar(@recorded) + scalar(@emitted), 0, 'nothing stored or printed on the way');
	};
}

# ===========================================================================
# Diagram compliance: the POD, the diagram and the code must agree
# ===========================================================================

# The text of one =head1 section of the module's POD
sub pod_section {
	my $title = shift;

	open(my $fh, '<', $MODULE_FILE) or die "$MODULE_FILE: $!";
	my $text = do { local $/; <$fh> };
	close($fh);
	my ($section) = ($text =~ /^=head1 \Q$title\E\n(.*?)^=head1 /ms);
	die "no '$title' section in $MODULE_FILE" if(!defined($section));
	return $section;
}

# Every method the POD documents, as [ [names of one =head2], ... ]
sub documented_methods {
	return map { [ split /,\s*/ ] }
		map { /^=head2 (\S.*)$/mg } (pod_section('METHODS'), pod_section('METHODS FOR SUBCLASSES'));
}

subtest 'Diagram compliance: the states in the diagram are the ones tested' => sub {
	my $diagram = pod_section('STATE DIAGRAM');
	my %boxes = map { $_ => 1 } ($diagram =~ /^\s*\|\s+([A-Z]+)\s+\|\s*(?:<|-|$)/mg);
	is_deeply([ sort keys %boxes ], [ sort($EMPTY, $CAPTURING) ], 'two states, EMPTY and CAPTURING');
};

subtest 'Diagram compliance: every documented method has a place in the diagram' => sub {
	my $diagram = pod_section('STATE DIAGRAM');
	foreach my $group (documented_methods()) {
		my ($first, $last) = ($group->[0], $group->[-1]);
		# A group may be written as a range, e.g. "trace() ... emergency()"
		my $ranged = (@{$group} > 1) && ($diagram =~ /(?<!\w)\Q$first\E\W*\.\.\.\s*\Q$last\E(?!\w)/);
		foreach my $name (@{$group}) {
			ok($ranged || ($diagram =~ /(?<!\w)\Q$name\E(?!\w)/), "$name: in the diagram")
				or diag("TODO: FSM Discrepancy - $name is documented but has no edge in the STATE DIAGRAM");
			ok(exists($ROLE{$name}), "$name: has a role in this file")
				or diag("TODO: FSM Discrepancy - $name is documented, but no transition for it is tested");
		}
	}
	# DESTROY has no =head2 of its own: the diagram is where it is documented
	my %documented = map { $_ => 1 } (map { @{$_} } documented_methods()), ($diagram =~ /(?<![\w:])([A-Za-z_]\w*)\(/g);
	foreach my $name (sort keys %ROLE) {
		ok($documented{$name}, "$name: tested, and documented")
			or diag("TODO: FSM Discrepancy - $name is tested here but no longer documented");
	}
};

subtest 'Diagram compliance: every call in the diagram exists, except the misspelling' => sub {
	my %called = map { $_ => 1 } (pod_section('STATE DIAGRAM') =~ /(?<![\w:])([A-Za-z_]\w*)\(/g);
	ok(delete($called{$UNKNOWN}), "the diagram's unknown method is '$UNKNOWN'");
	ok(!$CLASS->can($UNKNOWN), "... and it really is unknown");
	foreach my $name (sort keys %called) {
		ok($CLASS->can($name), "$name(): a real method")
			or diag("TODO: FSM Discrepancy - the diagram calls $name(), which the code does not have");
	}
};

subtest 'Diagram compliance: no temporal transitions exist to be tested' => sub {
	# The diagram has no timeout, expiry or TTL edge.  If the code ever read
	# the clock, that would be a transition the diagram does not show
	my $code = do {
		open(my $fh, '<', $MODULE_FILE) or die "$MODULE_FILE: $!";
		local $/;
		my $text = <$fh>;
		close($fh);
		$text =~ s/^=\w+.*?^=cut\n//msg;	# the POD may talk about time
		$text =~ s/#.*$//mg;	# so may comments
		$text;
	};
	unlike($code, qr/\b(?:time|localtime|gmtime|sleep|alarm|Time::\w+)\b/, 'the code never reads the clock')
		or diag('TODO: FSM Discrepancy - the code reads the clock, but the STATE DIAGRAM has no temporal edge');
};

# ===========================================================================
# Every documented method, from both states, by its role
# ===========================================================================

foreach my $state ($EMPTY, $CAPTURING) {
	subtest "State: $state -> Trigger: each documented method -> the state its role says" => sub {
		# Which assertions pass in this state, with the arguments used below
		my %passes = ($EMPTY => { unlike => 1, empty => 1 }, $CAPTURING => { like => 1, has_level => 1 });
		my %args = (
			like => [qr/\Q$MESSAGE\E/], unlike => [qr/\Q$MESSAGE\E/], has_level => ['info'],
			i18n => ['no_method', { method => $UNKNOWN }], _emit => [$MESSAGE], count => ['info'],
		);
		foreach my $name (sort map { @{$_} } documented_methods()) {
			my $role = $ROLE{$name};
			next if(!defined($role));	# reported by the compliance subtest
			my $logger = ($state eq $EMPTY) ? fresh(diag => 'none') : capturing();
			my $before = snapshot($logger);
			my $results = results();
			my ($returned, $out);

			if($role eq 'assert') {
				if($passes{$state}{$name}) {
					$out = printed { $returned = $logger->$name(@{$args{$name} || []}) };
					ok($returned, "$name: passes in $state");
				} else {
					($returned, $out) = failing(sub { $logger->$name(@{$args{$name} || []}) });
					ok(!$returned, "$name: fails in $state");
				}
				is(results(), $results + 2, "$name: one TAP result (plus this file's own)");
				is_deeply(snapshot($logger), $before, "$name: still $state, nothing changed");
				next;
			}

			my $method = ($name eq 'AUTOLOAD') ? $UNKNOWN : $name;
			$out = printed { $returned = $logger->$method(@{$args{$name} || ($role eq 'store' ? [$MESSAGE] : [])}) };
			is(results(), $results, "$name: no TAP result");
			if($role eq 'store') {
				is(state_of($logger), $CAPTURING, "$name: $state -> CAPTURING");
				is($logger->count(), scalar(@{$before->{'messages'}}) + 1, "$name: one more message");
				is_deeply($logger->messages()->[-1], { level => $method, message => $MESSAGE }, "$name: the one logged");
			} elsif($role eq 'clear') {
				is(state_of($logger), $EMPTY, "$name: $state -> EMPTY");
			} elsif($role eq 'copy') {
				is(state_of($returned), $state, "$name: the copy is in $state");
				isnt($returned, $logger, "$name: a different logger");
				is_deeply(snapshot($logger), $before, "$name: the original is unchanged");
			} else {
				# setting (read back: no argument), read, print, end
				is_deeply(snapshot($logger), $before, "$name ($role): still $state, nothing changed");
				is($out, $role eq 'print' ? "# $MESSAGE\n" : '', "$name ($role): " . ($role eq 'print' ? 'prints' : 'prints nothing'));
			}
		}
	};
}

# ===========================================================================
# Failure part-way through a transition
# ===========================================================================

{
	package Local::BrokenPrinter;	## no critic (ProhibitMultiplePackages)
	use parent -norequire, 'Test::Log::Abstraction';
	our $BROKEN = "printer broke\n";
	sub _emit { die $BROKEN }	## no critic (RequireFinalReturn)
}

foreach my $state ($EMPTY, $CAPTURING) {
	subtest "State: $state -> Trigger: level method whose print dies -> State: $CAPTURING, kept" => sub {
		# The diagram's order is "store the message; print it".  A subclass
		# _emit that dies is the subclass's error, and reaches the code that
		# logged; but the message was already stored, so the capture is
		# whole: one entry, not none and not two
		my $logger = Local::BrokenPrinter->new(diag => 'all', verbose => 0);
		eval { $logger->info($MESSAGE) } if($state eq $CAPTURING);
		my $before = $logger->count();
		throws_ok { $logger->error('broken') } qr/\A\Q$Local::BrokenPrinter::BROKEN\E\z/, 'the error reaches the caller';
		is(state_of($logger), $CAPTURING, "$state -> CAPTURING");
		is($logger->count(), $before + 1, 'stored exactly once');
		is_deeply($logger->messages()->[-1], { level => 'error', message => 'broken' }, 'the message as logged');
		# And the logger is still usable: the next call behaves the same
		throws_ok { $logger->error('again') } qr/printer broke/, 'the next call: the same';
		is($logger->count(), $before + 2, 'and is stored too');
	};
}

subtest "State: $EMPTY -> Trigger: a message that logs while it is read -> State: $CAPTURING (+2)" => sub {
	# A re-entrant transition: turning the message into text logs to the
	# same logger.  The inner call completes first, so both are stored,
	# inner first, and count() and messages() still agree
	my $logger = fresh(diag => 'none');
	my $calls = 0;
	my $message = Local::Reentrant->new(sub { $calls++; $logger->info($INNER); return $MESSAGE });
	$logger->warn($message);
	is(state_of($logger), $CAPTURING, 'now CAPTURING');
	is_deeply([ map { "$_->{level}:$_->{message}" } @{$logger->messages()} ], ["info:$INNER", "warn:$MESSAGE"], 'both stored, inner first');
	is($calls, 1, 'the message was read once');
};

{
	package Local::Reentrant;	## no critic (ProhibitMultiplePackages)
	use overload '""' => sub { $_[0]->{'code'}->() }, fallback => 1;
	sub new { my ($class, $code) = @_; return bless { code => $code }, $class }
}

# ===========================================================================
# Time
# ===========================================================================

foreach my $state ($EMPTY, $CAPTURING) {
	subtest "State: $state -> Trigger: a decade passes -> State: $state" => sub {
		# No edge leaves a state because time passed: there is no expiry and
		# no timeout.  The clock is frozen and warped forward instead of
		# sleeping, and the stored entries carry no time to go stale
		Test::Mockingbird::TimeTravel::with_frozen_time($EPOCH => sub {
			my $logger = ($state eq $EMPTY) ? fresh(diag => 'none') : capturing();
			my $before = snapshot($logger);
			Test::Mockingbird::TimeTravel::advance_time($DECADE, 'days');
			is_deeply(snapshot($logger), $before, "still $state, nothing expired");
			$logger->info($INNER);
			is_deeply([ sort keys %{$logger->messages()->[-1]} ], [qw(level message)], 'an entry has no time stamp');
			ok($logger->like(qr/\Q$INNER\E/), 'and assertions still see it');
		});
	};
}

done_testing();
