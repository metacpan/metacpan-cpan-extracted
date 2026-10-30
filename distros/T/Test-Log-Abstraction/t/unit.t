#!/usr/bin/env perl

# Black-box tests of the public API of Test::Log::Abstraction, written from
# its POD alone.  Every message and every return state that the POD
# documents is listed in %ledger below; each subtest removes the entries it
# proves, and the file ends by failing if any are left.  So a documented
# behaviour cannot silently go untested.
#
# The only collaborators outside this module are Test::Builder (where
# output goes) and PerlIO (how it is encoded).  Those are mocked with
# Test::Mockingbird to drive _emit() down each of its documented paths.

use strict;
use warnings;

use lib 't/lib';
use Test::Most;
use Test::Warnings;
use Test::Mockingbird;
use Test::Returns;
use Readonly;
use Errno qw(ENOENT);
use Capture qw(capture_diag);

use Test::Log::Abstraction;

Readonly::Scalar my $CLASS => 'Test::Log::Abstraction';
Readonly::Scalar my $FILE => __FILE__;
Readonly::Scalar my $SENTINEL => 'caller value';
Readonly::Scalar my $ALARM => 300;	# seconds; long enough never to fire

# Windows emulates alarm(), and its alarm(0) always reports 0 seconds left,
# so there the timer can only be checked for not having been replaced
Readonly::Scalar my $CAN_READ_ALARM => ($^O ne 'MSWin32');
Readonly::Scalar my $MAX_LISTED => 20;	# entries a failing assertion lists (POD: like)
Readonly::Scalar my $MAX_SHOWN => 200;	# characters of a repeated value kept (POD: DIAGNOSTICS)
Readonly::Scalar my $CUT_MARK => '...';	# what follows a value that was cut
Readonly::Scalar my $SHOW_STATE => $ENV{'TEST_VERBOSE'};

# Every documented level name and its number, from "Levels and how serious
# they are"
Readonly::Hash my %LEVEL => (
	emergency => 0, emerg => 0, panic => 0,
	alert => 1,
	critical => 2, crit => 2, fatal => 2,
	error => 3, err => 3,
	warning => 4, warn => 4,
	notice => 5,
	info => 6, informational => 6,
	debug => 7, trace => 7,
);
Readonly::Array my @PREDICATES => qw(trace debug info notice warn error critical alert emergency);
Readonly::Array my @LANGUAGES => qw(en de fr zh);

# The documented messages (MESSAGES tables) and return states (Returns
# sections).  Keys are "method: what"; values say where the POD documents it
my %ledger = (
	'new: object' => 'Returns',
	'new: clone' => 'Three ways to call it',
	'new: function form' => 'Three ways to call it',
	q{new: invalid diag level 'X'} => 'MESSAGES',
	'new: diag must be a level name' => 'MESSAGES',
	q{new: invalid syslog level 'X'} => 'MESSAGES',
	'new: invalid argument' => 'MESSAGES',

	'level methods: logger' => 'Returns',
	'level methods: must be called on an object' => 'MESSAGES',

	'is_*: 1' => 'Returns',
	'is_*: 0' => 'Returns',
	'is_*: must be called on an object' => 'MESSAGES',

	'AUTOLOAD: logger' => 'Returns',
	q{AUTOLOAD: no method 'X'} => 'MESSAGES',
	'AUTOLOAD: must be called on an object' => 'MESSAGES',

	'messages: copy' => 'Returns',
	'messages: must be called on an object' => 'MESSAGES',
	'clear: logger' => 'Returns',
	'clear: must be called on an object' => 'MESSAGES',
	'count: number' => 'Returns',
	'count: must be called on an object' => 'MESSAGES',
	'count: invalid argument' => 'MESSAGES',

	'like: true' => 'Returns',
	'like: false' => 'Returns',
	'like: needs a pattern' => 'MESSAGES',
	'like: invalid argument' => 'MESSAGES',
	'like: N messages were captured' => 'MESSAGES',
	'like: at most 20, then a count of the others' => 'Side Effects',
	'like: must be called on an object' => 'MESSAGES',

	'unlike: true' => 'Returns',
	'unlike: false' => 'Returns',
	'unlike: needs a pattern' => 'MESSAGES',
	'unlike: invalid argument' => 'MESSAGES',
	'unlike: N messages matched' => 'MESSAGES',
	'unlike: must be called on an object' => 'MESSAGES',

	'has_level: true' => 'Returns',
	'has_level: false' => 'Returns',
	'has_level: needs a level name' => 'MESSAGES',
	'has_level: invalid argument' => 'MESSAGES',
	'has_level: N messages were captured' => 'MESSAGES',
	'has_level: must be called on an object' => 'MESSAGES',

	'empty: true' => 'Returns',
	'empty: false' => 'Returns',
	'empty: N messages were captured' => 'MESSAGES',
	'empty: must be called on an object' => 'MESSAGES',

	'verbose: 1' => 'Returns',
	'verbose: 0' => 'Returns',
	'verbose: must be called on an object' => 'MESSAGES',

	'level: number' => 'Returns',
	'level: logger' => 'Returns',
	'level: undef' => 'Returns',
	q{level: invalid syslog level 'X'} => 'MESSAGES',
	'level: must be called on an object' => 'MESSAGES',

	'flush: logger' => 'Returns',
	'flush: must be called on an object' => 'MESSAGES',
	'reopen: logger' => 'Returns',
	'reopen: must be called on an object' => 'MESSAGES',
	'lang: code' => 'Returns',
	'lang: must be called on an object' => 'MESSAGES',

	'_emit: logger' => 'Returns',
	'i18n: string' => 'Returns',
	'i18n: key when not found' => 'Where the template is found',
	'i18n: a value the format cannot show is written as given' => 'How a message template works',
	'i18n: never fails, for any key or arguments' => 'MESSAGES',
	'count: unknown names give 0' => 'API SPECIFICATION',
	'level methods: an object whose text form dies is written in plain form' => 'Args',

	'DIAGNOSTICS: a repeated value is cut to 200 characters' => 'DIAGNOSTICS',
	'DIAGNOSTICS: control characters are shown as \\xNN' => 'DIAGNOSTICS',
	'DIAGNOSTICS: an object whose text form dies is shown in plain form' => 'DIAGNOSTICS',
);

# Mark a documented state as proven.  A name that is not in the ledger is
# itself a failure, so a typo here cannot hide an untested state
sub proven {
	my $state = shift;

	fail("ledger has no entry '$state'") if(!exists($ledger{$state}));
	delete $ledger{$state};
	return;
}

# A logger that prints nothing and ignores prove -v
sub logger {
	return $CLASS->new(diag => 'none', verbose => 0, @_);
}

# The exact text of an error or warning raised from this file
sub at_caller {
	my ($text, $class) = @_;

	$class = $CLASS if(!defined($class));
	return qr/\A\Q$class: $text\E at \Q$FILE\E line \d+\.?\n?\z/;
}

# Show a value, only when asked to
sub state_diag {
	my ($label, $value) = @_;

	diag(explain({ $label => $value })) if($SHOW_STATE);
	return;
}

# What code printed through diag(), without the indentation that
# Test::Builder adds inside a subtest, so it can be compared exactly
sub printed(&) {
	my $code = shift;

	(my $out = capture_diag(\&{$code})) =~ s/^[ ]+#/#/mg;
	return $out;
}

# Run a failing assertion as a TODO test, so that it does not fail this
# file, and return its result and everything it printed
sub failing {
	my $code = shift;

	my $tb = Test::Builder->new();
	my $result;
	$tb->todo_start('expected to fail: checking its output');
	my $out = printed { $result = $code->() };
	$tb->todo_end();
	state_diag(output => $out);
	return ($result, $out);
}

# Run code with known values in $@, $!, $_ and a running alarm(), and check
# that it leaves all of them as they were (POD: Global variables are left
# alone)
sub leaves_globals_alone {
	my ($name, $code) = @_;

	my $timer = alarm($ALARM);
	my $handler = sub { fail("$name: alarm fired") };
	local $SIG{'ALRM'} = $handler;
	local $_ = $SENTINEL;
	$@ = $SENTINEL;
	$! = ENOENT;
	$code->();
	my ($error, $errno, $topic) = ($@, $! + 0, $_);
	my $handler_after = $SIG{'ALRM'};
	my $left = alarm(0);

	is($error, $SENTINEL, "$name: \$@ untouched");
	is($errno, ENOENT, "$name: \$! untouched");
	is($topic, $SENTINEL, "$name: \$_ untouched");
	is($handler_after, $handler, "$name: alarm() handler untouched");
	SKIP: {
		skip('alarm(0) cannot report the time left on this platform', 1) if(!$CAN_READ_ALARM);
		ok(($left > 0) && ($left <= $ALARM), "$name: alarm() timer still running ($left s left)");
	}
	return;
}

# A subclass, so that the methods for subclasses can be used as the POD intends
{
	package Local::Subclass;
	our @ISA = ('Test::Log::Abstraction');
	sub say { my $self = shift; return $self->i18n(@_) }
	sub print_line { my $self = shift; return $self->_emit(@_) }

	package Local::Other;
	sub new { return bless {}, shift }

	# An object whose text form dies, as a badly written exception class may
	package Local::Bomb;
	use overload '""' => sub { die "kaboom\n" }, fallback => 1;
}

# ---------------------------------------------------------------------------
# new
# ---------------------------------------------------------------------------

# Strategy: one logger per documented option, checked only through public
# methods, then each documented error
subtest 'new: options as documented' => sub {
	my $logger = $CLASS->new();
	isa_ok($logger, $CLASS);
	returns_ok($logger, { type => 'object', isa => $CLASS }, 'returns a logger');
	proven('new: object');

	isa_ok($CLASS->new({ diag => 'none' }), $CLASS, 'hash reference form');
	isa_ok(Test::Log::Abstraction::new(diag => 'none'), $CLASS, 'function form');
	proven('new: function form');
	isa_ok($CLASS->new('stray'), $CLASS, 'odd list is ignored');
	isa_ok($CLASS->new(unknown => 1, diag => 'none'), $CLASS, 'other options are ignored');

	is(logger(verbose => 1)->verbose(), 1, 'verbose option');
	is(logger(level => 'warning')->level(), $LEVEL{'warning'}, 'level option');
	is($CLASS->new()->level(), $LEVEL{'trace'}, "level defaults to 'trace'");
	is(logger(lang => 'de')->lang(), 'de', 'lang option');
	is(logger(lang => 'de_DE.UTF-8')->lang(), 'de', 'lang option as a locale name');
	is(logger(country => 'fr')->lang(), 'fr', 'country option, lower case');
	is($CLASS->new()->lang(), 'en', 'English by default');
	{
		local $ENV{'LC_ALL'} = 'zh_CN.UTF-8';
		is(logger(lang => 'auto')->lang(), 'zh', "lang => 'auto' reads the environment");
		is(logger()->lang(), 'en', '... but only when asked');
	}
};

subtest 'new: verbose from the environment' => sub {
	foreach my $case ([0, 0, 0], [1, 0, 1], [0, 1, 1]) {
		my ($test_verbose, $verbose, $want) = @{$case};
		local $ENV{'TEST_VERBOSE'} = $test_verbose;
		local $ENV{'VERBOSE'} = $verbose;
		is($CLASS->new(diag => 'none')->verbose(), $want, "TEST_VERBOSE=$test_verbose VERBOSE=$verbose");
	}
	local $ENV{'TEST_VERBOSE'} = 1;
	is($CLASS->new(verbose => 0)->verbose(), 0, 'an explicit option beats the environment');
	is($CLASS->new(verbose => undef)->verbose(), 0, 'verbose => undef is off (COMMON PITFALLS)');
};

subtest 'new: clone' => sub {
	my $original = logger();
	$original->info('kept', { user => 'alice' });
	$original->verbose(1);
	$original->level('error');

	my $clone = $original->new(lang => 'fr', verbose => 0);
	proven('new: clone');
	isa_ok($clone, $CLASS);
	isnt($clone, $original, 'a different object');
	is($clone->count(), 1, 'copy of the stored messages');
	is($original->new()->verbose(), 1, 'same verbose setting, unless an option replaces it');
	is($clone->level(), $LEVEL{'error'}, 'same level');
	is($clone->lang(), 'fr', 'the new option applies');
	is($original->lang(), 'en', 'the original is not changed');

	$clone->info('only in the clone');
	is($original->count(), 1, 'the two capture separately');
};

subtest 'new: documented errors, exactly' => sub {
	throws_ok { $CLASS->new(diag => 'bogus') } at_caller(q{invalid diag level 'bogus'}), 'unknown diag level';
	throws_ok { $CLASS->new(diag => ['info', 'bogus']) } at_caller(q{invalid diag level 'bogus'}), 'unknown level in a list';
	proven(q{new: invalid diag level 'X'});

	my $type = 'diag must be a level name, "all", "none" or an array reference of level names';
	throws_ok { $CLASS->new(diag => {}) } at_caller($type), 'hash as diag';
	throws_ok { $CLASS->new(diag => sub { 1 }) } at_caller($type), 'code as diag';
	proven('new: diag must be a level name');

	throws_ok { $CLASS->new(level => 'loud') } at_caller(q{invalid syslog level 'loud'}), 'unknown level option';
	proven(q{new: invalid syslog level 'X'});

	throws_ok { $CLASS->new(country => 'GBR') } qr/\A\Q$CLASS: invalid argument: \E.*country.* at \Q$FILE\E line \d+/, 'country with three letters';
	throws_ok { $CLASS->new(lang => '!!') } qr/\A\Q$CLASS: invalid argument: \E.*lang/, 'lang with the wrong format';
	throws_ok { $CLASS->new(i18n => 'x') } qr/\A\Q$CLASS: invalid argument: \E.*i18n/, 'i18n that is not a hash';
	proven('new: invalid argument');

	lives_ok { $CLASS->new(diag => 'ALL') } "'ALL': upper or lower case does not matter";
};

# ---------------------------------------------------------------------------
# Level methods and is_*
# ---------------------------------------------------------------------------

# Strategy: every documented level name; check what is stored and what is
# returned, using only messages() and count()
subtest 'level methods: store and return the logger' => sub {
	my $logger = logger();
	foreach my $level (sort keys %LEVEL) {
		is($logger->$level("text for $level"), $logger, "$level returns the logger");
	}
	proven('level methods: logger');
	is($logger->count(), scalar(keys %LEVEL), 'one message each');
	is_deeply([sort map { $_->{'level'} } @{$logger->messages()}], [sort keys %LEVEL], 'stored under the name called');
	is($logger->clear()->info('a')->debug('b')->count(), 2, 'calls chain');
};

subtest 'level methods: the documented argument rules' => sub {
	my $logger = logger();
	my $loop = { name => 'loop' };
	$loop->{'self'} = $loop;
	my @rows = (
		[['file ', 'x', ' is empty'], 'file x is empty', undef, 'values joined with nothing between them'],
		[["line\n"], 'line', undef, 'one newline at the end removed'],
		[[['part 1, ', 'part 2']], 'part 1, part 2', undef, 'a lone array reference is the parts'],
		[['started', { pid => 1 }], 'started', { pid => 1 }, 'trailing hash is fields'],
		[['started', {}], 'started', undef, 'an empty fields hash is dropped'],
		[[{ b => 2, a => 1 }], '{a => 1, b => 2}', undef, 'a lone hash is the message, keys sorted'],
		[['v: ', [1, [2]]], 'v: [1, [2]]', undef, 'an array is written as [a, b]'],
		[[undef], 'undef', undef, 'undef is the text undef'],
		[[$loop], '{name => loop, self => (cycle)}', undef, 'a structure that contains itself'],
	);
	foreach my $row (@rows) {
		my ($args, $message, $fields, $name) = @{$row};
		$logger->clear()->info(@{$args});
		my $entry = $logger->messages()->[0];
		is($entry->{'message'}, $message, $name);
		is_deeply($entry->{'fields'}, $fields, "$name: fields") if(defined($fields));
		ok(!exists($entry->{'fields'}), "$name: no fields") if(!defined($fields));
	}
	delete $loop->{'self'};
};

subtest 'level methods: refuse anything that is not a logger' => sub {
	foreach my $level (sort keys %LEVEL) {
		throws_ok { $CLASS->$level('x') } at_caller("$level() must be called on an object, not on the class"), "$level on the class";
	}
	no strict 'refs';
	throws_ok { &{"${CLASS}::warn"}(undef, 'x') } at_caller('warn() must be called on an object, not on the class'), 'on undef';
	throws_ok { &{"${CLASS}::warn"}(Local::Other->new(), 'x') } at_caller('warn() must be called on an object, not on the class'), 'on another class';
	proven('level methods: must be called on an object');
};

subtest 'is_*: on and off by level' => sub {
	my $logger = logger();
	foreach my $method (map { "is_$_" } @PREDICATES) {
		is($logger->$method(), 1, "$method is 1 at the default level");
	}
	$logger->level('warning');
	my %want = (trace => 0, debug => 0, info => 0, notice => 0, warn => 1, error => 1, critical => 1, alert => 1, emergency => 1);
	foreach my $level (@PREDICATES) {
		my $method = "is_$level";
		is($logger->$method(), $want{$level}, "$method at level warning");
		returns_ok($logger->$method(), { type => 'boolean' }, "$method returns a boolean");
	}
	proven('is_*: 1');
	proven('is_*: 0');

	foreach my $method (map { "is_$_" } @PREDICATES) {
		throws_ok { $CLASS->$method() } at_caller("$method() must be called on an object, not on the class"), "$method on the class";
	}
	proven('is_*: must be called on an object');
};

# ---------------------------------------------------------------------------
# AUTOLOAD
# ---------------------------------------------------------------------------

subtest 'AUTOLOAD: a misspelt method is stored and announced' => sub {
	my $logger = logger();
	my $result;
	my $out = printed { $result = $logger->wran('oops') };
	is($result, $logger, 'returns the logger');
	proven('AUTOLOAD: logger');
	is($out, "# $CLASS: no method 'wran'\n", 'notice printed, even with diag => none');
	proven(q{AUTOLOAD: no method 'X'});
	is($logger->count('wran'), 1, 'stored under the misspelt name');
	is($logger->messages()->[0]->{'message'}, 'oops', 'with its message');

	throws_ok { $CLASS->wran('x') } at_caller('wran() must be called on an object, not on the class'), 'on the class';
	proven('AUTOLOAD: must be called on an object');
};

# ---------------------------------------------------------------------------
# messages, clear, count, verbose, level, flush, lang
# ---------------------------------------------------------------------------

subtest 'messages: a new copy, oldest first' => sub {
	my $logger = logger();
	$logger->warn('first');
	$logger->info('second', { k => 'v' });
	my $messages = $logger->messages();
	returns_ok($messages, { type => 'arrayref' }, 'array reference');
	is_deeply($messages, [{ level => 'warn', message => 'first' }, { level => 'info', message => 'second', fields => { k => 'v' } }], 'documented keys, oldest first');
	@{$messages} = ();
	is($logger->count(), 2, 'changing the copy does not change the logger');
	proven('messages: copy');
};

subtest 'clear: empties, keeps settings' => sub {
	my $logger = logger(level => 'error', lang => 'de', verbose => 1);
	capture_diag { $logger->info('x') };
	is($logger->clear(), $logger, 'returns the logger');
	proven('clear: logger');
	is($logger->count(), 0, 'no messages');
	is($logger->level(), $LEVEL{'error'}, 'level kept');
	is($logger->lang(), 'de', 'language kept');
	is($logger->verbose(), 1, 'verbose kept');
};

subtest 'count: total and per level' => sub {
	my $logger = logger();
	$logger->warn('a');
	$logger->warning('b');
	$logger->error('c');
	is($logger->count(), 3, 'total');
	is($logger->count('WARN'), 1, 'one level, case-insensitive');
	is($logger->count('warning'), 1, 'other names for a level are counted apart');
	is($logger->count('alert'), 0, 'a level never used');
	is($logger->count(undef), 3, 'count(undef) counts all (COMMON PITFALLS)');
	returns_ok($logger->count(), { type => 'integer', min => 0 }, 'an integer, 0 or more');
	proven('count: number');

	throws_ok { $logger->count([]) } at_caller(q{invalid argument: Parameter 'level' must be a string}), 'level that is not a string';
	proven('count: invalid argument');
};

subtest 'verbose: get and set' => sub {
	my $logger = logger();
	is($logger->verbose(), 0, 'off');
	proven('verbose: 0');
	is($logger->verbose(1), 1, 'turned on');
	proven('verbose: 1');
	is($logger->verbose(), 1, 'stays on');
	is($logger->verbose(0), 0, 'turned off');

	my $out = printed { $logger->verbose(1); $logger->trace('now printed') };
	is($out, "# now printed\n", 'verbose prints every message');
};

subtest 'level: get, set, reject' => sub {
	my $logger = logger();
	is($logger->level(), $LEVEL{'trace'}, 'number, 0 to 7');
	returns_ok($logger->level(), { type => 'integer', min => 0, max => 7 }, 'in range');
	proven('level: number');

	is($logger->level('Error'), $logger, 'a known name returns the logger');
	is($logger->level(), $LEVEL{'error'}, '... and sets the level, any case');
	proven('level: logger');

	my $result = 'unset';
	warning_like { $result = $logger->level('loud') } at_caller(q{invalid syslog level 'loud'}), 'an unknown name warns, exactly';
	proven(q{level: invalid syslog level 'X'});
	is($result, undef, '... and returns undef');
	proven('level: undef');
	is($logger->level(), $LEVEL{'error'}, '... and changes nothing');
};

subtest 'flush and lang' => sub {
	my $logger = logger(country => 'CN');
	is($logger->flush(), $logger, 'flush returns the logger');
	is($logger->count(), 0, 'flush stores nothing');
	proven('flush: logger');
	is($logger->reopen(), $logger, 'reopen returns the logger');
	is($logger->count(), 0, 'reopen stores nothing');
	proven('reopen: logger');

	is($logger->lang(), 'zh', 'lang returns the code');
	returns_ok($logger->lang(), { type => 'string', matches => qr/\A[a-z]{2,3}\z/ }, 'a language code');
	is(logger(lang => 'xx', i18n => { xx => {} })->lang(), 'xx', 'a code given in the i18n option');
	proven('lang: code');
};

subtest 'every inspection method refuses anything that is not a logger' => sub {
	my %not_loggers = ('the class' => $CLASS, 'undef' => undef, 'a plain hash' => {}, 'another class' => Local::Other->new());
	foreach my $method (qw(messages clear count verbose level flush reopen lang like unlike has_level empty)) {
		foreach my $what (sort keys %not_loggers) {
			no strict 'refs';
			throws_ok { &{"${CLASS}::$method"}($not_loggers{$what}, 'x') } at_caller("$method() must be called on an object, not on the class"), "$method on $what";
		}
		proven("$method: must be called on an object");
	}
};

# ---------------------------------------------------------------------------
# like, unlike, has_level, empty
# ---------------------------------------------------------------------------

# Strategy: passing calls are ordinary tests in this file; failing calls run
# as TODO tests, and what they print is compared line by line with the
# MESSAGES tables
subtest 'like: pass and fail' => sub {
	my $logger = logger();
	$logger->warn('the widget broke');
	$logger->info('second');

	ok($logger->like(qr/widget/, 'like passes on a match'), 'returns true');
	ok($logger->like('wid.et', 'a string is a regular expression'), 'string pattern');
	proven('like: true');

	my ($result, $out) = failing(sub { $logger->like(qr/updated/, 'no match') });
	ok(!$result, 'returns false');
	proven('like: false');
	like($out, qr/^# \Q$CLASS: 2 messages were captured:\E\n# \Q    [warn] the widget broke\E\n# \Q    [info] second\E\n/m, 'stored messages listed under it');
	proven('like: N messages were captured');
};

subtest 'like: at most 20 listed, then a count of the others' => sub {
	my $logger = logger();
	my $extra = 3;
	$logger->info("line $_") foreach 1 .. $MAX_LISTED + $extra;
	my (undef, $out) = failing(sub { $logger->like(qr/absent/) });
	my @listed = ($out =~ /^#     \[info\] line \d+$/mg);
	is(scalar(@listed), $MAX_LISTED, "$MAX_LISTED entries listed");
	like($out, qr/^#     \Q... and $extra more\E$/m, 'then a count of the others');
	proven('like: at most 20, then a count of the others');

	my $one = logger();
	$one->info('only');
	(undef, $out) = failing(sub { $one->like(qr/absent/) });
	like($out, qr/^# \Q$CLASS: 1 message was captured:\E$/m, 'singular form');
	my $none = logger();
	(undef, $out) = failing(sub { $none->like(qr/absent/) });
	like($out, qr/^# \Q$CLASS: no messages were captured\E$/m, 'zero form');
};

subtest 'unlike: pass and fail' => sub {
	my $logger = logger();
	ok(logger()->unlike(qr/x/, 'no messages at all'), 'passes with no messages');
	$logger->warn('fatal: disk');
	$logger->info('fine');
	ok($logger->unlike(qr/nothing/, 'no match'), 'returns true');
	proven('unlike: true');

	my ($result, $out) = failing(sub { $logger->unlike(qr/fatal/, 'match') });
	ok(!$result, 'returns false');
	proven('unlike: false');
	like($out, qr/^# \Q$CLASS: 1 message matched:\E\n# \Q    [warn] fatal: disk\E\n/m, 'only the matching message listed');
	unlike($out, qr/fine/, 'the other message is not listed');
	$logger->error('fatal: cpu');
	(undef, $out) = failing(sub { $logger->unlike(qr/fatal/) });
	like($out, qr/^# \Q$CLASS: 2 messages matched:\E$/m, 'plural form');
	proven('unlike: N messages matched');
};

subtest 'has_level: pass and fail' => sub {
	my $logger = logger();
	$logger->error('boom');
	ok($logger->has_level('ERROR', 'any case'), 'returns true');
	proven('has_level: true');

	my ($result, $out) = failing(sub { $logger->has_level('warn') });
	ok(!$result, 'returns false');
	proven('has_level: false');
	like($out, qr/^# \Q$CLASS: 1 message was captured:\E\n# \Q    [error] boom\E\n/m, 'stored messages listed, with levels');
	proven('has_level: N messages were captured');
};

subtest 'empty: pass and fail' => sub {
	my $logger = logger();
	ok($logger->empty('nothing yet'), 'returns true');
	proven('empty: true');
	$logger->notice('something');
	my ($result, $out) = failing(sub { $logger->empty('not empty') });
	ok(!$result, 'returns false');
	proven('empty: false');
	like($out, qr/^# \Q$CLASS: 1 message was captured:\E\n# \Q    [notice] something\E\n/m, 'stored messages listed');
	proven('empty: N messages were captured');
};

subtest 'like, unlike, has_level: documented errors, exactly' => sub {
	my $logger = logger();
	$logger->info('x');
	foreach my $method (qw(like unlike)) {
		throws_ok { $logger->$method() } at_caller("$method() needs a pattern"), "$method with no pattern";
		throws_ok { $logger->$method(undef, 'name') } at_caller("$method() needs a pattern"), "$method with undef";
		proven("$method: needs a pattern");
		throws_ok { $logger->$method([]) } at_caller(q{invalid argument: Parameter 'pattern' must be one of regex, string}), "$method with an array";
		throws_ok { $logger->$method('(') } qr/\A\Q$CLASS: invalid argument: Unmatched ( in regex\E/, "$method with a pattern that does not compile";
		throws_ok { $logger->$method('a{2,1}') } qr/\A\Q$CLASS: invalid argument: Quantifier {n,m} with n > m can't match\E/, "$method with a pattern that can never match";
		proven("$method: invalid argument");
	}
	throws_ok { $logger->has_level() } at_caller('has_level() needs a level name'), 'has_level with no level';
	proven('has_level: needs a level name');
	throws_ok { $logger->has_level({}) } at_caller(q{invalid argument: Parameter 'level' must be a string}), 'has_level with a hash';
	proven('has_level: invalid argument');
};

# ---------------------------------------------------------------------------
# Protected methods: _emit and i18n
# ---------------------------------------------------------------------------

# Strategy: the only things _emit depends on are Test::Builder and the
# output handle's layers; mock them to drive each documented path
subtest '_emit: every output path' => sub {
	my $logger = Local::Subclass->new(diag => 'none', verbose => 0);
	my (@printed, @results);
	my $characters = "caf\x{e9} \x{2603}";

	# Collect first and check after restore_all(): with diag() mocked, a
	# failing check could not report itself
	mock 'Test::Builder::diag' => sub { push @printed, $_[1]; return 0 };
	push @results, $logger->print_line('plain');
	push @results, $logger->print_line("bytes \xc3\xa9");
	push @results, $logger->print_line($characters);
	mock 'PerlIO::get_layers' => sub { return ('unix', 'perlio', 'utf8') };
	push @results, $logger->print_line($characters);
	unmock 'PerlIO::get_layers';
	mock 'Test::Builder::in_todo' => sub { 1 };
	my $todo_handle_used = 0;
	mock 'Test::Builder::todo_output' => sub { $todo_handle_used++; return \*STDERR };
	push @results, $logger->print_line('inside todo');
	restore_all();

	is_deeply(\@results, [($logger) x 5], 'always returns the logger');
	proven('_emit: logger');
	is($printed[0], 'plain', 'ASCII as it is');
	is($printed[1], "bytes \xc3\xa9", 'a byte string unchanged');
	is($printed[2], "caf\xc3\xa9 \xe2\x98\x83", 'a character string as UTF-8');
	is($printed[3], $characters, 'not encoded again when the output already encodes');
	is($todo_handle_used, 1, 'inside a TODO test, the TODO output is checked');
	is($printed[4], 'inside todo', '... and the line still printed');
};

subtest 'i18n: from a subclass' => sub {
	my $logger = Local::Subclass->new(diag => 'none', verbose => 0, i18n => { en => {
		count_things => { zero => 'none', one => '%{count}d thing', other => '%{count}d things' },
		greet => { male => 'he', female => 'she', other => 'they' },
	} });
	is($logger->say('needs_pattern', { method => 'like' }), 'Local::Subclass: like() needs a pattern', 'built-in message, class filled in');
	is($logger->say('count_things', { count => 0 }), 'none', 'zero form');
	is($logger->say('count_things', { count => 1 }), '1 thing', 'one form');
	is($logger->say('count_things', { count => 5 }), '5 things', 'other form');
	is($logger->say('greet', { gender => 'female' }), 'she', 'gender form');
	is($logger->say('greet'), 'they', 'other when no gender is given');
	returns_ok($logger->say('greet'), { type => 'string' }, 'a string');
	proven('i18n: string');
	is($logger->say('not_a_key'), 'not_a_key', 'unknown key returned as it is');
	proven('i18n: key when not found');
};

subtest 'i18n: every documented error exists in every language' => sub {
	my %args = (method => 'm', level => 'X', reason => 'r', count => 2);
	foreach my $key (qw(class_invocant invalid_argument invalid_diag_level invalid_diag_type invalid_level needs_level needs_pattern no_method captured matched)) {
		foreach my $lang (@LANGUAGES) {
			my $text = Local::Subclass->new(diag => 'none', lang => $lang)->say($key, \%args);
			ok(length($text) && ($text ne $key) && ($text =~ /\ALocal::Subclass/), "$key in $lang");
		}
	}
};

subtest 'methods for subclasses' => sub {
	lives_ok { Local::Subclass->new(diag => 'none')->say('x') } 'a subclass may call them';
};

# Strategy: the template rules say what happens when a value does not fit
# its format, so feed each kind of misfit through a template of our own
subtest 'i18n: a value the format cannot show is written as it was given' => sub {
	my $logger = logger(i18n => { en => { all => '%{v}d|%{v}x|%{v}.2f' } });
	foreach my $odd ('text', 'Inf', '-Inf', 'NaN') {
		is($logger->i18n('all', { v => $odd }), "$odd|$odd|$odd", "'$odd' in every number format");
	}
	my $big = 1e30;
	is($logger->i18n('all', { v => $big }), "$big|$big|" . sprintf('%.2f', $big), 'too big for %d and %x, but %.2f can show it');
	is($logger->i18n('all', { v => 255 }), '255|ff|255.00', 'a value that fits is formatted');
	is($logger->i18n('all', {}), 'undef|undef|undef', 'a missing value is the text undef');
	proven('i18n: a value the format cannot show is written as given');
};

# Strategy: MESSAGES says "None.  It never fails, for any key or
# arguments" - so try the keys and arguments most likely to make it fail
subtest 'i18n: never fails, for any key or arguments' => sub {
	my $logger = logger();
	my %keys = (
		'undef' => undef,
		'an empty string' => '',
		'an array reference' => [],
		'an object whose text form dies' => bless({}, 'Local::Bomb'),
	);
	foreach my $what (sort keys %keys) {
		my $text;
		lives_ok { $text = $logger->i18n($keys{$what}, 'not a hash') } "key: $what";
		returns_ok($text, { type => 'string' }, '... gives a string');
	}
	lives_ok { $logger->i18n('captured', { count => bless({}, 'Local::Bomb') }) } 'an argument whose text form dies';
	proven('i18n: never fails, for any key or arguments');
};

# Strategy: the Domains line of count()'s API SPECIFICATION, including the
# misspelt level that LIMITATIONS warns about
subtest 'count: unknown names give 0' => sub {
	my $logger = logger();
	$logger->warn('a');
	foreach my $name ('', '0', 'wran', 'WARN ') {
		is($logger->count($name), 0, "count('$name') is 0");
	}
	is($logger->count('warn'), 1, 'while the real level still counts');
	proven('count: unknown names give 0');
};

# Strategy: the level methods' Args promise that an object whose text form
# dies does not stop the log call
subtest 'level methods: an object whose text form dies' => sub {
	my $logger = logger();
	my $bomb = bless({}, 'Local::Bomb');
	lives_ok { $logger->error('got ', $bomb) } 'the log call works';
	like($logger->messages()->[0]->{'message'}, qr/\Agot Local::Bomb=HASH\(0x[0-9a-f]+\)\z/, 'the object is written in plain form');
	proven('level methods: an object whose text form dies is written in plain form');
};

# Strategy: DIAGNOSTICS promises that every value an error, warning or
# notice repeats is cut and escaped.  Send one hostile name to every place
# that repeats a name, and expect exactly the same safe text from each
subtest 'DIAGNOSTICS: every repeated value is cut and escaped' => sub {
	my $hostile = "x\ny\e" . ('z' x $MAX_SHOWN);
	my $prefix = 'x\x0Ay\x1B';
	my $shown = $prefix . ('z' x ($MAX_SHOWN - length($prefix))) . $CUT_MARK;
	my $logger = logger();

	throws_ok { $CLASS->new(diag => $hostile) } at_caller("invalid diag level '$shown'"), 'new(diag => name)';
	throws_ok { $CLASS->new(diag => ['info', $hostile]) } at_caller("invalid diag level '$shown'"), 'new(diag => [names])';
	throws_ok { $CLASS->new(level => $hostile) } at_caller("invalid syslog level '$shown'"), 'new(level => name)';
	warning_like { $logger->level($hostile) } at_caller("invalid syslog level '$shown'"), 'level(name) warning';
	throws_ok { $CLASS->$hostile() } at_caller("$shown() must be called on an object, not on the class"), 'unknown method on the class';
	my $out = printed { $logger->$hostile() };
	is($out, "# $CLASS: no method '$shown'\n", 'the "no method" notice: one line');
	proven('DIAGNOSTICS: a repeated value is cut to 200 characters');
	proven('DIAGNOSTICS: control characters are shown as \\xNN');
};

# Strategy: DIAGNOSTICS promises that an object whose text form dies gives
# this module's message, never the object's own error
subtest 'DIAGNOSTICS: an object whose text form dies is shown in plain form' => sub {
	my $bomb = bless({}, 'Local::Bomb');
	my $plain = qr/Local::Bomb=HASH\(0x[0-9a-f]+\)/;
	throws_ok { $CLASS->new(diag => [$bomb]) } qr/\A\Q$CLASS: invalid diag level '\E$plain' at \Q$FILE\E line \d+/, 'new(diag => [object]) croaks with its own message';
	my $result = 'not called';
	warning_like { $result = logger()->level($bomb) } qr/\A\Q$CLASS: invalid syslog level '\E$plain'/, 'level(object) warns with its own message';
	is($result, undef, '... and returns undef, as for any bad name');
	proven('DIAGNOSTICS: an object whose text form dies is shown in plain form');
};

# ---------------------------------------------------------------------------
# Global state (POD: Global variables are left alone)
# ---------------------------------------------------------------------------

# Strategy: every public method that returns normally, run with known
# values in $@, $!, $_ and a live alarm()
subtest 'no method changes $@, $!, $_ or alarm()' => sub {
	my $logger = logger();
	# In this order: clear and empty must come after the calls that need
	# messages to exist
	my @calls = (
		'new' => sub { $CLASS->new(diag => 'none') },
		'new (clone)' => sub { $logger->new() },
		'info' => sub { $logger->info('x', { k => 1 }) },
		'AUTOLOAD' => sub { capture_diag { $logger->wran('x') } },
		'is_debug' => sub { $logger->is_debug() },
		'messages' => sub { $logger->messages() },
		'count' => sub { $logger->count('info') },
		'like' => sub { $logger->like(qr/x/, 'like inside the globals check') },
		'unlike' => sub { $logger->unlike('zzz', 'unlike inside the globals check') },
		'has_level' => sub { $logger->has_level('info', 'has_level inside the globals check') },
		'verbose' => sub { $logger->verbose(0) },
		'level' => sub { $logger->level('debug') },
		'flush' => sub { $logger->flush() },
		'reopen' => sub { $logger->reopen() },
		'lang' => sub { $logger->lang() },
		'clear' => sub { $logger->clear() },
		'empty' => sub { $logger->empty('empty inside the globals check') },
	);
	while(my ($name, $code) = splice(@calls, 0, 2)) {
		leaves_globals_alone($name, $code);
	}
	leaves_globals_alone('failing like', sub { failing(sub { $logger->like(qr/absent/) }) });
};

# ---------------------------------------------------------------------------
# The ledger
# ---------------------------------------------------------------------------

state_diag(untested => \%ledger);
if(%ledger) {
	fail("documented state not tested: $_ (POD $ledger{$_})") foreach sort keys %ledger;
} else {
	pass('every documented message and return state was tested');
}

done_testing();
