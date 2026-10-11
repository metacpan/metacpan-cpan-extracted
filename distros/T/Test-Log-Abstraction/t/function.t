#!/usr/bin/env perl

# White-box tests of every routine in lib/Test/Log/Abstraction.pm, public
# and private.  Each subtest isolates one routine: its collaborators are
# replaced with Test::Mockingbird mocks or spies, so a failure points at the
# routine under test and not at something it calls.
#
# Most of the tests here are hostile: undefined and wrongly typed input,
# invocants that are not loggers, self-referential and very large data,
# collaborators that die part way through, and global variables that the
# code under test must not disturb.

use strict;
use warnings;

use lib 't/lib';
use Test::Most;
use Test::Warnings;	# any warning at all fails the file
use Test::Mockingbird;
use Test::Returns;
use Test::Memory::Cycle;
use Readonly;
use Scalar::Util qw(weaken);
use Errno qw(ENOENT);
use Capture qw(capture_diag);

use Test::Log::Abstraction;

# Loggers below are made with verbose => 0, so that prove -v does not change
# what they print; this records whether to show the extra diagnostics
Readonly::Scalar my $SHOW_STATE => $ENV{'TEST_VERBOSE'};

Readonly::Scalar my $CLASS => 'Test::Log::Abstraction';
Readonly::Scalar my $FILE => __FILE__;
Readonly::Scalar my $CYCLE => '(cycle)';
Readonly::Scalar my $MAX_EXPLAIN => 20;	# entries listed by a failing assertion
Readonly::Scalar my $MAX_REASON => 200;	# characters kept from another module's error
Readonly::Scalar my $DEEP => 5_000;	# nesting depth for recursion tests
Readonly::Scalar my $WIDE => 10_000;	# element count for size tests
Readonly::Scalar my $HUGE => 1_000_000;	# characters in a very long message
Readonly::Scalar my $SENTINEL => 'sentinel value';

# The level table from the documentation; the module must agree with it
Readonly::Hash my %SEVERITY => (
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

# A logger that prints nothing unless a test asks it to
sub logger {
	return $CLASS->new(diag => 'none', verbose => 0, @_);
}

# The exact text of a croak raised for this file, with nothing after it
sub croaked {
	my $text = shift;

	return qr/\A\Q$CLASS: $text\E at \Q$FILE\E line \d+\.?\n\z/;
}

# Show an internal structure, only when asked to
sub state_diag {
	my ($label, $value) = @_;

	diag(explain({ $label => $value })) if($SHOW_STATE);
	return;
}

# Classes whose objects stringify badly, used to attack _stringify
{
	package Local::Bomb;
	use overload '""' => sub { die "kaboom\n" }, fallback => 1;

	package Local::Undef;
	use overload '""' => sub { return undef }, fallback => 1;

	package Local::Text;
	use overload '""' => sub { 'overloaded text' }, fallback => 1;

	package Local::Sub;
	our @ISA = ('Test::Log::Abstraction');

	package Local::Other;
	sub new { return bless {}, shift }
}

# ===========================================================================
# Construction: new, _args, _build, _clone, _validate, _reason,
# _resolve_lang, _diag_rule
# ===========================================================================

# Strategy: new() only routes to _build or _clone; check each route with
# those mocked, then attack the argument shapes it must survive
subtest 'new: routes each calling form' => sub {
	my @built;
	mock "${CLASS}::_build" => sub { push @built, [@_]; return 'built' };
	mock "${CLASS}::_clone" => sub { return 'cloned' };

	is($CLASS->new(a => 1), 'built', 'class form builds');
	is($built[-1]->[0], $CLASS, '... blessed into the class');
	is_deeply($built[-1]->[1], { a => 1 }, '... with the options');
	is_deeply($built[-1]->[2], [], '... and an empty capture');

	is(Test::Log::Abstraction::new(), 'built', 'function form with no arguments');
	is($built[-1]->[0], $CLASS, '... uses this class');

	Test::Log::Abstraction::new(verbose => 1);
	is_deeply($built[-1]->[1], { verbose => 1 }, 'function form: first argument is an option, not a class');

	Test::Log::Abstraction::new('Local::Sub', verbose => 1);
	is($built[-1]->[0], 'Local::Sub', 'function form with a subclass name uses the subclass');

	is(bless({}, $CLASS)->new(), 'cloned', 'object form clones');
	restore_all();
};

subtest 'new: hostile arguments are ignored, not fatal' => sub {
	my %before = %Test::Log::Abstraction::config;

	isa_ok($CLASS->new('stray'), $CLASS, 'odd list');
	isa_ok($CLASS->new(undef, 'x'), $CLASS, 'undefined key');
	isa_ok($CLASS->new([1, 2]), $CLASS, 'array reference');
	isa_ok(Test::Log::Abstraction::new(''), $CLASS, 'empty string as class');
	isa_ok(Test::Log::Abstraction::new([]), $CLASS, 'reference as class');
	isa_ok($CLASS->new(messages => 'oops', options => 'x', diag_rule => 1, diag => 'none'), $CLASS, 'option names that match internal keys');
	is_deeply(\%Test::Log::Abstraction::config, \%before, '%config is never changed by new()');
};

subtest 'new: invalid options croak with the exact message' => sub {
	throws_ok { $CLASS->new(diag => 'bogus') } croaked(q{invalid diag level 'bogus'}), 'unknown diag level';
	throws_ok { $CLASS->new(diag => {}) } croaked('diag must be a level name, "all", "none" or an array reference of level names'), 'hash as diag';
	throws_ok { $CLASS->new(diag => sub { 1 }) } croaked('diag must be a level name, "all", "none" or an array reference of level names'), 'code as diag';
	throws_ok { $CLASS->new(level => 'loud') } croaked(q{invalid syslog level 'loud'}), 'unknown level';
	throws_ok { $CLASS->new(country => 'GBR') } qr/\A\Q$CLASS: invalid argument: \E.*country/, 'three-letter country';
	throws_ok { $CLASS->new(lang => '../../etc/passwd') } qr/\A\Q$CLASS: invalid argument: \E.*lang/, 'path as lang';
	throws_ok { $CLASS->new(i18n => []) } qr/\A\Q$CLASS: invalid argument: \E.*i18n/, 'array as i18n';
};

subtest 'new: a collaborator that dies part way is not swallowed' => sub {
	mock "${CLASS}::_build" => sub { die "disk on fire\n" };
	throws_ok { $CLASS->new() } qr/\Adisk on fire\n\z/, 'error from _build reaches the caller unchanged';
	restore_all();
	isa_ok($CLASS->new(), $CLASS, 'normal after the mock is removed');
};

# Strategy: _args decides which shapes reach Params::Get; anything else
# must become an empty hash, never a warning or a die
subtest '_args: normalises good shapes' => sub {
	my %caller = (verbose => 1);
	my $result = Test::Log::Abstraction::_args([\%caller]);
	is_deeply($result, { verbose => 1 }, 'single hash reference');
	isnt($result, \%caller, '... is copied, not kept');
	$result->{'verbose'} = 0;
	is($caller{'verbose'}, 1, '... so changing the result leaves the caller alone');

	is_deeply(Test::Log::Abstraction::_args([a => 1, b => 2]), { a => 1, b => 2 }, 'key/value list');
	returns_ok(Test::Log::Abstraction::_args([]), { type => 'hashref' }, 'empty list returns a hash reference');
	is_deeply(Test::Log::Abstraction::_args([]), {}, '... which is empty');
};

subtest '_args: hostile shapes become an empty hash' => sub {
	my $get_params = spy "${CLASS}::get_params";
	is_deeply(Test::Log::Abstraction::_args(['odd']), {}, 'single scalar');
	is_deeply(Test::Log::Abstraction::_args([1, 2, 3]), {}, 'odd list');
	is_deeply(Test::Log::Abstraction::_args([undef, 1]), {}, 'undefined key');
	is_deeply(Test::Log::Abstraction::_args([a => 1, undef, 2]), {}, 'undefined key after a good pair');
	is_deeply(Test::Log::Abstraction::_args([[1, 2]]), {}, 'array reference');
	is_deeply(Test::Log::Abstraction::_args([bless {}, 'Local::Other']), {}, 'object');
	is(scalar($get_params->()), 0, 'none of them reached Params::Get');
	restore_all();

	my @pairs = map { ("key$_" => $_) } 1 .. $WIDE;
	is(scalar(keys %{Test::Log::Abstraction::_args(\@pairs)}), $WIDE, "$WIDE pairs survive");
};

subtest '_args: Params::Get failures are reported, not hidden' => sub {
	mock "${CLASS}::get_params" => sub { die "Params::Get exploded\n" };
	throws_ok { Test::Log::Abstraction::_args([a => 1]) } qr/\AParams::Get exploded\n\z/, 'die propagates';
	restore_all();

	mock_return "${CLASS}::get_params" => undef;
	is_deeply(Test::Log::Abstraction::_args([a => 1]), {}, 'undef from Params::Get becomes {}');
	restore_all();
};

# Strategy: _build is where the state is set up; check every field, then
# break %config and the validator under it
subtest '_build: sets up the state from the options' => sub {
	my $messages = [];
	my $self = Test::Log::Abstraction::_build($CLASS, { verbose => 1, diag => 'error', level => 'Warn', lang => 'fr' }, $messages);
	state_diag(state => $self);

	isa_ok($self, $CLASS);
	is($self->{'messages'}, $messages, 'capture is the array given');
	is($self->{'verbose'}, 1, 'verbose normalised to 1');
	is($self->{'lang'}, 'fr', 'language resolved');
	is_deeply($self->{'diag_rule'}, { threshold => $SEVERITY{'error'} }, 'diag rule built');
	is($self->{'level'}, $SEVERITY{'warn'}, 'level is case-insensitive');
	is($self->{'options'}->{'diag'}, 'error', 'diag kept in the options for clones');
	memory_cycle_ok($self, 'no reference cycles');
};

subtest '_build: verbose comes from the environment only when not given' => sub {
	local $ENV{'TEST_VERBOSE'} = 0;
	local $ENV{'VERBOSE'} = 0;
	is(Test::Log::Abstraction::_build($CLASS, {}, [])->{'verbose'}, 0, 'off by default');
	{
		local $ENV{'VERBOSE'} = 1;
		is(Test::Log::Abstraction::_build($CLASS, {}, [])->{'verbose'}, 1, 'VERBOSE turns it on');
	}
	{
		local $ENV{'TEST_VERBOSE'} = 1;
		is(Test::Log::Abstraction::_build($CLASS, { verbose => undef }, [])->{'verbose'}, 0, 'verbose => undef means off, even with TEST_VERBOSE');
		is(Test::Log::Abstraction::_build($CLASS, { verbose => 'yes' }, [])->{'verbose'}, 1, 'a true string means on');
	}
};

subtest '_build: broken defaults croak cleanly' => sub {
	{
		local $Test::Log::Abstraction::config{'level'} = undef;
		throws_ok { Test::Log::Abstraction::_build($CLASS, {}, []) } croaked(q{invalid syslog level 'undef'}), 'undefined default level';
	}
	{
		local $Test::Log::Abstraction::config{'level'} = 'nonsense';
		throws_ok { Test::Log::Abstraction::_build($CLASS, {}, []) } croaked(q{invalid syslog level 'nonsense'}), 'unknown default level';
	}
	{
		local $Test::Log::Abstraction::config{'diag'} = undef;
		throws_ok { Test::Log::Abstraction::_build($CLASS, {}, []) } croaked(q{invalid diag level 'undef'}), 'undefined default diag';
	}
	{
		local $Test::Log::Abstraction::config{'lang'} = undef;
		is(Test::Log::Abstraction::_build($CLASS, {}, [])->{'lang'}, 'en', 'undefined default language falls back to English');
	}
};

subtest '_build: validator failure stops construction' => sub {
	mock "${CLASS}::_validate" => sub { die "validator down\n" };
	throws_ok { Test::Log::Abstraction::_build($CLASS, {}, []) } qr/\Avalidator down\n\z/, 'error propagates';
	restore_all();
};

# Strategy: a clone must be independent of its original in every way
subtest '_clone: copies are independent' => sub {
	my $original = logger();
	$original->info('one', { user => 'alice' });
	$original->verbose(1);
	$original->level('error');

	my $clone = Test::Log::Abstraction::_clone($original, {});
	state_diag(clone => $clone);
	isa_ok($clone, $CLASS);
	isnt($clone, $original, 'a new object');
	is($clone->{'verbose'}, 1, 'runtime verbose carried over');
	is($clone->{'level'}, $SEVERITY{'error'}, 'runtime level carried over');

	$clone->{'messages'}->[0]->{'message'} = 'changed';
	$clone->{'messages'}->[0]->{'fields'}->{'user'} = 'mallory';
	push @{$clone->{'messages'}}, { level => 'x', message => 'x' };
	is($original->{'messages'}->[0]->{'message'}, 'one', 'entry text is copied');
	is($original->{'messages'}->[0]->{'fields'}->{'user'}, 'alice', 'fields are copied');
	is($original->count(), 1, 'capture array is copied');
	memory_cycle_ok($clone, 'clone has no reference cycles');
};

subtest '_clone: overrides win' => sub {
	my $original = logger();
	$original->verbose(1);
	is(Test::Log::Abstraction::_clone($original, { verbose => 0 })->{'verbose'}, 0, 'explicit verbose beats runtime value');
	is(Test::Log::Abstraction::_clone($original, { level => 'alert' })->{'level'}, $SEVERITY{'alert'}, 'explicit level beats runtime value');
	is_deeply(Test::Log::Abstraction::_clone($original, { diag => 'all' })->{'diag_rule'}, { all => 1 }, 'new diag rule is built');
};

subtest '_clone: hostile overrides' => sub {
	my $original = logger();
	$original->info('kept');
	throws_ok { Test::Log::Abstraction::_clone($original, { diag => 'bogus' }) } croaked(q{invalid diag level 'bogus'}), 'invalid diag';
	throws_ok { Test::Log::Abstraction::_clone($original, { level => 'bogus' }) } croaked(q{invalid syslog level 'bogus'}), 'invalid level';
	throws_ok { Test::Log::Abstraction::_clone($original, { country => [] }) } qr/\A\Q$CLASS: invalid argument: \E.*country/, 'invalid country';
	is_deeply($original->{'diag_rule'}, {}, 'original rule untouched by failed clones');
	is($original->count(), 1, 'original capture untouched by failed clones');

	my $clone = Test::Log::Abstraction::_clone($original, { messages => [], verbose_rule => 1, level_number => 0 });
	is($clone->count(), 1, 'an override named messages cannot replace the copied capture');
	ok(!exists($clone->{'verbose_rule'}), 'unknown overrides do not become object keys');
};

# Strategy: _validate must turn every validator failure into our message,
# without the validator's own file and line
subtest '_validate: success and unknown keys' => sub {
	my $schema = { a => { type => 'string', optional => 1 } };
	is_deeply(Test::Log::Abstraction::_validate($CLASS, $schema, { a => 'x', unknown => 1 }), { a => 'x' }, 'unknown key dropped');
	returns_ok(Test::Log::Abstraction::_validate($CLASS, $schema, {}), { type => 'hashref' }, 'empty input gives a hash reference');
};

subtest '_validate: every failure becomes invalid_argument' => sub {
	mock "${CLASS}::validate_strict" => sub { die "Params::Validate::Strict line 9: validate_strict: Parameter 'x' is bad at /elsewhere/Foo.pm line 3.\n" };
	throws_ok { Test::Log::Abstraction::_validate($CLASS, {}, {}) } croaked(q{invalid argument: Parameter 'x' is bad}), 'prefix and location stripped';
	restore_all();

	mock "${CLASS}::validate_strict" => sub { die { code => 42 } };
	throws_ok { Test::Log::Abstraction::_validate($CLASS, {}, {}) } qr/\A\Q$CLASS: invalid argument: HASH(0x\E/, 'non-string exception still reported';
	restore_all();

	mock_return "${CLASS}::validate_strict" => undef;
	is_deeply(Test::Log::Abstraction::_validate($CLASS, {}, {}), {}, 'undef from the validator becomes {}');
	restore_all();

	my $logger = logger(lang => 'de');
	throws_ok { Test::Log::Abstraction::_validate($logger, { a => { type => 'integer' } }, { a => 'x' }) } qr/\A\Q$CLASS: ung\E\x{fc}ltiges Argument: /, 'reported in the logger language';
};

subtest '_reason: hostile errors' => sub {
	like(Test::Log::Abstraction::_reason({ code => 1 }), qr/\AHASH\(0x[0-9a-f]+\)\z/, 'hash exception');
	is(Test::Log::Abstraction::_reason(bless({}, 'Local::Text')), 'overloaded text', 'exception object with a text form');
	is(Test::Log::Abstraction::_reason("line one\nline two at x line 1.\n"), 'line one\\x0Aline two', 'a newline is escaped, so the error stays on one line');
	is(Test::Log::Abstraction::_reason(' at x line 1.'), '', 'nothing but a location');
	is(Test::Log::Abstraction::_reason('at x line 1.'), 'at x line 1.', 'no space before at: not a location');
	# ok() rather than is(): if the cap breaks, is() would print the whole
	# million-character result, which looks like a hung test
	my $cut = Test::Log::Abstraction::_reason(('x' x $HUGE) . ' at y line 2.');
	ok($cut eq ('x' x $MAX_REASON) . '...', 'huge message is cut short')
		or diag('got ', length($cut), ' characters');
};

subtest '_reason: removes only a trailing location' => sub {
	is(Test::Log::Abstraction::_reason("bad thing at /a/b.pm line 12.\n"), 'bad thing', 'location removed');
	is(Test::Log::Abstraction::_reason("bad thing at /a/b.pm line 12\n"), 'bad thing', 'without the full stop');
	is(Test::Log::Abstraction::_reason('no location'), 'no location', 'text without a location unchanged');
	is(Test::Log::Abstraction::_reason("look at this line 5 at x line 2.\n"), 'look at this line 5', 'only the last location');
	is(Test::Log::Abstraction::_reason(undef), '', 'undef gives an empty string');
	is(Test::Log::Abstraction::_reason(''), '', 'empty stays empty');
};

# Strategy: walk the precedence table, then feed garbage at every level
subtest '_resolve_lang: precedence' => sub {
	local $ENV{'LC_ALL'} = 'de_DE.UTF-8';
	is(Test::Log::Abstraction::_resolve_lang({ lang => 'fr', country => 'DE' }), 'fr', 'lang beats country');
	is(Test::Log::Abstraction::_resolve_lang({ country => 'cn' }), 'zh', 'country, any case');
	is(Test::Log::Abstraction::_resolve_lang({ country => 'JP' }), 'en', 'unmapped country');
	is(Test::Log::Abstraction::_resolve_lang({ lang => 'AUTO' }), 'de', 'auto, any case, reads LC_ALL');
	is(Test::Log::Abstraction::_resolve_lang({}), 'en', 'environment ignored without auto');
	is(Test::Log::Abstraction::_resolve_lang({ lang => 'zh_TW.Big5' }), 'zh', 'locale name reduced');
	is(Test::Log::Abstraction::_resolve_lang({ lang => 'xx', i18n => { xx => {} } }), 'xx', 'language from the i18n option');
	{
		local $Test::Log::Abstraction::config{'lang'} = 'auto';
		is(Test::Log::Abstraction::_resolve_lang({}), 'de', 'auto in %config');
	}
};

subtest '_resolve_lang: garbage falls back to English' => sub {
	local $ENV{'LC_MESSAGES'};
	local $ENV{'LANG'};
	foreach my $value ('', 'C', 'POSIX', 'english', '12', "\0de", '../de', 'ja_JP.UTF-8') {
		local $ENV{'LC_ALL'} = $value;
		is(Test::Log::Abstraction::_resolve_lang({ lang => 'auto' }), 'en', "LC_ALL '" . ($value =~ s/\0/\\0/r) . q{'});
	}
	{
		local $ENV{'LC_ALL'};
		is(Test::Log::Abstraction::_resolve_lang({ lang => 'auto' }), 'en', 'no locale variables at all');
	}
	{
		local $Test::Log::Abstraction::config{'lang'} = undef;
		is(Test::Log::Abstraction::_resolve_lang({}), 'en', 'undefined default, no warning');
	}
	is(Test::Log::Abstraction::_resolve_lang({ lang => 'xx', i18n => { yy => {} } }), 'en', 'i18n for another language does not count');
	is(Test::Log::Abstraction::_resolve_lang({ lang => 'xx', i18n => { xx => 0 } }), 'en', 'false i18n entry does not count');
};

# Strategy: every accepted form, then every malformed form, with the exact
# message for each
subtest '_diag_rule: accepted forms' => sub {
	my $self = logger();
	is_deeply($self->_diag_rule('all'), { all => 1 }, 'all');
	is_deeply($self->_diag_rule('ALL'), { all => 1 }, 'ALL: case-insensitive like level names');
	is_deeply($self->_diag_rule('None'), {}, 'None');
	is_deeply($self->_diag_rule('Error'), { threshold => $SEVERITY{'error'} }, 'level name');
	is_deeply($self->_diag_rule(['INFO', 'crit']), { levels => { info => 1, crit => 1 } }, 'list, lower-cased');
	is_deeply($self->_diag_rule([]), { levels => {} }, 'empty list prints nothing');
	is_deeply($self->_diag_rule(undef), { threshold => $SEVERITY{'warning'} }, 'undef uses %config');
};

subtest '_diag_rule: rejected forms' => sub {
	my $self = logger();
	my $type = 'diag must be a level name, "all", "none" or an array reference of level names';
	throws_ok { $self->_diag_rule('') } croaked(q{invalid diag level ''}), 'empty string';
	throws_ok { $self->_diag_rule('all ') } croaked(q{invalid diag level 'all '}), 'trailing space';
	throws_ok { $self->_diag_rule([undef]) } croaked(q{invalid diag level 'undef'}), 'undef in a list';
	throws_ok { $self->_diag_rule(['info', 'all']) } croaked(q{invalid diag level 'all'}), "'all' is not a level inside a list";
	throws_ok { $self->_diag_rule([[]]) } qr/\A\Q$CLASS: invalid diag level 'ARRAY(0x\E/, 'reference in a list';
	throws_ok { $self->_diag_rule({}) } croaked($type), 'hash';
	throws_ok { $self->_diag_rule(\'error') } croaked($type), 'scalar reference';
	throws_ok { $self->_diag_rule(bless [], 'Local::Other') } croaked($type), 'blessed array is not a plain list';
	{
		local $Test::Log::Abstraction::config{'diag'} = undef;
		throws_ok { $self->_diag_rule(undef) } croaked(q{invalid diag level 'undef'}), 'undef with no default';
	}
};

# ===========================================================================
# Logging: level methods, is_*, _object, _record, _entry, _stringify,
# _diags, AUTOLOAD, DESTROY
# ===========================================================================

# Strategy: every generated method must hand its exact name and arguments
# to _record, and refuse anything that is not a logger
subtest 'level methods: delegate to _record' => sub {
	my @calls;
	mock "${CLASS}::_record" => sub { push @calls, [@_[1, 2]]; return $_[0] };
	my $self = logger();
	my %results = map { $_ => [$self->$_('a', 'b'), shift(@calls)] } sort keys %SEVERITY;
	restore_all();

	foreach my $level (sort keys %results) {
		is_deeply($results{$level}, [$self, [$level, ['a', 'b']]], "$level passes its name and arguments, returns the logger");
	}
};

subtest 'level methods: refuse non-logger invocants' => sub {
	my $spy = spy "${CLASS}::_record";
	foreach my $level (sort keys %SEVERITY) {
		my $method = "${CLASS}::$level";
		no strict 'refs';
		throws_ok { $CLASS->$level('x') } croaked("$level() must be called on an object, not on the class"), "$level on the class";
		throws_ok { &{$method}(undef, 'x') } croaked("$level() must be called on an object, not on the class"), "$level on undef";
		throws_ok { &{$method}({}, 'x') } croaked("$level() must be called on an object, not on the class"), "$level on a plain hash";
		throws_ok { &{$method}(Local::Other->new(), 'x') } croaked("$level() must be called on an object, not on the class"), "$level on another class";
	}
	is(scalar($spy->()), 0, '_record never reached');
	restore_all();
};

subtest 'is_*: follow the threshold' => sub {
	my $self = logger();

	# Aliases share a severity, so one name per severity covers every case
	my %by_severity = reverse %SEVERITY;
	foreach my $threshold (sort { $a <=> $b } keys %by_severity) {
		$self->{'level'} = $threshold;
		my @want = map { ($SEVERITY{$_} <= $threshold) ? 1 : 0 } @PREDICATES;
		is_deeply([map { my $method = "is_$_"; $self->$method() } @PREDICATES], \@want, "threshold $threshold ($by_severity{$threshold})");
	}
	returns_ok($self->is_debug(), { type => 'boolean' }, 'returns a boolean');
};

subtest 'is_*: refuse non-logger invocants' => sub {
	foreach my $level (@PREDICATES) {
		my $method = "is_$level";
		no strict 'refs';
		throws_ok { $CLASS->$method() } croaked("$method() must be called on an object, not on the class"), "$method on the class";
		throws_ok { &{"${CLASS}::$method"}({ level => 7 }) } croaked("$method() must be called on an object, not on the class"), "$method on a hash that looks like a logger";
	}
};

# Strategy: _object is the gatekeeper for every public method
subtest '_object: accepts loggers' => sub {
	my $self = logger();
	is(Test::Log::Abstraction::_object($self, 'm'), $self, 'logger passes and is returned');
	my $sub = Local::Sub->new(diag => 'none');
	is(Test::Log::Abstraction::_object($sub, 'm'), $sub, 'subclass object passes');
};

subtest '_object: refuses everything else' => sub {
	throws_ok { Test::Log::Abstraction::_object($CLASS, 'm') } croaked('m() must be called on an object, not on the class'), 'class name';
	throws_ok { Test::Log::Abstraction::_object('Local::Sub', 'm') } qr/\A\QLocal::Sub: m() must be called/, 'subclass name is reported';
	throws_ok { Test::Log::Abstraction::_object(undef, 'm') } croaked('m() must be called on an object, not on the class'), 'undef';
	throws_ok { Test::Log::Abstraction::_object('', 'm') } croaked('m() must be called on an object, not on the class'), 'empty string';
	throws_ok { Test::Log::Abstraction::_object('No::Such::Class', 'm') } croaked('m() must be called on an object, not on the class'), 'unknown class name';
	throws_ok { Test::Log::Abstraction::_object({}, 'm') } croaked('m() must be called on an object, not on the class'), 'unblessed hash';
	throws_ok { Test::Log::Abstraction::_object(sub { 1 }, 'm') } croaked('m() must be called on an object, not on the class'), 'code reference';
	throws_ok { Test::Log::Abstraction::_object(\$CLASS, 'm') } croaked('m() must be called on an object, not on the class'), 'reference to the class name';
	throws_ok { Test::Log::Abstraction::_object(Local::Other->new(), 'm') } croaked('m() must be called on an object, not on the class'), 'another class';
};

# Strategy: _record with all three collaborators mocked, to check the
# order of events and that the caller's error state survives
subtest '_record: stores, then prints only when allowed' => sub {
	my $self = logger();
	my $printed_after_store;
	mock "${CLASS}::_entry" => sub { return { level => $_[0], message => 'built' } };
	mock_sequence "${CLASS}::_diags" => (1, 0);
	mock "${CLASS}::_emit" => sub { $printed_after_store = scalar(@{$_[0]->{'messages'}}); return $_[0] };
	my $emit = spy "${CLASS}::_emit";

	is($self->_record('WARN', ['x']), $self, 'returns the logger');
	is($self->{'messages'}->[0]->{'level'}, 'warn', 'level lower-cased before _entry');
	is($printed_after_store, 1, 'entry stored before it is printed');
	$self->_record('debug', ['y']);
	is(scalar($emit->()), 1, 'not printed when _diags says no');
	is($self->count(), 2, 'but still stored');
	restore_all();
};

subtest '_record: $@ and $! survive collaborators that change them' => sub {
	my $self = logger();
	mock "${CLASS}::_entry" => sub { $@ = 'clobbered'; $! = ENOENT; return { level => 'x', message => 'x' } };
	mock "${CLASS}::_diags" => sub { eval { die "inner\n" }; return 0 };

	$@ = $SENTINEL;
	$! = 0;
	$self->_record('warn', []);
	is($@, $SENTINEL, '$@ restored');
	is($! + 0, 0, '$! restored');
	restore_all();
};

subtest '_record: a failing collaborator does not corrupt the capture' => sub {
	my $self = logger();
	mock_exception "${CLASS}::_entry" => 'entry failed';
	throws_ok { $self->_record('warn', ['x']) } qr/entry failed/, '_entry failure propagates';
	is($self->count(), 0, 'nothing half-stored');
	restore_all();

	mock_exception "${CLASS}::_emit" => 'printing failed';
	$self->{'verbose'} = 1;
	throws_ok { $self->_record('warn', ['x']) } qr/printing failed/, '_emit failure propagates';
	is($self->count(), 1, 'the entry was already safely stored');
	restore_all();
};

# Strategy: _entry is pure; check each argument rule, then make sure the
# caller's data and the global $/ are never touched
subtest '_entry: argument rules' => sub {
	is_deeply(Test::Log::Abstraction::_entry('info', ['a', 'b', 1]), { level => 'info', message => 'ab1' }, 'parts joined');
	is_deeply(Test::Log::Abstraction::_entry('info', []), { level => 'info', message => '' }, 'no arguments');
	is_deeply(Test::Log::Abstraction::_entry('info', [['x', 'y']]), { level => 'info', message => 'xy' }, 'lone array reference is parts');
	is_deeply(Test::Log::Abstraction::_entry('info', [{ k => 'v' }]), { level => 'info', message => '{k => v}' }, 'lone hash is the message');
	is_deeply(Test::Log::Abstraction::_entry('info', ['m', { k => 'v' }]), { level => 'info', message => 'm', fields => { k => 'v' } }, 'trailing hash is fields');
	is_deeply(Test::Log::Abstraction::_entry('info', ['m', {}]), { level => 'info', message => 'm' }, 'empty fields dropped');
	is(Test::Log::Abstraction::_entry('info', ['0'])->{'message'}, '0', 'false message kept');
	is(Test::Log::Abstraction::_entry('info', ["x\n\n"])->{'message'}, "x\n", 'exactly one newline removed');
	is(Test::Log::Abstraction::_entry('info', ["x\r\n"])->{'message'}, "x\r", 'only the newline, not the carriage return');
};

subtest '_entry: hostile arguments' => sub {
	my $object_hash = bless { k => 'v' }, 'Local::Other';
	my $entry = Test::Log::Abstraction::_entry('info', ['m', $object_hash]);
	ok(!exists($entry->{'fields'}), 'blessed hash at the end is not fields');
	like($entry->{'message'}, qr/\Am\QLocal::Other=HASH(0x\E/, '... it is part of the message');

	my @args = ('m', { k => 'v' });
	my $fields = $args[1];
	$entry = Test::Log::Abstraction::_entry('info', \@args);
	is(scalar(@args), 2, 'caller array not shortened');
	isnt($entry->{'fields'}, $fields, 'fields copied');
	$fields->{'k'} = 'changed';
	is($entry->{'fields'}->{'k'}, 'v', 'later change by the caller does not rewrite history');

	is(length(Test::Log::Abstraction::_entry('info', ['x' x $HUGE])->{'message'}), $HUGE, 'very long message kept whole');
	is(Test::Log::Abstraction::_entry('info', [(undef) x 3])->{'message'}, 'undefundefundef', 'undef parts, no warnings');
};

subtest '_entry: does not depend on or change $/ or $_' => sub {
	foreach my $separator (undef, '', 'X', "\n\n") {
		local $/ = $separator;
		local $_ = $SENTINEL;
		is(Test::Log::Abstraction::_entry('info', ["x\n"])->{'message'}, 'x', 'newline removed with $/ = ' . (defined($separator) ? "'" . ($separator =~ s/\n/\\n/gr) . q{'} : 'undef'));
		is($_, $SENTINEL, '... $_ untouched');
	}
};

# Strategy: _stringify must render anything, never die, never warn, never
# loop, and leave its bookkeeping hash as it found it
subtest '_stringify: ordinary values' => sub {
	my %cases = (
		'undef' => [undef],
		'plain' => ['plain'],
		'42' => [42],
		'{a => 1, b => undef}' => [{ b => undef, a => 1 }],
		'[1, [2, {x => y}]]' => [[1, [2, { x => 'y' }]]],
		'{}' => [{}],
		'[]' => [[]],
		'overloaded text' => [bless({}, 'Local::Text')],
	);
	foreach my $want (sort keys %cases) {
		is(Test::Log::Abstraction::_stringify($cases{$want}->[0], {}), $want, "renders $want");
	}
	like(Test::Log::Abstraction::_stringify(sub { 1 }, {}), qr/\ACODE\(0x[0-9a-f]+\)\z/, 'code reference');
	like(Test::Log::Abstraction::_stringify(\'x', {}), qr/\ASCALAR\(0x[0-9a-f]+\)\z/, 'scalar reference');
	like(Test::Log::Abstraction::_stringify(qr/ab/, {}), qr/ab/, 'regular expression');
};

subtest '_stringify: hostile values' => sub {
	my $seen = {};
	my $loop = { name => 'loop' };
	$loop->{'self'} = $loop;
	is(Test::Log::Abstraction::_stringify($loop, $seen), "{name => loop, self => $CYCLE}", 'hash cycle');
	is_deeply($seen, {}, 'bookkeeping hash restored');

	my @list = (1);
	push @list, \@list;
	is(Test::Log::Abstraction::_stringify(\@list, {}), "[1, $CYCLE]", 'array cycle');

	my $shared = ['s'];
	is(Test::Log::Abstraction::_stringify([$shared, $shared], {}), '[[s], [s]]', 'shared reference is not a cycle');

	like(Test::Log::Abstraction::_stringify(bless({}, 'Local::Bomb'), {}), qr/\ALocal::Bomb=HASH\(0x[0-9a-f]+\)\z/, 'dying overload falls back');
	is(Test::Log::Abstraction::_stringify(bless({}, 'Local::Undef'), {}), '', 'undef overload is empty, no warning');

	local $@ = $SENTINEL;
	Test::Log::Abstraction::_stringify(bless({}, 'Local::Bomb'), {});
	is($@, $SENTINEL, 'the caught overload error does not leak into $@');

	my $deep = 'bottom';
	$deep = [$deep] for 1 .. $DEEP;
	my $text = Test::Log::Abstraction::_stringify($deep, {});
	is(length($text), length('bottom') + 2 * $DEEP, "$DEEP levels deep, no recursion warning");

	my $wide = [1 .. $WIDE];
	is(scalar(split(/, /, substr(Test::Log::Abstraction::_stringify($wide, {}), 1, -1))), $WIDE, "$WIDE elements wide");
};

# Strategy: _diags is a pure decision table; check every rule against a
# known, an alias and an unknown level
subtest '_diags: decision table' => sub {
	my $self = logger();
	my @rows = (
		[{}, 0, 'error', 0, 'none: nothing'],
		[{}, 1, 'trace', 1, 'verbose beats none'],
		[{}, 1, 'nolevel', 1, 'verbose prints unknown levels too'],
		[{ all => 1 }, 0, 'nolevel', 1, 'all prints unknown levels'],
		[{ levels => { info => 1 } }, 0, 'info', 1, 'listed level'],
		[{ levels => { info => 1 } }, 0, 'informational', 0, 'alias is not listed'],
		[{ threshold => 3 }, 0, 'err', 1, 'alias at threshold'],
		[{ threshold => 3 }, 0, 'warn', 0, 'below threshold'],
		[{ threshold => 3 }, 0, 'panic', 1, 'above threshold'],
		[{ threshold => 7 }, 0, 'nolevel', 0, 'unknown level never passes a threshold'],
		[{ threshold => 7 }, 0, '', 0, 'empty level name'],
	);
	foreach my $row (@rows) {
		my ($rule, $verbose, $level, $want, $name) = @{$row};
		$self->{'diag_rule'} = $rule;
		$self->{'verbose'} = $verbose;
		is($self->_diags($level), $want, $name);
	}
	returns_ok($self->_diags('error'), { type => 'integer', min => 0, max => 1 }, 'returns 0 or 1');
};

# Strategy: AUTOLOAD with _record and _emit mocked; it must accept any
# method name Perl can produce and refuse non-logger invocants
subtest 'AUTOLOAD: unknown methods are stored and announced' => sub {
	my $self = logger();
	my (@recorded, @printed);
	mock "${CLASS}::_record" => sub { push @recorded, [@_[1, 2]]; return $_[0] };
	mock "${CLASS}::_emit" => sub { push @printed, $_[1]; return $_[0] };

	is($self->wran('oops'), $self, 'returns the logger');
	is_deeply($recorded[0], ['wran', ['oops']], 'stored under the called name');
	is($printed[0], "$CLASS: no method 'wran'", 'notice text');

	my $name = 'has-hyphen';
	$self->$name('x');
	is($recorded[1]->[0], 'has-hyphen', 'a name that is not a word');
	is($printed[1], "$CLASS: no method 'has-hyphen'", '... announced correctly');

	restore_all();
};

subtest 'AUTOLOAD: refuses non-logger invocants' => sub {
	my $spy = spy "${CLASS}::_record";
	throws_ok { $CLASS->nosuch() } croaked('nosuch() must be called on an object, not on the class'), 'class invocant';
	throws_ok { Local::Sub->nosuch() } qr/\A\QLocal::Sub: nosuch() must be called/, 'subclass invocant';
	is(scalar($spy->()), 0, 'nothing recorded');
	restore_all();
};

subtest 'DESTROY: never records, never prints' => sub {
	my $spy = spy "${CLASS}::_record";
	{
		my $self = logger();
		$self->DESTROY();
	}
	is(scalar($spy->()), 0, 'no _record call');
	restore_all();
};

# ===========================================================================
# Inspection: messages, clear, count, _at_level, lang, flush, verbose, level
# ===========================================================================

subtest 'messages: a fresh copy every time' => sub {
	my $self = logger();
	$self->info('a');
	my $first = $self->messages();
	returns_ok($first, { type => 'arrayref' }, 'array reference');
	isnt($first, $self->messages(), 'new array each call');
	isnt($first, $self->{'messages'}, 'not the internal array');
	@{$first} = ();
	is($self->count(), 1, 'emptying the copy leaves the capture');
};

subtest 'clear: empties the capture, keeps the settings' => sub {
	my $self = logger(level => 'error', lang => 'fr');
	$self->info('a') for 1 .. 3;
	my $capture = $self->{'messages'};
	is($self->clear(), $self, 'returns the logger');
	is($self->count(), 0, 'emptied');
	is($self->{'messages'}, $capture, 'same array, so outstanding references see the change');
	is($self->level(), $SEVERITY{'error'}, 'level kept');
	is($self->lang(), 'fr', 'language kept');
	is($self->clear()->count(), 0, 'clearing twice is harmless');
};

subtest 'count and _at_level' => sub {
	my $self = logger();
	$self->warn('a');
	$self->warning('b');
	capture_diag { $self->WARN('c') };	# AUTOLOAD, recorded lower-cased; hide its notice
	is($self->count(), 3, 'total');
	is($self->count('WARN'), 2, 'case-insensitive');
	is($self->count('warning'), 1, 'aliases counted apart');
	is($self->count('nolevel'), 0, 'unknown level');
	is($self->count(''), 0, 'empty level');
	returns_ok($self->count(), { type => 'integer', min => 0 }, 'integer');

	my $found = $self->_at_level('Warn');
	is(scalar(@{$found}), 2, '_at_level matches lower-cased');
	isnt($found, $self->_at_level('warn'), '_at_level returns a new array');

};

subtest 'lang and flush' => sub {
	my $self = logger(lang => 'zh');
	is($self->lang(), 'zh', 'lang');
	returns_ok($self->lang(), { type => 'string', matches => qr/\A[a-z]{2,3}\z/ }, 'language code');
	is($self->flush(), $self, 'flush returns the logger');
	is($self->count(), 0, 'flush stores nothing');
};

subtest 'inspection methods: refuse non-logger invocants' => sub {
	# Every form of non-logger, against every method that reads the state
	my %invocants = (
		'the class' => $CLASS,
		'undef' => undef,
		'a hash that looks like a logger' => { messages => [], level => 7, verbose => 0, lang => 'en' },
		'another class' => Local::Other->new(),
	);
	foreach my $method (qw(messages clear count verbose level lang)) {
		foreach my $form (sort keys %invocants) {
			no strict 'refs';
			throws_ok { &{"${CLASS}::$method"}($invocants{$form}) } croaked("$method() must be called on an object, not on the class"), "$method on $form";
		}
	}
};

subtest 'count: rejects a level that is not a string' => sub {
	my $self = logger();
	$self->info('x');
	foreach my $bad ([], {}, sub { 1 }, \'info', Local::Other->new()) {
		throws_ok { $self->count($bad) } croaked(q{invalid argument: Parameter 'level' must be a string}), 'count(' . ref($bad) . ')';
	}
	is($self->count(), 1, 'capture unchanged');
};

subtest 'verbose: get and set' => sub {
	my $self = logger();
	is($self->verbose(), 0, 'get');
	is($self->verbose('yes'), 1, 'true string turns it on');
	is($self->verbose(), 1, '... and it stays on');
	is($self->verbose(undef), 0, 'undef turns it off');
	is($self->verbose(0), 0, 'zero');
	is($self->verbose('0.0'), 1, 'the string 0.0 is true in Perl');
};

subtest 'level: get, set, and reject' => sub {
	my $self = logger();
	is($self->level(), $SEVERITY{'trace'}, 'default');
	is($self->level('ALERT'), $self, 'set returns the logger');
	is($self->level(), $SEVERITY{'alert'}, 'case-insensitive');
	is($self->level(undef), $SEVERITY{'alert'}, 'undef is a get');

	foreach my $bad ('loud', '', '0', ' warn') {
		my $result = 'unset';
		warning_like { $result = $self->level($bad) } qr/\A\Q$CLASS: invalid syslog level '$bad'\E at \Q$FILE\E line \d+/, "carp for '$bad'";
		is($result, undef, "... returns undef for '$bad'");
	}
	is($self->level(), $SEVERITY{'alert'}, 'unchanged after rejected names');
	throws_ok { $CLASS->level() } croaked('level() must be called on an object, not on the class'), 'class invocant';
};

# ===========================================================================
# Assertions: like, unlike, has_level, empty, _matching, _assert, _explain
# ===========================================================================

# Strategy: _assert is mocked so that these tests check what each
# assertion decides, without adding failing tests to this file's TAP
subtest 'like, unlike, has_level, empty: decisions' => sub {
	my @asserted;
	mock "${CLASS}::_assert" => sub { push @asserted, [@_[1 .. 4]]; return $_[1] ? 1 : 0 };
	my $self = logger();
	$self->warn('the widget broke');
	$self->info('fine');

	ok($self->like(qr/widget/, 'n'), 'like: match');
	is_deeply([@{$asserted[-1]}[1, 2]], ['n', 'captured'], 'like: name and heading passed on');
	ok(!$self->like('^fine$x'), 'like: no match');
	ok($self->unlike(qr/nothing/), 'unlike: no match passes');
	ok(!$self->unlike(qr/widget/), 'unlike: match fails');
	is(scalar(@{$asserted[-1]->[3]}), 1, 'unlike: only the matching entry is explained');
	ok($self->has_level('WARN'), 'has_level: case-insensitive');
	ok(!$self->has_level('warning'), 'has_level: alias is different');
	ok(!$self->empty(), 'empty: fails with messages');
	ok($self->clear()->empty(), 'empty: passes when empty');
	restore_all();
};

subtest 'like, unlike, has_level: hostile arguments' => sub {
	my $assert = spy "${CLASS}::_assert";
	my $self = logger();
	$self->warn('x');

	foreach my $method (qw(like unlike)) {
		throws_ok { $self->$method() } croaked("$method() needs a pattern"), "$method: missing pattern";
		throws_ok { $self->$method(undef, 'name') } croaked("$method() needs a pattern"), "$method: undef pattern";
		throws_ok { $self->$method([]) } croaked(q{invalid argument: Parameter 'pattern' must be one of regex, string}), "$method: array";
		throws_ok { $self->$method(qr/x/, []) } qr/\A\Q$CLASS: invalid argument: \E.*name/, "$method: array as name";
		throws_ok { $self->$method('(') } qr/\A\Q$CLASS: invalid argument: Unmatched ( in regex\E/, "$method: pattern that does not compile";
		throws_ok { $self->$method('(?{ die "injected" })') } qr/\A\Q$CLASS: invalid argument: Eval-group not allowed at runtime\E/, "$method: code in a string pattern";
		throws_ok { $CLASS->$method(qr/x/) } croaked("$method() must be called on an object, not on the class"), "$method: class invocant";
	}
	throws_ok { $self->has_level() } croaked('has_level() needs a level name'), 'has_level: missing level';
	throws_ok { $self->has_level({}) } croaked(q{invalid argument: Parameter 'level' must be a string}), 'has_level: hash';
	throws_ok { $CLASS->has_level('x') } croaked('has_level() must be called on an object, not on the class'), 'has_level: class invocant';
	throws_ok { $CLASS->empty() } croaked('empty() must be called on an object, not on the class'), 'empty: class invocant';
	is(scalar($assert->()), 0, 'no bad call reached _assert');
	restore_all();
};

subtest '_matching: matches in order and leaves $_ alone' => sub {
	my $self = logger();
	$self->info($_) for qw(apple banana cherry);
	local $_ = $SENTINEL;
	is_deeply([map { $_->{'message'} } @{$self->_matching('an')}], ['banana'], 'string pattern');
	is_deeply([map { $_->{'message'} } @{$self->_matching(qr/^[ac]/)}], ['apple', 'cherry'], 'compiled pattern, in order');
	is_deeply($self->_matching(qr/zzz/), [], 'no match gives an empty array');
	is($_, $SENTINEL, '$_ untouched');
};

subtest '_matching: malformed and malicious patterns' => sub {
	my $self = logger();
	$self->info('x');
	my %bad = (
		'[' => 'Unmatched [ in regex',
		'(' => 'Unmatched ( in regex',
		'a{2,1}' => 'Quantifier {n,m} with n > m can\'t match in regex',
		'(?{ 1 })' => 'Eval-group not allowed at runtime',
		'(??{ "x" })' => 'Eval-group not allowed at runtime',
		'\\' => 'Trailing \\ in regex',
	);
	foreach my $pattern (sort keys %bad) {
		throws_ok { $self->_matching($pattern) } qr/\A\Q$CLASS: invalid argument: $bad{$pattern}\E/, "rejects '$pattern'";
	}
	local $@ = $SENTINEL;
	is_deeply($self->_matching('x')->[0]->{'message'}, 'x', 'a good pattern after bad ones still works');
};

# Strategy: replace Test::Builder::ok to see what _assert hands it,
# including $Test::Builder::Level, which decides the reported line
subtest '_assert: reports through Test::Builder at the right level' => sub {
	my $self = logger();
	my $outer = $Test::Builder::Level;
	my (@seen, @results, @level_after);

	# While ok() is mocked, this subtest's own is() would be mocked too, so
	# collect everything first and check it after restore_all()
	mock 'Test::Builder::ok' => sub { push @seen, { args => [@_[1, 2]], level => $Test::Builder::Level }; return $_[1] ? 1 : 0 };
	my $explain = spy "${CLASS}::_explain";
	mock "${CLASS}::_emit" => sub { return $_[0] };
	push @results, $self->_assert(1, 'passes', 'captured', []);
	push @level_after, $Test::Builder::Level;
	my $explained_on_pass = scalar($explain->());
	push @results, $self->_assert(0, 'fails', 'captured', []);
	my $explained_on_fail = scalar($explain->());
	restore_all();

	is_deeply(\@results, [1, 0], 'result of ok() returned');
	is_deeply($seen[0]->{'args'}, [1, 'passes'], 'value and name given to ok()');
	is($seen[0]->{'level'}, $outer + 2, 'Level raised by two frames');
	is($level_after[0], $outer, 'Level restored afterwards');
	is($explained_on_pass, 0, 'nothing explained on a pass');
	is($explained_on_fail, 1, 'failure explained once');
};

subtest '_explain: lists at most the limit' => sub {
	my $self = logger();
	my @lines;
	mock "${CLASS}::_emit" => sub { push @lines, $_[1]; return $_[0] };

	my %cases = (0 => 1, 1 => 2, $MAX_EXPLAIN => $MAX_EXPLAIN + 1, $MAX_EXPLAIN + 1 => $MAX_EXPLAIN + 2, $WIDE => $MAX_EXPLAIN + 2);
	foreach my $total (sort { $a <=> $b } keys %cases) {
		@lines = ();
		my $entries = [map { { level => 'info', message => "m$_" } } 1 .. $total];
		is($self->_explain('captured', $entries), $self, "$total entries: returns the logger");
		is(scalar(@lines), $cases{$total}, "$total entries: $cases{$total} lines");
	}
	is($lines[0], "$CLASS: $WIDE messages were captured:", 'heading has the true total');
	is($lines[1], '    [info] m1', 'entry format');
	is($lines[-1], '    ... and ' . ($WIDE - $MAX_EXPLAIN) . ' more', 'summary of the rest');

	@lines = ();
	$self->_explain('captured', []);
	is_deeply(\@lines, ["$CLASS: no messages were captured"], 'zero form');
	restore_all();
};

# ===========================================================================
# Output and messages: _emit, i18n, _template, _variant, _plural,
# _interpolate, _format, _croak
# ===========================================================================

# Strategy: replace Test::Builder::diag to see exactly which bytes _emit
# would print in each encoding situation
subtest '_emit: encodes character strings only' => sub {
	my $self = logger();
	my @printed;
	my $characters = "caf\x{e9}";
	utf8::upgrade($characters);

	# diag() is mocked, so a failing check here could not report itself;
	# print everything first, then check after the mock is removed
	mock 'Test::Builder::diag' => sub { push @printed, $_[1]; return 0 };
	my $returned = $self->_emit('plain');
	$self->_emit("caf\xc3\xa9");
	$self->_emit($characters);
	$self->_emit("snow \x{2603}");
	restore_all();

	is($returned, $self, 'returns the logger');
	is($printed[0], 'plain', 'ASCII unchanged');
	is($printed[1], "caf\xc3\xa9", 'byte string unchanged');
	is($printed[2], "caf\xc3\xa9", 'Latin-1 character string encoded');
	is($printed[3], "snow \xe2\x98\x83", 'wide character encoded');
	ok(!utf8::is_utf8($printed[3]), 'what is printed is bytes');

	mock 'Test::Builder::diag' => sub { push @printed, $_[1]; return 0 };

	mock 'PerlIO::get_layers' => sub { return ('unix', 'perlio', 'encoding(utf-8-strict)', 'utf8') };
	$self->_emit("snow \x{2603}");
	restore_all();
	is($printed[-1], "snow \x{2603}", 'not encoded twice when the handle encodes');
};

subtest 'i18n: always returns a string' => sub {
	my $self = logger();
	is($self->i18n('no_method', { method => 'x' }), "$CLASS: no method 'x'", 'normal use');
	is($CLASS->i18n('no_method', { method => 'x' }), "$CLASS: no method 'x'", 'class invocant uses %config');
	is($self->i18n('nonexistent'), 'nonexistent', 'unknown key returned');
	is($self->i18n(undef), '', 'undef key gives an empty string');
	is($self->i18n('no_method', 'not a hash'), "$CLASS: no method 'undef'", 'non-hash arguments ignored');
	is($self->i18n('no_method', [method => 'x']), "$CLASS: no method 'undef'", 'array arguments ignored');
	is($self->i18n('no_method', { method => 'x', class => 'Other' }), q{Other: no method 'x'}, 'class can be overridden');
	returns_ok($self->i18n('no_method'), { type => 'string' }, 'string');
};

subtest '_template: search order and missing tables' => sub {
	my $self = logger(lang => 'de', i18n => { de => { a => 'de-override' }, en => { a => 'en-override', b => 'en-only' } });
	is($self->_template('de', 'a'), 'de-override', 'override in the language first');
	is($self->_template('de', 'b'), 'en-only', 'then English overrides');
	like($self->_template('de', 'needs_pattern'), qr/Muster/, 'built-in language table');
	is($self->_template('de', 'entry'), '    [%{level}s] %{message}s', 'built-in English last');
	is($self->_template('de', 'nonexistent'), undef, 'missing key');
	is($self->_template('qq', 'needs_pattern'), '%{class}s: %{method}s() needs a pattern', 'unknown language uses English');
	is($CLASS->_template('en', 'no_method'), q{%{class}s: no method '%{method}s'}, 'class invocant has no overrides');

};

subtest '_template: hostile override tables' => sub {
	foreach my $table ('not a table', [], sub { {} }, undef, 0) {
		my $broken = logger(i18n => { en => $table, de => $table });
		is($broken->_template('de', 'no_method'), q{%{class}s: keine Methode '%{method}s'}, 'override ' . (defined($table) ? "'$table'" : 'undef') . ' skipped');
	}
	my $self = logger(i18n => {});
	is($self->_template('en', ''), undef, 'empty key');
	is($self->_template('', 'no_method'), q{%{class}s: no method '%{method}s'}, 'empty language uses English');
};

subtest '_variant: chooses forms and always ends' => sub {
	my $forms = { male => { one => 'm1', other => 'mN' }, female => 'f', other => 'o' };
	is(Test::Log::Abstraction::_variant('text', {}, 'en'), 'text', 'string unchanged');
	is(Test::Log::Abstraction::_variant($forms, { gender => 'female' }, 'en'), 'f', 'gender');
	is(Test::Log::Abstraction::_variant($forms, { gender => 'male', count => 1 }, 'en'), 'm1', 'gender then plural');
	is(Test::Log::Abstraction::_variant($forms, { gender => 'robot' }, 'en'), 'o', 'unknown gender');
	is(Test::Log::Abstraction::_variant({ male => 'm' }, {}, 'en'), '', 'no form applies');

	my $loop = {};
	$loop->{'other'} = $loop;
	is(Test::Log::Abstraction::_variant($loop, {}, 'en'), '', 'self-referential template ends');
	my ($first, $second) = ({}, {});
	$first->{'other'} = $second;
	$second->{'other'} = $first;
	is(Test::Log::Abstraction::_variant($first, {}, 'en'), '', 'two-step cycle ends');

	my $chain = 'end';
	$chain = { other => $chain } for 1 .. $DEEP;
	is(Test::Log::Abstraction::_variant($chain, {}, 'en'), 'end', "$DEEP-level chain is walked to the end");
};

subtest '_plural: language rules' => sub {
	my $all = { zero => 1, one => 1, other => 1 };
	my $no_zero = { one => 1, other => 1 };
	my @rows = (
		[$all, 0, 'en', 'zero'], [$all, 1, 'en', 'one'], [$all, 2, 'en', 'other'],
		[$no_zero, 0, 'en', 'other'], [$no_zero, 0, 'fr', 'one'], [$no_zero, 1.5, 'fr', 'one'],
		[$no_zero, 2, 'fr', 'other'], [$no_zero, -1, 'fr', 'one'], [$no_zero, -5, 'fr', 'other'],
		[$no_zero, 1, 'de', 'one'], [$no_zero, 1, 'zh', 'other'], [$no_zero, 1, 'qq', 'one'],
		[{ other => 1 }, 1, 'en', 'other'],
	);
	foreach my $row (@rows) {
		my ($template, $count, $lang, $want) = @{$row};
		is(Test::Log::Abstraction::_plural($template, $count, $lang), $want, "$lang $count -> $want");
	}
};

subtest '_plural: hostile counts and languages' => sub {
	my $all = { zero => 1, one => 1, other => 1 };
	foreach my $odd (undef, 'many', '', ' 1', 'NaN', 'Inf', '-Inf', '1e400', '9' x 400, [], {}, Local::Other->new()) {
		my $result = Test::Log::Abstraction::_plural($all, $odd, 'en');
		ok(exists($all->{$result}), 'count ' . (defined($odd) ? "'$odd'" : 'undef') . " gives a valid form ($result)");
	}
	foreach my $lang (undef, '', 'qq', '../en', []) {
		is(Test::Log::Abstraction::_plural($all, 1, $lang), 'one', 'language ' . (defined($lang) ? "'$lang'" : 'undef') . ' uses the English rule');
	}
	is(Test::Log::Abstraction::_plural({}, 1, 'en'), 'other', 'template with no forms at all');
};

subtest '_interpolate: placeholders' => sub {
	my %args = (a => 'A', n => 3, r => 1 / 3);
	is(Test::Log::Abstraction::_interpolate('%{a}s-%{n}d-%{r}.2f', \%args), 'A-3-0.33', 'conversions');
	is(Test::Log::Abstraction::_interpolate('100%% of %{a}s', \%args), '100% of A', 'escaped percent');
	is(Test::Log::Abstraction::_interpolate('no placeholders', {}), 'no placeholders', 'plain text');
	is(Test::Log::Abstraction::_interpolate('%{missing}s', {}), 'undef', 'missing value');
	ok(!utf8::is_utf8(Test::Log::Abstraction::_interpolate('ascii %{a}s', \%args)), 'ASCII template stays bytes');
	ok(utf8::is_utf8(Test::Log::Abstraction::_interpolate("caf\x{e9} %{a}s", \%args)), 'non-ASCII template becomes characters');
};

subtest '_interpolate: dangerous conversions are not run' => sub {
	is(Test::Log::Abstraction::_interpolate('%{a}n', { a => 1 }), '%{a}n', '%n left as text');
	is(Test::Log::Abstraction::_interpolate('%{a}vd', { a => '1.2' }), '%{a}vd', 'vector flag left as text');
	is(Test::Log::Abstraction::_interpolate('%{a}*d', { a => 1 }), '%{a}*d', 'star width left as text');
	is(Test::Log::Abstraction::_interpolate('%{a}99999999s', { a => 'x' }), '%{a}99999999s', 'huge width left as text, not allocated');
	is(Test::Log::Abstraction::_interpolate('%{a}.99999999f', { a => 1 }), '%{a}.99999999f', 'huge precision left as text');
	is(Test::Log::Abstraction::_interpolate('%{a-b}s', { 'a-b' => 1 }), '%{a-b}s', 'non-word name left as text');
	is(Test::Log::Abstraction::_interpolate('%s %d', {}), '%s %d', 'positional sprintf codes left as text');
};

subtest '_format: never warns' => sub {
	my @rows = (
		['%', 's', 'ignored', '%'],
		[undef, 's', undef, 'undef'],
		[undef, 's', 'text', 'text'],
		[undef, '5s', 'ab', '   ab'],
		[undef, 'd', 42, '42'],
		[undef, 'd', 'abc', 'abc'],
		[undef, 'c', 'abc', 'abc'],
		[undef, 'c', 65, 'A'],
		[undef, '.2f', 'x', 'x'],
		[undef, 'x', 255, 'ff'],
		[undef, 'd', '', ''],
	);
	foreach my $row (@rows) {
		my ($percent, $conversion, $value, $want) = @{$row};
		is(Test::Log::Abstraction::_format($percent, $conversion, $value), $want, "%$conversion of " . (defined($value) ? "'$value'" : 'undef'));
	}
	like(Test::Log::Abstraction::_format(undef, 'd', 'Inf'), qr/\A-?\w+\z/, 'infinity does not warn');
};

subtest '_format and i18n: values whose text form dies' => sub {
	my $error_after;
	my $text = do { local $@ = $SENTINEL; my $t = Test::Log::Abstraction::_format(undef, 's', bless({}, 'Local::Bomb')); $error_after = $@; $t };
	like($text, qr/\ALocal::Bomb=HASH\(0x[0-9a-f]+\)\z/, '_format falls back to the plain form');
	is($error_after, $SENTINEL, '$@ untouched');
	like(logger()->i18n('no_method', { method => bless({}, 'Local::Bomb') }), qr/no method 'Local::Bomb=HASH/, 'i18n still returns a string');
	is(Test::Log::Abstraction::_format(undef, 's', bless({}, 'Local::Undef')), '', 'text form of undef is empty, without a warning');
};

subtest '_croak: translated, at the caller' => sub {
	my $self = logger(lang => 'fr');
	throws_ok { $self->_croak('needs_pattern', { method => 'like' }) } qr/\A\Q$CLASS : like() n\E\x{e9}\Qcessite un motif at $FILE\E line \d+/, 'French, reported at this file';
	throws_ok { $CLASS->_croak('nonexistent') } qr/\Anonexistent at \Q$FILE\E line \d+/, 'unknown key becomes the message';

	my @asked;
	mock "${CLASS}::i18n" => sub { push @asked, [@_[1, 2]]; return 'mocked text' };
	throws_ok { $self->_croak('k', { a => 1 }) } qr/\Amocked text at /, 'message comes from i18n';
	is_deeply($asked[0], ['k', { a => 1 }], 'key and arguments passed on');
	restore_all();
};

# ===========================================================================
# Hostile environments and limits
# ===========================================================================

subtest '_entry: parts that cannot be rendered do not break logging' => sub {
	{
		package Local::TieBomb;
		sub TIEHASH { return bless {}, shift }
		sub FETCH { die "fetch exploded\n" }
		sub FIRSTKEY { die "keys exploded\n" }
		sub TIEARRAY { return bless {}, shift }
		sub FETCHSIZE { die "size exploded\n" }
	}
	tie my %hash, 'Local::TieBomb';
	tie my @array, 'Local::TieBomb';

	# lives_ok() resets $@ itself, so $@ is read inside the block
	my ($entry, $error_after);
	lives_ok {
		local $@ = $SENTINEL;
		$entry = Test::Log::Abstraction::_entry('info', ['h=', \%hash, ' a=', \@array]);
		$error_after = $@;
	} 'tied containers that die do not kill the call';
	like($entry->{'message'}, qr/\Ah=HASH\(0x[0-9a-f]+\) a=ARRAY\(0x[0-9a-f]+\)\z/, 'shown in plain form');
	is($error_after, $SENTINEL, '$@ untouched');
	untie %hash;
	untie @array;
};

subtest 'logging under hostile signal handlers' => sub {
	my $self = logger();
	my $loop = {};
	$loop->{'self'} = $loop;
	my $die_calls = 0;

	# Tests often make warnings fatal, and some install __DIE__ handlers
	# that rethrow; neither may turn a log call into a failure
	local $SIG{'__WARN__'} = sub { die "warning became fatal: @_" };
	local $SIG{'__DIE__'} = sub { $die_calls++; die "rethrown: @_" };
	lives_ok {
		$self->info(undef, bless({}, 'Local::Bomb'), bless({}, 'Local::Undef'), $loop, [undef]);
		$self->warn("x\n");
	} 'every hostile part logged';
	is($self->count(), 2, 'both calls recorded');
	ok($die_calls > 0, 'the __DIE__ handler did fire inside the module, and was contained');
	delete $loop->{'self'};
};

subtest 'level methods: resource limits' => sub {
	my $self = logger();
	$self->info((1) x $WIDE);
	is(length($self->messages()->[0]->{'message'}), $WIDE, "$WIDE arguments joined");
	$self->info('y' x $HUGE);
	is(length($self->messages()->[1]->{'message'}), $HUGE, "$HUGE-character message stored whole");
	$self->info($_) for 1 .. $WIDE;
	is($self->count(), $WIDE + 2, "$WIDE separate calls all stored");
	is($self->clear()->count(), 0, 'and all released by clear()');
};

subtest 'i18n: hostile keys and templates' => sub {
	my $loop = {};
	$loop->{'other'} = $loop;
	my $self = logger(i18n => { en => {
		undef_form => { other => undef },
		undef_top => undef,
		code => sub { 'never called' },
		loop => $loop,
		huge => { other => '%{count}d' },
	} });
	like($self->i18n([]), qr/\AARRAY\(0x[0-9a-f]+\)\z/, 'reference key gives its string form, not the reference');
	is($self->i18n('undef_form'), '', 'undefined form renders as nothing');
	is($self->i18n('undef_top'), 'undef_top', 'undefined template counts as missing');
	like($self->i18n('code'), qr/\ACODE\(0x[0-9a-f]+\)\z/, 'code template is text, never run');
	is($self->i18n('loop'), '', 'cyclic template ends');
	is($self->i18n('huge', { count => '9' x 400 }), '9' x 400, 'enormous count is shown, not converted to -1 or Inf');
	delete $loop->{'other'};
};

subtest '_emit: hostile text and failing output' => sub {
	my $self = logger();
	my @printed;
	mock 'Test::Builder::diag' => sub { push @printed, $_[1]; return 0 };
	$self->_emit(undef);
	$self->_emit('');
	restore_all();
	is_deeply(\@printed, [undef, ''], 'undef and empty passed through, without warnings');

	mock_exception 'Test::Builder::diag' => 'output closed';
	throws_ok { $self->_emit('x') } qr/output closed/, 'an output failure is not hidden';
	restore_all();
};

subtest '_format: values that only look like numbers' => sub {
	foreach my $odd ('Inf', '-Inf', 'NaN', '1e400', '-1e400') {
		foreach my $conversion (qw(d x .2f)) {
			is(Test::Log::Abstraction::_format(undef, $conversion, $odd), $odd, "%$conversion of '$odd' shown as written");
		}
	}
};

subtest '_explain: hostile entries' => sub {
	my $self = logger();
	my @lines;
	mock "${CLASS}::_emit" => sub { push @lines, $_[1]; return $_[0] };
	$self->_explain('captured', [{ level => undef, message => undef }, { level => 'x', message => 'y' x $HUGE }]);
	restore_all();
	is($lines[1], '    [undef] undef', 'undefined level and message, no warnings');
	is(length($lines[2]), length('    [x] ') + $HUGE, 'huge message listed whole');
};

subtest '_build: keeps its own copy of the options' => sub {
	my %options = (diag => 'none', lang => 'fr');
	my $self = $CLASS->new(\%options);
	$options{'lang'} = 'de';
	$options{'diag'} = 'all';
	is($self->{'options'}->{'lang'}, 'fr', 'later change to the caller hash ignored');
	is($self->new()->lang(), 'fr', 'clones use the original options');
	is_deeply($self->new()->{'diag_rule'}, {}, '... including diag');
};

# ===========================================================================
# Memory: no cycles, and loggers are freed
# ===========================================================================

# Strategy: weaken a reference and drop the strong ones; if anything inside
# the module kept the logger alive, the weak reference would survive
subtest 'memory: loggers are freed and hold no cycles' => sub {
	my $weak;
	{
		my $self = logger();
		$self->info('m', { k => [1, 2] });
		$self->like(qr/m/, 'used once before release');
		my $clone = $self->new();
		memory_cycle_ok($self, 'logger has no cycles');
		memory_cycle_ok($clone, 'clone has no cycles');
		$weak = $self;
		weaken($weak);
	}
	ok(!defined($weak), 'logger freed when it goes out of scope');

	my $loop = {};
	$loop->{'self'} = $loop;
	my $self = logger();
	$self->info($loop);
	memory_cycle_ok($self, 'logging a cyclic structure stores text, not the cycle');
	delete $loop->{'self'};
};

done_testing();
