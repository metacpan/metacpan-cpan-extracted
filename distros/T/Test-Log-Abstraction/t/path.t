#!/usr/bin/env perl

# Path-coverage tests: for every routine, one test per distinct path from
# entry to exit - every branch combination, every early return or croak,
# and every loop run zero, one and several times.  Where the result alone
# cannot show which path ran, a Test::Mockingbird spy proves it.
#
# The paths of each routine are listed in the comment above its subtest,
# as P1, P2, ...; each test's name starts with the path it takes.
#
# Path analysis found no unreachable code (the whole suite already takes
# every branch both ways).  The one loop that always ran exactly once - the
# bare block in _entry() that held local($/) - was removed, keeping its
# body; no loop runs at most once.
# This file alone reaches every statement, branch, condition and
# subroutine (Devel::Cover).
# It did find one redundant iteration: _template() searched English twice
# for an English logger; it now searches once.
#
# The paths added in 0.002.2 were mapped the same way.  The new loops run
# 0 to N times: the argument-reading loop in _entry() once per argument
# that dies plus one pass that ends it, _render()'s loops once per key or
# item, so none is marked.  No new code is unreachable.  _printable()'s
# undef branch is taken by no caller unless a stored entry was changed
# through messages(), which the POD allows, so it is kept and tested that
# way.  Mapping the fallback of the reading loop found two bugs, now fixed:
# an element of a tied array or hash whose FETCH dies has no tie object,
# so it vanished from the message and overload::StrVal(undef) warned; and
# an argument such as substr($s, 10), evaluated only when read, warned at
# the module's line.

use strict;
use warnings;

use lib 't/lib';
use Test::Most;
use Test::Warnings qw(warning);
use Test::Mockingbird;
use Test::Returns;
use Readonly;
use Encode ();
use Config;
use Capture qw(failing printed);

use Test::Log::Abstraction;

Readonly::Scalar my $CLASS => 'Test::Log::Abstraction';
Readonly::Scalar my $FILE => __FILE__;
Readonly::Scalar my $MAX_LISTED => 20;
Readonly::Scalar my $MAX_REASON => 200;
Readonly::Scalar my $DEFAULT_LEVEL => 7;	# trace
Readonly::Scalar my $ERROR => 3;
Readonly::Scalar my $LOCALE => 'fr_FR.UTF-8';
Readonly::Scalar my $IV_BYTES => 8;	# the integer limits below are for 64-bit integers
Readonly::Scalar my $INT_MAX => '9223372036854775807';
Readonly::Scalar my $ABOVE_INT_MAX => '9223372036854775808';
Readonly::Scalar my $UINT_MAX => '18446744073709551615';
Readonly::Scalar my $ABOVE_UINT_MAX => '18446744073709551616';

{
	package Local::Sub;
	our @ISA = ('Test::Log::Abstraction');

	package Local::Other;
	sub new { return bless {}, shift }

	package Local::Bomb;
	use overload '""' => sub { die "boom\n" }, fallback => 1;
}

sub quiet {
	return $CLASS->new(diag => 'none', verbose => 0, @_);
}

sub at_caller {
	my $text = shift;

	return qr/\A\Q$CLASS: $text\E at \Q$FILE\E line \d+\.?\n?\z/;
}

# How many times a spied routine was called while running a block
sub calls_to {
	my ($routine, $code) = @_;

	my $spy = spy "${CLASS}::$routine";
	$code->();
	my $count = scalar(my @calls = $spy->());
	restore_all();
	return $count;
}

# ===========================================================================
# Construction
# ===========================================================================

# new: P1 object -> _clone.  P2 class name -> _build with it.  P3 defined
# non-class -> pushed back as an option.  P4 undef -> nothing pushed back.
subtest 'new: 4 paths' => sub {
	my $object = quiet();
	is(calls_to('_clone', sub { $object->new() }), 1, 'P1 object: cloned');
	isa_ok(Test::Log::Abstraction::new('Local::Sub', diag => 'none'), 'Local::Sub', 'P2 class name: used as the class');
	is(Test::Log::Abstraction::new(lang => 'de', diag => 'none')->lang(), 'de', 'P3 not a class: first option kept');
	is(ref(Test::Log::Abstraction::new()), $CLASS, 'P4 undef: this class, no extra option');
};

# _args: P1 one hash.  P2 even list, keys defined.  P3 even list, a key
# undefined.  P4 odd list.  P5 empty.  P6 Params::Get returns nothing.
subtest '_args: 6 paths' => sub {
	is_deeply(Test::Log::Abstraction::_args([{ a => 1 }]), { a => 1 }, 'P1 one hash');
	is_deeply(Test::Log::Abstraction::_args([a => 1]), { a => 1 }, 'P2 even list');
	is_deeply(Test::Log::Abstraction::_args([undef, 1]), {}, 'P3 undefined key');
	is_deeply(Test::Log::Abstraction::_args([1, 2, 3]), {}, 'P4 odd list');
	is_deeply(Test::Log::Abstraction::_args([]), {}, 'P5 empty');
	mock_return "Params::Get::get_params" => undef;
	is_deeply(Test::Log::Abstraction::_args([a => 1]), {}, 'P6 Params::Get returns undef');
	restore_all();
};

# _build: P1 defaults.  P2 diag list copied.  P3 i18n copied.  P4 verbose
# given.  P5 level unknown -> croak.  P6 validation fails -> croak.
subtest '_build: 6 paths' => sub {
	local @ENV{qw(TEST_VERBOSE VERBOSE)} = (0, 0);
	my $self = Test::Log::Abstraction::_build($CLASS, {}, []);
	is_deeply([@{$self}{qw(verbose level lang)}], [0, $DEFAULT_LEVEL, 'en'], 'P1 defaults');
	my @diag = ('error');
	isnt(Test::Log::Abstraction::_build($CLASS, { diag => \@diag }, [])->{'options'}->{'diag'}, \@diag, 'P2 diag list: a copy');
	my %i18n = (en => {});
	isnt(Test::Log::Abstraction::_build($CLASS, { i18n => \%i18n }, [])->{'options'}->{'i18n'}, \%i18n, 'P3 i18n: a copy');
	is(Test::Log::Abstraction::_build($CLASS, { verbose => 'yes' }, [])->{'verbose'}, 1, 'P4 verbose given: normalised');
	throws_ok { Test::Log::Abstraction::_build($CLASS, { level => 'loud' }, []) } at_caller(q{invalid syslog level 'loud'}), 'P5 unknown level';
	throws_ok { Test::Log::Abstraction::_build($CLASS, { country => 'XYZ' }, []) } qr/\A\Q$CLASS: invalid argument: \E/, 'P6 invalid option';
	is(Test::Log::Abstraction::_build($CLASS, { level => 'ERROR' }, [])->{'level'}, $ERROR, 'P7 level given: looked up in lower case');
	{
		local $Test::Log::Abstraction::config{'level'} = undef;
		throws_ok { Test::Log::Abstraction::_build($CLASS, {}, []) } at_caller(q{invalid syslog level 'undef'}), 'P8 no level and no default: croak, named undef';
	}
};

# _copy_tree: P1 not a structure.  P2 hash.  P3 array.  P4 back-reference.
subtest '_copy_tree: 4 paths' => sub {
	is(Test::Log::Abstraction::_copy_tree('s', {}), 's', 'P1 plain value: as it is');
	my $hash = { a => 1 };
	my $copy = Test::Log::Abstraction::_copy_tree($hash, {});
	ok(($copy ne $hash) && ($copy->{'a'} == 1), 'P2 hash: copied');
	my $array = [1];
	is_deeply(Test::Log::Abstraction::_copy_tree($array, {}), [1], 'P3 array: copied');
	my $loop = {};
	$loop->{'self'} = $loop;
	is_deeply(Test::Log::Abstraction::_copy_tree($loop, {}), { self => undef }, 'P4 back-reference: cut');
	delete $loop->{'self'};
};

# _clone: verbose overridden or not x level overridden or not.
subtest '_clone: 4 paths' => sub {
	my $original = quiet();
	$original->verbose(1);
	$original->level('alert');
	my %rows = ('00' => [1, 1], '10' => [0, 1], '01' => [1, $ERROR], '11' => [0, $ERROR]);
	foreach my $key (sort keys %rows) {
		my ($v, $l) = split(//, $key);
		my $clone = Test::Log::Abstraction::_clone($original, { ($v ? (verbose => 0) : ()), ($l ? (level => 'error') : ()) });
		is_deeply([$clone->verbose(), $clone->level()], $rows{$key}, "P verbose-override=$v level-override=$l");
	}
};

# _validate: P1 valid.  P2 invalid -> croak.  P3 validator returns nothing.
subtest '_validate: 3 paths' => sub {
	my $schema = { a => { type => 'string' } };
	is_deeply(Test::Log::Abstraction::_validate($CLASS, $schema, { a => 'x' }), { a => 'x' }, 'P1 valid');
	throws_ok { Test::Log::Abstraction::_validate($CLASS, $schema, { a => [] }) } qr/\A\Q$CLASS: invalid argument: Parameter 'a'\E/, 'P2 invalid';
	mock_return "Params::Validate::Strict::validate_strict" => undef;
	is_deeply(Test::Log::Abstraction::_validate($CLASS, $schema, {}), {}, 'P3 nothing returned');
	restore_all();
};

# _reason: P1 undef.  P2 trailing location removed.  P3 this file's
# location removed mid-text.  P4 control character escaped.  P5 short:
# kept.  P6 long: cut.
subtest '_reason: 6 paths' => sub {
	my $here = 'lib/Test/Log/Abstraction.pm';
	is(Test::Log::Abstraction::_reason(undef), '', 'P1 undef');
	is(Test::Log::Abstraction::_reason("bad at x line 1.\n"), 'bad', 'P2 trailing location');
	like(Test::Log::Abstraction::_reason("a at ${\ $INC{'Test/Log/Abstraction.pm'}} line 9. b"), qr/\Aa b\z/, 'P3 location in this file, mid-text');
	is(Test::Log::Abstraction::_reason("a\nb"), 'a\x0Ab', 'P4 control character');
	is(Test::Log::Abstraction::_reason('x' x $MAX_REASON), 'x' x $MAX_REASON, 'P5 at the limit: kept');
	is(Test::Log::Abstraction::_reason('x' x ($MAX_REASON + 1)), ('x' x $MAX_REASON) . '...', 'P6 over the limit: cut');
};

# _resolve_lang: P1 lang code.  P2 country mapped.  P3 country unmapped.
# P4 auto, locale set.  P5 auto, no locale.  P6 default.  P7 unknown code
# -> English.  P8 code known only from the i18n option.
subtest '_resolve_lang: 8 paths' => sub {
	local @ENV{qw(LC_ALL LC_MESSAGES LANG)};
	delete @ENV{qw(LC_ALL LC_MESSAGES LANG)};
	is(Test::Log::Abstraction::_resolve_lang({ lang => 'fr' }), 'fr', 'P1 lang code');
	is(Test::Log::Abstraction::_resolve_lang({ country => 'DE' }), 'de', 'P2 country mapped');
	is(Test::Log::Abstraction::_resolve_lang({ country => 'JP' }), 'en', 'P3 country unmapped');
	{
		local $ENV{'LC_ALL'} = $LOCALE;
		is(Test::Log::Abstraction::_resolve_lang({ lang => 'auto' }), 'fr', 'P4 auto, locale set');
	}
	is(Test::Log::Abstraction::_resolve_lang({ lang => 'auto' }), 'en', 'P5 auto, no locale');
	is(Test::Log::Abstraction::_resolve_lang({}), 'en', 'P6 the default');
	is(Test::Log::Abstraction::_resolve_lang({ lang => 'ja' }), 'en', 'P7 no catalogue: English');
	is(Test::Log::Abstraction::_resolve_lang({ lang => 'xx', i18n => { xx => {} } }), 'xx', 'P8 catalogue from the i18n option');
};

# _diag_rule: list loop run 0, 1 and 2 times; a bad element (croak in the
# loop); a non-list reference; 'none'; 'all'; a level; anything else;
# undef, taking the default; undef with no default (croak).
subtest '_diag_rule: 11 paths' => sub {
	my $self = quiet();
	is_deeply($self->_diag_rule([]), { levels => {} }, 'P1 list, loop runs 0 times');
	is_deeply($self->_diag_rule(['info']), { levels => { info => 1 } }, 'P2 list, loop runs once');
	is_deeply($self->_diag_rule(['info', 'error']), { levels => { info => 1, error => 1 } }, 'P3 list, loop runs twice');
	throws_ok { $self->_diag_rule(['info', 'bad']) } at_caller(q{invalid diag level 'bad'}), 'P4 list, croak on the second pass';
	throws_ok { $self->_diag_rule({}) } at_caller('diag must be a level name, "all", "none" or an array reference of level names'), 'P5 other reference';
	is_deeply($self->_diag_rule('none'), {}, "P6 'none'");
	is_deeply($self->_diag_rule('all'), { all => 1 }, "P7 'all'");
	is_deeply($self->_diag_rule('error'), { threshold => $ERROR }, 'P8 level name');
	throws_ok { $self->_diag_rule('bad') } at_caller(q{invalid diag level 'bad'}), 'P9 anything else';
	{
		local $Test::Log::Abstraction::config{'diag'} = 'error';
		is_deeply($self->_diag_rule(undef), { threshold => $ERROR }, 'P10 undef: the default');
		$Test::Log::Abstraction::config{'diag'} = undef;
		throws_ok { $self->_diag_rule(undef) } at_caller(q{invalid diag level 'undef'}), 'P11 undef with no default: croak';
	}
};

# _diag_level: P1 a level name.  P2 any other text -> croak.  P3 undef ->
# croak, named undef.  P4 an object whose text form dies -> croak, plain form.
subtest '_diag_level: 4 paths' => sub {
	my $self = quiet();
	is($self->_diag_level('ERROR'), 'error', 'P1 level name: lower case');
	throws_ok { $self->_diag_level('bad') } at_caller(q{invalid diag level 'bad'}), 'P2 other text';
	throws_ok { $self->_diag_level(undef) } at_caller(q{invalid diag level 'undef'}), 'P3 undef';
	throws_ok { $self->_diag_level(bless({}, 'Local::Bomb')) } qr/\A\Q$CLASS: invalid diag level 'Local::Bomb=HASH(0x\E[0-9a-f]+\)'/, 'P4 dying text form: plain form';
};

# _string: P1 not a reference.  P2 a reference that stringifies.  P3 a
# reference whose text form dies -> plain form.
subtest '_string: 3 paths' => sub {
	is(Test::Log::Abstraction::_string(42), '42', 'P1 plain value');
	like(Test::Log::Abstraction::_string([]), qr/\AARRAY\(0x[0-9a-f]+\)\z/, 'P2 reference');
	like(Test::Log::Abstraction::_string(bless({}, 'Local::Bomb')), qr/\ALocal::Bomb=HASH\(0x[0-9a-f]+\)\z/, 'P3 dying text form');
};

# _shown: undef or a value (2) x byte or character string, which decides
# whether the C1 step runs (2) x cut or not (2).  undef is short ASCII, so
# it takes one combination: 5 paths.  P6: a bidi control, which only a
# character string can hold, is escaped as \x{HHHH}.
subtest '_shown: 6 paths' => sub {
	is(Test::Log::Abstraction::_shown(undef), 'undef', 'P1 undef');
	my $bytes = "a\x{9b}";
	utf8::downgrade($bytes);
	is(Test::Log::Abstraction::_shown($bytes), $bytes, 'P2 byte string, short: the C1 step is skipped');
	my $characters = "a\x{9b}";
	utf8::upgrade($characters);
	is(Test::Log::Abstraction::_shown($characters), 'a\x9B', 'P3 character string, short: C1 escaped');
	is(Test::Log::Abstraction::_shown('x' x ($MAX_REASON + 1)), ('x' x $MAX_REASON) . '...', 'P4 byte string, long: cut');
	my $long = "\x{263a}" x ($MAX_REASON + 1);
	is(Test::Log::Abstraction::_shown($long), ("\x{263a}" x $MAX_REASON) . '...', 'P5 character string, long: cut in characters');
	is(Test::Log::Abstraction::_shown("a\x{202E}b"), 'a\x{202E}b', 'P6 a bidi control: escaped as \x{HHHH}');
};

# ===========================================================================
# Logging
# ===========================================================================

# Level methods: P1 a logger -> _record.  P2 anything else -> croak.
# is_*: P1 on.  P2 off.  P3 not a logger -> croak.
subtest 'level methods and is_*: their paths' => sub {
	my $logger = quiet();
	is(calls_to('_record', sub { $logger->warn('x') }), 1, 'level P1 logger: recorded');
	throws_ok { $CLASS->warn('x') } at_caller('warn() must be called on an object, not on the class'), 'level P2 not a logger';
	$logger->level('error');
	is($logger->is_error(), 1, 'is_* P1 on');
	is($logger->is_warn(), 0, 'is_* P2 off');
	throws_ok { $CLASS->is_warn() } at_caller('is_warn() must be called on an object, not on the class'), 'is_* P3 not a logger';
};

# _object: P1 logger.  P2 class-name string.  P3 anything else.
subtest '_object: 3 paths' => sub {
	my $logger = quiet();
	is(Test::Log::Abstraction::_object($logger, 'm'), $logger, 'P1 logger');
	throws_ok { Test::Log::Abstraction::_object('Local::Sub', 'm') } qr/\ALocal::Sub: m\(\) must be called/, 'P2 class name: named in the error';
	throws_ok { Test::Log::Abstraction::_object(Local::Other->new(), 'm') } at_caller('m() must be called on an object, not on the class'), 'P3 other';
};

# _record: P1 printed.  P2 not printed.
subtest '_record: 2 paths' => sub {
	my $logger = quiet();
	is(calls_to('_emit', sub { $logger->verbose(1); printed { $logger->_record('info', ['x']) } }), 1, 'P1 printed');
	is(calls_to('_emit', sub { $logger->verbose(0); $logger->_record('info', ['x']) }), 0, 'P2 not printed');
};

# _entry: fields (non-empty, empty, none) x lone array or not x a part
# that cannot be rendered x newline removed or not.
subtest '_entry: 7 paths' => sub {
	is_deeply(Test::Log::Abstraction::_entry('i', ['m', { k => 1 }]), { level => 'i', message => 'm', fields => { k => 1 } }, 'P1 non-empty fields');
	is_deeply(Test::Log::Abstraction::_entry('i', ['m', {}]), { level => 'i', message => 'm' }, 'P2 empty fields dropped');
	is_deeply(Test::Log::Abstraction::_entry('i', ['m']), { level => 'i', message => 'm' }, 'P3 no fields');
	is(Test::Log::Abstraction::_entry('i', [['a', 'b']])->{'message'}, 'ab', 'P4 lone array: parts');
	{
		package Local::TieDie;
		sub TIEHASH { return bless {}, shift }
		sub FIRSTKEY { die "keys\n" }
	}
	tie my %bad, 'Local::TieDie';
	like(Test::Log::Abstraction::_entry('i', [\%bad])->{'message'}, qr/\AHASH\(0x/, 'P5 part cannot be rendered: plain form');
	untie %bad;
	is(Test::Log::Abstraction::_entry('i', ["m\n"])->{'message'}, 'm', 'P6 trailing newline removed');
	is(Test::Log::Abstraction::_entry('i', ['m'])->{'message'}, 'm', 'P7 no trailing newline');
};

# _stringify: P1 undef.  P2 plain value.  P3 object.  P4 object whose ""
# dies.  P5 hash.  P6 array.  P7 back-reference.
subtest '_stringify: 7 paths' => sub {
	is(Test::Log::Abstraction::_stringify(undef, {}), 'undef', 'P1 undef');
	is(Test::Log::Abstraction::_stringify('s', {}), 's', 'P2 plain value');
	like(Test::Log::Abstraction::_stringify(Local::Other->new(), {}), qr/\ALocal::Other=HASH/, 'P3 object');
	like(Test::Log::Abstraction::_stringify(bless({}, 'Local::Bomb'), {}), qr/\ALocal::Bomb=HASH/, 'P4 dying text form');
	is(Test::Log::Abstraction::_stringify({ a => 1 }, {}), '{a => 1}', 'P5 hash');
	is(Test::Log::Abstraction::_stringify([1], {}), '[1]', 'P6 array');
	my @loop;
	push @loop, \@loop;
	is(Test::Log::Abstraction::_stringify(\@loop, {}), '[(cycle)]', 'P7 back-reference');
	@loop = ();
};

# _diags: P1 verbose.  P2 'all'.  P3 listed.  P4 threshold met.  P5 none
# (short-circuit order: each path stops at its first true reason).
subtest '_diags: 5 paths' => sub {
	my $self = quiet();
	my @rows = ([1, {}, 1, 'P1 verbose'], [0, { all => 1 }, 1, "P2 'all'"], [0, { levels => { info => 1 } }, 1, 'P3 listed'], [0, { threshold => $DEFAULT_LEVEL }, 1, 'P4 threshold met'], [0, {}, 0, 'P5 none']);
	foreach my $row (@rows) {
		@{$self}{qw(verbose diag_rule)} = @{$row}[0, 1];
		is($self->_diags('info'), $row->[2], $row->[3]);
	}
};

# AUTOLOAD: P1 logger.  P2 not a logger -> croak.
subtest 'AUTOLOAD: 2 paths' => sub {
	my $logger = quiet();
	my $out = printed { $logger->wran('x') };
	is($out, "# $CLASS: no method 'wran'\n", 'P1 logger: stored and announced');
	throws_ok { $CLASS->wran('x') } at_caller('wran() must be called on an object, not on the class'), 'P2 not a logger';
};

# ===========================================================================
# Inspection
# ===========================================================================

# Each of messages, clear, flush, reopen, lang: P1 logger.  P2 not a logger.
# count: P1 no level.  P2 a level.  P3 invalid level.  P4 not a logger.
# verbose: P1 get.  P2 set.  level: P1 get.  P2 set.  P3 warn.
subtest 'messages, clear, flush, reopen, lang, count, verbose, level: every path' => sub {
	my $logger = quiet();
	$logger->info('x');
	returns_ok($logger->messages(), { type => 'arrayref' }, 'messages P1');
	returns_ok($logger->clear(), { type => 'object', isa => $CLASS }, 'clear P1');
	returns_ok($logger->flush(), { type => 'object', isa => $CLASS }, 'flush P1');
	returns_ok($logger->reopen(), { type => 'object', isa => $CLASS }, 'reopen P1');
	returns_ok($logger->lang(), { type => 'string' }, 'lang P1');
	foreach my $method (qw(messages clear flush reopen lang count verbose level)) {
		throws_ok { $CLASS->$method() } at_caller("$method() must be called on an object, not on the class"), "$method: not a logger";
	}
	$logger->info('x');
	is($logger->count(), 1, 'count P1 no level');
	is($logger->count('info'), 1, 'count P2 a level');
	throws_ok { $logger->count([]) } at_caller(q{invalid argument: Parameter 'level' must be a string}), 'count P3 invalid';
	is($logger->verbose(), 0, 'verbose P1 get');
	is($logger->verbose(1), 1, 'verbose P2 set');
	is($logger->level(), $DEFAULT_LEVEL, 'level P1 get');
	is($logger->level('error'), $logger, 'level P2 set');
	my $result = 'unset';
	like(warning { $result = $logger->level('bad') }, at_caller(q{invalid syslog level 'bad'}), 'level P3 warn');
	ok(!defined($result), 'level P3 returns undef');
};

# ===========================================================================
# Assertions
# ===========================================================================

# like/unlike: P1 not a logger.  P2 no pattern.  P3 invalid argument.
# P4 pattern does not compile.  P5 pass.  P6 fail.
# has_level: P1 not a logger.  P2 no level.  P3 invalid.  P4 pass.  P5 fail.
# empty: P1 not a logger.  P2 invalid name.  P3 pass.  P4 fail.
subtest 'like, unlike, has_level, empty: every path' => sub {
	my $logger = quiet();
	$logger->info('x');
	foreach my $method (qw(like unlike)) {
		throws_ok { $CLASS->$method(qr/x/) } at_caller("$method() must be called on an object, not on the class"), "$method P1";
		throws_ok { $logger->$method() } at_caller("$method() needs a pattern"), "$method P2";
		throws_ok { $logger->$method([]) } at_caller(q{invalid argument: Parameter 'pattern' must be one of regex, string}), "$method P3";
		throws_ok { $logger->$method('(') } qr/\A\Q$CLASS: invalid argument: Unmatched (\E/, "$method P4";
	}
	ok($logger->like(qr/x/, 'like P5 pass'), 'like P5');
	ok(!(failing(sub { $logger->like(qr/y/) }))[0], 'like P6 fail');
	ok($logger->unlike(qr/y/, 'unlike P5 pass'), 'unlike P5');
	ok(!(failing(sub { $logger->unlike(qr/x/) }))[0], 'unlike P6 fail');

	throws_ok { $CLASS->has_level('info') } at_caller('has_level() must be called on an object, not on the class'), 'has_level P1';
	throws_ok { $logger->has_level() } at_caller('has_level() needs a level name'), 'has_level P2';
	throws_ok { $logger->has_level({}) } at_caller(q{invalid argument: Parameter 'level' must be a string}), 'has_level P3';
	ok($logger->has_level('info', 'has_level P4 pass'), 'has_level P4');
	ok(!(failing(sub { $logger->has_level('error') }))[0], 'has_level P5 fail');

	throws_ok { $CLASS->empty() } at_caller('empty() must be called on an object, not on the class'), 'empty P1';
	throws_ok { $logger->empty([]) } at_caller(q{invalid argument: Parameter 'name' must be a string}), 'empty P2';
	ok(!(failing(sub { $logger->empty() }))[0], 'empty P4 fail');
	ok($logger->clear()->empty('empty P3 pass'), 'empty P3');
};

# _assert: P1 pass, nothing explained.  P2 fail, explained.
# _explain: listing loop run 0 times, once, up to the limit (no summary)
# and past it (summary).
subtest '_assert and _explain: every path' => sub {
	my $logger = quiet();
	$logger->info('present');
	is(calls_to('_explain', sub { $logger->like(qr/present/, '_assert P1 pass') }), 0, '_assert P1 pass: no explanation');
	is(calls_to('_explain', sub { failing(sub { $logger->like(qr/never/) }) }), 1, '_assert P2 fail: explained');

	my @lines;
	mock "${CLASS}::_emit" => sub { push @lines, $_[1]; return $_[0] };
	my %runs = (0 => 1, 1 => 2, $MAX_LISTED => $MAX_LISTED + 1, $MAX_LISTED + 1 => $MAX_LISTED + 2);
	my %got;
	foreach my $count (keys %runs) {
		@lines = ();
		$logger->_explain('captured', [map { { level => 'i', message => $_ } } 1 .. $count]);
		$got{$count} = scalar(@lines);
	}
	restore_all();
	is($got{0}, 1, '_explain loop 0 times: heading only');
	is($got{1}, 2, '_explain loop once');
	is($got{$MAX_LISTED}, $MAX_LISTED + 1, '_explain loop to the limit: no summary');
	is($got{$MAX_LISTED + 1}, $MAX_LISTED + 2, '_explain past the limit: summary');
};

# _matching: P1 compiles.  P2 does not.  _at_level: one path.
subtest '_matching and _at_level: every path' => sub {
	my $logger = quiet();
	$logger->info('apple');
	is(scalar(@{$logger->_matching('app')}), 1, '_matching P1 compiles');
	throws_ok { $logger->_matching('[') } qr/\A\Q$CLASS: invalid argument: Unmatched [\E/, '_matching P2 does not compile';
	is(scalar(@{$logger->_at_level('INFO')}), 1, '_at_level P1');
};

# ===========================================================================
# Output and messages
# ===========================================================================

# _emit: TODO or not x handle defined or not x encoded or not.
subtest '_emit: 5 paths' => sub {
	my $logger = quiet();
	my (@printed, $todo_used);
	mock 'Test::Builder::diag' => sub { push @printed, $_[1]; return 1 };
	$logger->_emit("\x{2603}");
	$logger->_emit('bytes');
	mock 'PerlIO::get_layers' => sub { ('utf8') };
	$logger->_emit("\x{2603}");
	unmock 'PerlIO::get_layers';
	mock 'Test::Builder::failure_output' => sub { undef };
	$logger->_emit("\x{2603}");
	unmock 'Test::Builder::failure_output';
	mock 'Test::Builder::in_todo' => sub { 1 };
	mock 'Test::Builder::todo_output' => sub { $todo_used++; \*STDERR };
	$logger->_emit('t');
	restore_all();
	is($printed[0], "\xe2\x98\x83", 'P1 characters, no layer: encoded');
	is($printed[1], 'bytes', 'P2 bytes: as they are');
	is($printed[2], "\x{2603}", 'P3 layer present: not encoded');
	is($printed[3], "\xe2\x98\x83", 'P4 no handle: encoded');
	is($todo_used, 1, 'P5 inside TODO: the TODO handle is examined');
};

# i18n: P1 found.  P2 not found -> key.  P3 key undefined.  P4 arguments
# not a hash.  P5 called on a class.
subtest 'i18n: 5 paths' => sub {
	my $logger = quiet();
	is($logger->i18n('no_method', { method => 'm' }), "$CLASS: no method 'm'", 'P1 found');
	is($logger->i18n('nope'), 'nope', 'P2 not found: the key');
	is($logger->i18n(undef), '', 'P3 undefined key');
	is($logger->i18n('no_method', 'x'), "$CLASS: no method 'undef'", 'P4 arguments not a hash');
	is($CLASS->i18n('no_method', { method => 'm' }), "$CLASS: no method 'm'", 'P5 class');
};

# _template: language override, language built-in, English override,
# English built-in, nothing; a table that is not a hash is skipped; an
# English logger searches once.
subtest '_template: 7 paths' => sub {
	my $logger = quiet(lang => 'de', i18n => { de => { a => 'de override' }, en => { b => 'en override' } });
	is($logger->_template('de', 'a'), 'de override', 'P1 language override');
	like($logger->_template('de', 'needs_pattern'), qr/Muster/, 'P2 language built-in');
	is($logger->_template('de', 'b'), 'en override', 'P3 English override');
	is($logger->_template('de', 'entry'), '    [%{level}s] %{message}s', 'P4 English built-in');
	is($logger->_template('de', 'nothing'), undef, 'P5 not found');
	is(quiet(i18n => { en => 'not a table' })->_template('en', 'no_method'), q{%{class}s: no method '%{method}s'}, 'P6 non-hash table skipped');

	# P7: the language is English; record each table lookup to count passes
	my $lookups = 0;
	{
		package Local::Counting;
		sub TIEHASH { my ($class, $count) = @_; return bless { count => $count, data => {} }, $class }
		sub FETCH { my ($self, $key) = @_; return $self->{'data'}->{$key} }
		sub EXISTS { my ($self, $key) = @_; ${$self->{'count'}}++; return exists($self->{'data'}->{$key}) }
	}
	tie my %overrides, 'Local::Counting', \$lookups;
	my $english = quiet();
	$english->{'options'}->{'i18n'} = \%overrides;
	$english->_template('en', 'nothing');
	is($lookups, 1, 'P7 English logger: the overrides are searched once, not twice');
	untie %overrides;
};

# _variant: P1 a string.  P2 gender.  P3 plural.  P4 cycle.  P5 undefined form.
subtest '_variant: 5 paths' => sub {
	is(Test::Log::Abstraction::_variant('s', {}, 'en'), 's', 'P1 string: loop runs 0 times');
	is(Test::Log::Abstraction::_variant({ female => 'f', other => 'o' }, { gender => 'female' }, 'en'), 'f', 'P2 gender');
	is(Test::Log::Abstraction::_variant({ one => '1', other => 'n' }, { count => 1 }, 'en'), '1', 'P3 plural');
	my $loop = {};
	$loop->{'other'} = $loop;
	is(Test::Log::Abstraction::_variant($loop, {}, 'en'), '', 'P4 cycle');
	delete $loop->{'other'};
	is(Test::Log::Abstraction::_variant({ other => undef }, {}, 'en'), '', 'P5 undefined form');
};

# _plural: P1 not numeric.  P2 zero form.  P3 category exists.  P4 category
# missing -> other.  P5 unknown language -> English rule.
subtest '_plural: 5 paths' => sub {
	is(Test::Log::Abstraction::_plural({ one => 1, other => 1 }, 'x', 'en'), 'other', 'P1 not numeric');
	is(Test::Log::Abstraction::_plural({ zero => 1, other => 1 }, 0, 'en'), 'zero', 'P2 zero form');
	is(Test::Log::Abstraction::_plural({ one => 1, other => 1 }, 1, 'en'), 'one', 'P3 category exists');
	is(Test::Log::Abstraction::_plural({ other => 1 }, 1, 'en'), 'other', 'P4 category missing');
	is(Test::Log::Abstraction::_plural({ one => 1, other => 1 }, 1, 'qq'), 'one', 'P5 unknown language');
};

# _interpolate: P1 ASCII, no placeholders.  P2 non-ASCII template.  P3 %%.
# P4 placeholder.  _format: P1 '%'.  P2 undef.  P3 number.  P4 %s.
# P5 not a number for %d.  P6 text form dies.
subtest '_interpolate and _format: every path' => sub {
	is(Test::Log::Abstraction::_interpolate('plain', {}), 'plain', '_interpolate P1');
	ok(utf8::is_utf8(Test::Log::Abstraction::_interpolate("caf\x{e9}", {})), '_interpolate P2 non-ASCII: characters');
	is(Test::Log::Abstraction::_interpolate('100%%', {}), '100%', '_interpolate P3 %%');
	is(Test::Log::Abstraction::_interpolate('%{a}s', { a => 'x' }), 'x', '_interpolate P4 placeholder');
	is(Test::Log::Abstraction::_format('%', 's', 'x'), '%', '_format P1');
	is(Test::Log::Abstraction::_format(undef, 's', undef), 'undef', '_format P2');
	is(Test::Log::Abstraction::_format(undef, 'd', 7), '7', '_format P3 number');
	is(Test::Log::Abstraction::_format(undef, 's', 'x'), 'x', '_format P4 %s');
	is(Test::Log::Abstraction::_format(undef, 'd', 'x'), 'x', '_format P5 not a number');
	like(Test::Log::Abstraction::_format(undef, 's', bless({}, 'Local::Bomb')), qr/\ALocal::Bomb=HASH/, '_format P6 text form dies');
};

# _format, integer conversions of a number: read as signed (%d, or any
# negative) or unsigned (%u of a non-negative) x a digit string or a float
# x fits or not; and a digit string's sign, which '-0' drops.
#   P1 signed, digits, fits.        P2 signed, digits, too big.
#   P3 unsigned, digits, fits.      P4 unsigned, digits, too big.
#   P5 negative, unsigned format: read as signed.   P6 float, fits.
#   P7 float, too big.
#   P8 '-0': the minus sign is dropped before comparing.
subtest '_format: integer conversion paths' => sub {
	plan(skip_all => 'the limits are for 64-bit integers') if($Config{'ivsize'} < $IV_BYTES);
	is(Test::Log::Abstraction::_format(undef, 'd', $INT_MAX), $INT_MAX, 'P1 signed, digits, fits');
	is(Test::Log::Abstraction::_format(undef, 'd', $ABOVE_INT_MAX), $ABOVE_INT_MAX, 'P2 signed, digits, too big: as written');
	is(Test::Log::Abstraction::_format(undef, 'u', $UINT_MAX), $UINT_MAX, 'P3 unsigned, digits, fits');
	is(Test::Log::Abstraction::_format(undef, 'u', $ABOVE_UINT_MAX), $ABOVE_UINT_MAX, 'P4 unsigned, digits, too big: as written');
	is(Test::Log::Abstraction::_format(undef, 'x', '-1'), 'f' x 16, 'P5 negative under %x: read as signed, printed in two\'s complement');
	is(Test::Log::Abstraction::_format(undef, 'd', 2.5), '2', 'P6 float that fits: formatted');
	my $huge = 1e30;
	is(Test::Log::Abstraction::_format(undef, 'd', $huge), "$huge", 'P7 float too big: as written');
	is(Test::Log::Abstraction::_format(undef, 'd', '-0'), '0', "P8 '-0': 0");
};

# ===========================================================================
# Paths that only the rest of the suite took.  This file claims to reach
# every statement, branch and condition on its own, so each is taken here.
# ===========================================================================

# _build verbose: P1 option given.  P2 TEST_VERBOSE set.  P3 only VERBOSE
# set.  P4 neither.
subtest '_build: verbose, 4 paths' => sub {
	foreach my $row ([{ verbose => 0 }, 1, 1, 0, 'P1 option given: it decides'], [{}, 1, 0, 1, 'P2 TEST_VERBOSE'], [{}, 0, 1, 1, 'P3 VERBOSE only'], [{}, 0, 0, 0, 'P4 neither']) {
		my ($options, $test_verbose, $verbose, $want, $name) = @{$row};
		local $ENV{'TEST_VERBOSE'} = $test_verbose;
		local $ENV{'VERBOSE'} = $verbose;
		is(Test::Log::Abstraction::_build($CLASS, { %{$options}, diag => 'none' }, [])->{'verbose'}, $want, $name);
	}
};

# _clone's copy loop: P1 no messages (0 runs).  P2 one entry without
# fields.  P3 one with fields, which are copied too.
subtest '_clone: copy loop, 3 paths' => sub {
	my $logger = quiet();
	is_deeply($logger->new()->messages(), [], 'P1 nothing to copy');
	$logger->info('plain');
	is_deeply($logger->new()->messages(), [{ level => 'info', message => 'plain' }], 'P2 entry without fields');
	$logger->info('m', { k => 1 });
	my $clone = $logger->new();
	is_deeply($clone->messages()->[-1]->{'fields'}, { k => 1 }, 'P3 entry with fields: copied');
	isnt($clone->messages()->[-1]->{'fields'}, $logger->messages()->[-1]->{'fields'}, 'P3 ... into a new hash');
};

# _resolve_lang: P9 no lang and an undefined default -> English.
subtest '_resolve_lang: undefined default' => sub {
	local $Test::Log::Abstraction::config{'lang'} = undef;
	is(Test::Log::Abstraction::_resolve_lang({}), 'en', 'P9 nothing to go on: English');
};

# Level methods: P3 warn or more serious, no arguments -> ignored.  P4 less
# serious, no arguments -> an empty message.
subtest 'level methods: calls with no arguments' => sub {
	my $logger = quiet();
	is(calls_to('_record', sub { $logger->warn() }), 0, 'P3 warn(): ignored');
	is(calls_to('_record', sub { $logger->notice() }), 1, 'P4 notice(): recorded');
	is($logger->messages()->[0]->{'message'}, '', 'P4 ... as an empty message');
};

# _entry: P8 several arguments, the last not a hash.  P9 an undefined part.
# P10 a part that cannot be rendered at all -> plain form.  P11 trailing
# fields that cannot be copied -> put back as a part, so plain form.
# P12 a reference part that renders.
subtest '_entry: more paths' => sub {
	is(Test::Log::Abstraction::_entry('i', ['a', 'b'])->{'message'}, 'ab', 'P8 several arguments, no fields');
	is(Test::Log::Abstraction::_entry('i', ['a', undef])->{'message'}, 'aundef', 'P9 undefined part');
	tie my %broken, 'Local::DyingHash';
	like(Test::Log::Abstraction::_entry('i', ['a', \%broken, 'b'])->{'message'}, qr/\AaHASH\(0x[0-9a-f]+\)b\z/, 'P10 part that cannot be rendered: plain form');
	my $entry;
	lives_ok { $entry = Test::Log::Abstraction::_entry('i', ['a', \%broken]) } 'P11 fields that cannot be read: no death';
	like($entry->{'message'}, qr/\AaHASH\(0x[0-9a-f]+\)\z/, 'P11 ... shown as a part, in plain form');
	ok(!exists($entry->{'fields'}), 'P11 ... and not as fields');
	is(Test::Log::Abstraction::_entry('i', ['a', [1, 2]])->{'message'}, 'a[1, 2]', 'P12 a reference part that renders');
};

# _variant: P6 a gender not in the template -> plural form.  P7 the chosen
# form is missing -> ''.
# _plural: P6 count 0 with no 'zero' form.  P7 undefined language -> English.
subtest '_variant and _plural: more paths' => sub {
	is(Test::Log::Abstraction::_variant({ male => 'he', other => 'they' }, { gender => 'female' }, 'en'), 'they', '_variant P6 gender missing: plural form');
	is(Test::Log::Abstraction::_variant({ one => 'one' }, { count => 2 }, 'en'), '', '_variant P7 no such form: empty');
	is(Test::Log::Abstraction::_plural({ one => 1, other => 1 }, 0, 'en'), 'other', "_plural P6 0 with no 'zero'");
	is(Test::Log::Abstraction::_plural({ one => 1, other => 1 }, 1, undef), 'one', '_plural P7 undefined language');
};

# _format, not a finite plain number for %d: P9 a reference.  P10 NaN.
# P11 infinity.  i18n: P6 called on the class.  P7 called as a function
# with no invocant: no class to name.
subtest '_format and i18n: more paths' => sub {
	my $ref = [];
	is(Test::Log::Abstraction::_format(undef, 'd', $ref), "$ref", '_format P9 reference: as written');
	is(Test::Log::Abstraction::_format(undef, 'd', 'NaN'), 'NaN', '_format P10 NaN: as written');
	is(Test::Log::Abstraction::_format(undef, 'd', 9**9**9), 9**9**9, '_format P11 infinity: as written');
	is($CLASS->i18n('no_method', { method => 'm' }), "$CLASS: no method 'm'", 'i18n P6 called on the class');
	is(Test::Log::Abstraction::i18n('', 'no_method', { method => 'm' }), ": no method 'm'", 'i18n P7 no invocant: no class named');
};

{
	package Local::DyingHash;
	sub TIEHASH { return bless {}, shift }
	sub FIRSTKEY { die "no keys\n" }
}

# DESTROY: one path, which does nothing - in particular, it never reaches
# AUTOLOAD, so destruction stores and prints nothing
subtest 'DESTROY: 1 path' => sub {
	my $logger = quiet();
	my $out = printed { $logger->DESTROY() };
	is($out, '', 'P1 nothing printed');
	is($logger->count(), 0, 'P1 nothing stored');
};

# _croak: one path, always ending in croak.
subtest '_croak: 1 path' => sub {
	throws_ok { $CLASS->_croak('no_method', { method => 'm' }) } at_caller(q{no method 'm'}), 'P1 croak';
};

# ===========================================================================
# Paths added in 0.002.2: hostile names, references and arguments
# ===========================================================================

# A character string whose bytes are not valid UTF-8
sub malformed {
	my $text = shift;

	Encode::_utf8_on($text);
	return $text;
}

{
	package Local::DyingScalar;
	sub TIESCALAR { return bless {}, shift }
	sub FETCH { die "unreadable\n" }

	package Local::DyingElements;
	# A one-element array, and a hash, whose elements die when read
	sub TIEARRAY { return bless {}, shift }
	sub TIEHASH { return bless {}, shift }
	sub FETCHSIZE { return 1 }
	sub EXISTS { return 1 }
	sub FETCH { die "unreadable\n" }

	package Local::DyingSize;
	sub TIEARRAY { return bless {}, shift }
	sub FETCHSIZE { die "unreadable\n" }
}

# _repaired: P1 a byte string (the first test decides).  P2 a valid
# character string (the second decides).  P3 a malformed one: repaired.
subtest '_repaired: 3 paths' => sub {
	my $decodes = spy 'Encode::decode';
	is(Test::Log::Abstraction::_repaired("\xff\xfe"), "\xff\xfe", 'P1 bytes: returned as they are');
	is(Test::Log::Abstraction::_repaired("\x{263a}"), "\x{263a}", 'P2 valid characters: returned as they are');
	my $got = Test::Log::Abstraction::_repaired(malformed("\xff\xfe x"));
	my $calls = scalar(my @calls = $decodes->());
	restore_all();
	like($got, qr/\A\x{FFFD}+ x\z/, 'P3 malformed: each bad part is U+FFFD');
	is($calls, 1, 'P1 and P2 decode nothing; P3 decodes once');
};

# _lc: one path, through _repaired().
subtest '_lc: 1 path' => sub {
	is(Test::Log::Abstraction::_lc('ERROR'), 'error', 'P1 lower case');
	is(calls_to('_repaired', sub { Test::Log::Abstraction::_lc('X') }), 1, 'P1 always through _repaired()');
};

# _is_a: P1 ref() is not the type (the second test is not reached).  P2
# ref() is the type, the underlying type is not.  P3 both are.
subtest '_is_a: 3 paths' => sub {
	my $reftypes = spy 'Scalar::Util::reftype';
	ok(!Test::Log::Abstraction::_is_a([], 'HASH'), 'P1 another type: false');
	my $after_p1 = scalar(my @calls = $reftypes->());
	ok(!Test::Log::Abstraction::_is_a(bless([], 'HASH'), 'HASH'), 'P2 claims HASH, is an array: false');
	ok(Test::Log::Abstraction::_is_a({}, 'HASH'), 'P3 a hash: true');
	restore_all();
	is($after_p1, 0, 'P1 does not reach reftype()');
};

# The arguments of a call, still aliased to the caller's variables as
# @_ is: an anonymous array [...] would copy, and so read, them
sub aliased {
	return \@_;
}

# _entry, reading the arguments.  The loop runs once per argument that
# dies, plus one pass that ends it, so 0 to N times:
#   P1 no arguments: the loop runs 0 times.
#   P2 all readable: 1 pass, ending at 'last'.
#   P3 one in the middle dies: 2 passes, the second ending at 'last'.
#   P4 the last one dies: 1 pass, ending at the loop's own test.
#   P5 a tied element dies: no tie object, so a reference's plain form.
#   P6 a substr() out of range: read as undef, with no warning.
subtest '_entry: argument reads, 6 paths' => sub {
	tie my $scalar, 'Local::DyingScalar';
	tie my @array, 'Local::DyingElements';
	my $object = qr/Local::DyingScalar=HASH\(0x[0-9a-f]+\)/;
	my $string = 'ab';
	my %path = (
		'P1 no arguments' => [aliased(), qr/\A\z/, 0],
		'P2 all readable' => [aliased('a', 'b'), qr/\Aab\z/, 0],
		'P3 one in the middle dies' => [aliased('a', $scalar, 'b'), qr/\Aa${object}b\z/, 1],
		'P4 the last one dies' => [aliased('a', $scalar), qr/\Aa$object\z/, 1],
		'P5 a tied element dies' => [aliased('a', $array[0], 'b'), qr/\AaSCALAR\(0x[0-9a-f]+\)b\z/, 1],
		'P6 substr out of range' => [aliased('a', substr($string, 10, 1), 'b'), qr/\Aaundefb\z/, 0],
	);
	foreach my $name (sort keys %path) {
		my ($args, $want, $failed) = @{$path{$name}};
		my $plain = spy 'overload::StrVal';
		my $entry = Test::Log::Abstraction::_entry('i', $args);
		my $calls = scalar(my @calls = $plain->());
		restore_all();
		like($entry->{'message'}, $want, "$name: message");
		is($calls, $failed, "$name: $failed unreadable part" . (($failed == 1) ? '' : 's') . ' shown in plain form');
	}
	untie $scalar;
	untie @array;
};

# _entry, a lone array reference: P1 its parts are read.  P2 reading it
# dies (a tied array whose size dies): it stays one part.  P3 it only
# claims to be an array: it stays one part.
subtest '_entry: lone array, 3 paths' => sub {
	tie my @size, 'Local::DyingSize';
	is(Test::Log::Abstraction::_entry('i', [['a', 'b']])->{'message'}, 'ab', 'P1 parts');
	like(Test::Log::Abstraction::_entry('i', [\@size])->{'message'}, qr/\AARRAY\(0x[0-9a-f]+\)\z/, 'P2 unreadable: plain form');
	like(Test::Log::Abstraction::_entry('i', [bless({}, 'ARRAY')])->{'message'}, qr/\AARRAY=HASH\(0x[0-9a-f]+\)\z/, 'P3 claimed: plain form');
	untie @size;
};

# _render: P1 undef.  P2 a plain value.  P3 a reference that only claims
# HASH (neither test passes).  P4 a cycle.  P5 a hash with no keys (the
# loop runs 0 times).  P6 a hash with two (it runs twice: separator).
# P7 an empty array.  P8 an array with two.
subtest '_render: 8 paths' => sub {
	my @loop;
	push @loop, \@loop;
	my %path = (
		'P1 undef' => [undef, 'undef'],
		'P2 plain value' => ['v', 'v'],
		'P4 cycle' => [\@loop, '[(cycle)]'],
		'P5 empty hash' => [{}, '{}'],
		'P6 hash, two keys' => [{ a => 1, b => 2 }, '{a => 1, b => 2}'],
		'P7 empty array' => [[], '[]'],
		'P8 array, two items' => [[1, 2], '[1, 2]'],
	);
	foreach my $name (sort keys %path) {
		my ($value, $want) = @{$path{$name}};
		my $out = '';
		Test::Log::Abstraction::_render($value, {}, \$out);
		is($out, $want, $name);
	}
	my $out = 'kept|';
	Test::Log::Abstraction::_render(bless([], 'HASH'), {}, \$out);
	like($out, qr/\Akept\|HASH=ARRAY\(0x[0-9a-f]+\)\z/, 'P3 claimed type: its text, appended to what was there');
	@loop = ();
};

# _copy_tree, _build and _diag_rule with references that claim a type:
# P1 a claimed hash or array is not copied.  P2 a claimed array as diag is
# refused as a type, by _diag_rule().
subtest '_copy_tree and _diag_rule: claimed types, 2 paths' => sub {
	my $claimed = bless([], 'HASH');
	is(Test::Log::Abstraction::_copy_tree($claimed, {}), $claimed, 'P1 not copied: the same reference back');
	throws_ok { quiet(diag => bless({}, 'ARRAY')) } at_caller('diag must be a level name, "all", "none" or an array reference of level names'), 'P2 refused';
};

# _template and _resolve_lang with an i18n option that claims HASH: P1 no
# overrides are searched.  P2 the language is not taken from it.
subtest '_template and _resolve_lang: claimed option, 2 paths' => sub {
	my $logger = quiet(lang => 'xx', i18n => bless([], 'HASH'));
	is(Test::Log::Abstraction::_template($logger, 'en', 'needs_level'), Test::Log::Abstraction::_template(quiet(), 'en', 'needs_level'), 'P1 the built-in template');
	is($logger->lang(), 'en', 'P2 English');
};

# _variant with objects: P1 a gender object is used by its text.  P2 a
# template whose text form dies is shown in plain form.
subtest '_variant: object paths' => sub {
	{
		package Local::Male;
		use overload '""' => sub { 'male' }, fallback => 1;
	}
	is(Test::Log::Abstraction::_variant({ male => 'M', other => 'X' }, { gender => bless({}, 'Local::Male') }, 'en'), 'M', 'P1 gender by its text');
	like(Test::Log::Abstraction::_variant(bless({}, 'Local::Bomb'), {}, 'en'), qr/\ALocal::Bomb=HASH/, 'P2 template in plain form');
};

# _plural: a count that is a reference takes the not-numeric path
subtest '_plural: a reference count' => sub {
	is(Test::Log::Abstraction::_plural({ one => 1, other => 1 }, [1], 'en'), 'other', 'P1 not numeric: other');
};

# _regex and AUTOLOAD with malformed text: P1 a malformed pattern croaks.
# P2 a malformed method name is repaired, then stored.
subtest '_regex and AUTOLOAD: malformed text, 2 paths' => sub {
	throws_ok { quiet()->like(malformed("\xff")) } qr/\A\Q$CLASS: invalid argument: Malformed UTF-8 character\E/, 'P1 croak';
	my $logger = quiet();
	my $name = malformed("\xff x");
	is(calls_to('_repaired', sub { printed { $logger->$name() } }) >= 1 ? 1 : 0, 1, 'P2 repaired');
	like($logger->messages()->[0]->{'level'}, qr/\A\x{FFFD} x\z/, 'P2 stored repaired');
};

# _printable: P1 text.  P2 undef, which no caller passes unless a stored
# entry was changed through messages() (the POD warns against it, but it
# is possible); then a failing assertion lists it as 'undef', with no
# warning (Test::Warnings checks).  has_level() fails here because it
# lists the entries without matching their text: like() and unlike() would
# match against the undef, and warn.
subtest '_printable: 2 paths' => sub {
	is(Test::Log::Abstraction::_printable("a\eb"), 'a\x1Bb', 'P1 escaped');
	my $logger = quiet();
	$logger->info('x');
	$logger->messages()->[0]->{'message'} = undef;
	my (undef, $out) = failing(sub { $logger->has_level('nosuch') });
	like($out, qr/\[info\] undef$/m, 'P2 undef: listed as undef');
};

done_testing();
