use strict;
use warnings;
use Test::Most;
use Readonly;
use Test::Mockingbird;
use Test::Mockingbird::TimeTravel qw(
	now freeze_time travel_to advance_time rewind_time with_frozen_time
);

# Error-message constants -- eliminate magic strings in throws_ok patterns.
Readonly my $ERR_MOCK_REQ    => 'Package, method and replacement are required for mocking';
Readonly my $ERR_UNMOCK_REQ  => 'Package and method are required for unmocking';
Readonly my $ERR_SPY_REQ     => 'Package and method are required for spying';
Readonly my $ERR_INJ_REQ     => 'Package and dependency are required for injection';
Readonly my $ERR_IA_PKG      => 'inject_all requires a package name';
Readonly my $ERR_IA_HREF     => 'inject_all requires a hashref of dependencies';
Readonly my $ERR_IN_CLASS    => 'intercept_new requires a class name';
Readonly my $ERR_IN_REPL     => 'intercept_new requires a replacement object or coderef';
Readonly my $ERR_RESTORE_TGT => 'restore requires a target';
Readonly my $ERR_ACO_MIN     => 'assert_call_order requires at least two method names';
Readonly my $ERR_MS_UNRECOG  => 'mock_scoped: unrecognised argument form';
Readonly my $ERR_TT_TRAVEL   => 'travel_to() called while TimeTravel is inactive';
Readonly my $ERR_TT_ADVANCE  => 'advance_time() called while TimeTravel is inactive';
Readonly my $ERR_TT_REWIND   => 'rewind_time() called while TimeTravel is inactive';
Readonly my $ERR_TT_CODE     => 'with_frozen_time() requires a coderef';
Readonly my $ERR_TT_TS       => 'with_frozen_time() requires a timestamp';
Readonly my $ERR_TT_INVALID  => 'Invalid timestamp format for TimeTravel';
Readonly my $ERR_PROTO_NAME  => 'Invalid fully-qualified name';

Readonly my $TS_2025_JAN1    => '2025-01-01T00:00:00Z';
Readonly my $TS_2025_JUN1    => '2025-06-01T00:00:00Z';
Readonly my $TS_2025_DEC31   => '2025-12-31T00:00:00Z';

# A dummy package for testing
{
	package Edge::Target;
	sub a { 'A' }
	sub b { 'B' }
	sub c { 'C' }
}

# ------------------------------------------------------------
# 1. Mocking edge cases
# ------------------------------------------------------------

subtest 'mock(): basic sanity' => sub {
	mock 'Edge::Target::a' => sub { 'mocked' };
	is Edge::Target::a(), 'mocked', 'mock replaced method';
	restore_all();
};

subtest 'mock(): mocking a non-existent method' => sub {
	mock 'Edge::Target::does_not_exist' => sub { 'x' };
	is Edge::Target::does_not_exist(), 'x', 'mock created new method';
	restore_all();
};

subtest 'mock(): multiple layers stack correctly' => sub {
	mock 'Edge::Target::a' => sub { 'L1' };
	mock 'Edge::Target::a' => sub { 'L2' };
	is Edge::Target::a(), 'L2', 'top layer active';
	restore_all();
};

# ------------------------------------------------------------
# 2. unmock() edge cases
# ------------------------------------------------------------

subtest 'unmock(): unmocking restores previous layer' => sub {
	mock 'Edge::Target::a' => sub { 'L1' };
	mock 'Edge::Target::a' => sub { 'L2' };
	unmock 'Edge::Target::a';
	is Edge::Target::a(), 'L1', 'previous layer restored';
	restore_all();
};

subtest 'unmock(): unmocking when nothing mocked is silent' => sub {
	lives_ok { unmock 'Edge::Target::a' } 'unmock on clean method does not die';
};

# ------------------------------------------------------------
# 3. mock_scoped() edge cases
# ------------------------------------------------------------

subtest 'mock_scoped(): restores automatically on scope exit' => sub {
	{
		my $g = mock_scoped 'Edge::Target::a' => sub { 'scoped' };
		is Edge::Target::a(), 'scoped', 'scoped mock active';
	}
	is Edge::Target::a(), 'A', 'restored after scope';
};

# ------------------------------------------------------------
# 4. spy() edge cases
# ------------------------------------------------------------

subtest 'spy(): captures calls and arguments' => sub {
	my $spy = spy 'Edge::Target::b';
	Edge::Target::b('x', 'y');
	my @calls = $spy->();
	is scalar(@calls), 1, 'one call captured';
	is_deeply $calls[0], [ 'Edge::Target::b', 'x', 'y' ], 'call recorded correctly';
	restore_all();
};

subtest 'spy(): stacked spies behave correctly' => sub {
	my $s1 = spy 'Edge::Target::c';
	my $s2 = spy 'Edge::Target::c';
	Edge::Target::c('z');
	my @c1 = $s1->();
	my @c2 = $s2->();
	is scalar(@c1), 1, 'outer spy captured';
	is scalar(@c2), 1, 'inner spy captured';
	restore_all();
};

# ------------------------------------------------------------
# 5. inject() edge cases
# ------------------------------------------------------------

subtest 'inject(): injects dependency and restores' => sub {
	inject 'Edge::Target::dep' => 'MOCK';
	is Edge::Target::dep(), 'MOCK', 'injected dependency returned';
	restore_all();
};

subtest 'inject(): multiple injections stack' => sub {
	inject 'Edge::Target::dep' => 'ONE';
	inject 'Edge::Target::dep' => 'TWO';
	is Edge::Target::dep(), 'TWO', 'top injection active';
	restore_all();
};

# ------------------------------------------------------------
# 6. restore_all() edge cases
# ------------------------------------------------------------

subtest 'restore_all(): restores everything' => sub {
	mock 'Edge::Target::a' => sub { 'X' };
	mock 'Edge::Target::b' => sub { 'Y' };
	restore_all();
	is Edge::Target::a(), 'A', 'a restored';
	is Edge::Target::b(), 'B', 'b restored';
};

subtest 'restore_all(): package-specific restore' => sub {
	mock 'Edge::Target::a' => sub { 'X' };
	mock 'Other::Pkg::foo' => sub { 'Y' };
	restore_all 'Edge::Target';
	is Edge::Target::a(), 'A', 'Edge::Target restored';
	is Other::Pkg::foo(), 'Y', 'Other::Pkg untouched';
	restore_all();
};

# ------------------------------------------------------------
# 7. pathological cases
# ------------------------------------------------------------

subtest 'mock(): undef replacement is not allowed' => sub {
	dies_ok { mock 'Edge::Target::a' => undef } 'undef replacement is not allowed';
	restore_all();
};

subtest 'spy(): calling spy after restore does not explode' => sub {
	my $spy = spy 'Edge::Target::a';
	restore_all();
	lives_ok { $spy->() } 'spy->() safe after restore';
};

subtest 'restore_all(): repeated calls are safe' => sub {
	mock 'Edge::Target::a' => sub { 'X' };
	restore_all();
	lives_ok { restore_all() } 'second restore_all safe';
};

subtest 'mock_return croaks without target' => sub {
	dies_ok { mock_return undef, 1 } 'undef target croaks';
};

subtest 'mock_exception croaks without message' => sub {
	dies_ok { mock_exception 'Edge::Target::e' } 'missing message croaks';
};

subtest 'mock_sequence croaks without values' => sub {
	dies_ok { mock_sequence 'Edge::Target::f' } 'no values croaks';
};

subtest 'mock_once croaks on missing coderef' => sub {
	dies_ok { mock_once 'Edge::Target::x' => undef } 'undef coderef rejected';
};

subtest 'mock_once does not recurse' => sub {
	{
		package Edge::Target;
		sub y { return 'orig' }
	}

	mock_once 'Edge::Target::y' => sub { 'once' };
	is Edge::Target::y(), 'once', 'first call ok';
	is Edge::Target::y(), 'orig', 'no recursion after restore';
	restore_all();
};

subtest 'restore on never-mocked method is safe' => sub {
	{
		package Edge::Restore;
		sub d { return 'orig' }
	}

	lives_ok { restore 'Edge::Restore::d' } 'restore on untouched method is safe';
	is Edge::Restore::d(), 'orig', 'method unchanged';
};

subtest 'restore on nonexistent method deletes nothing' => sub {
	lives_ok { restore 'Edge::Restore::nope' } 'restore on nonexistent method is safe';
};

subtest 'diagnose_mocks on empty state' => sub {
	my $diag = diagnose_mocks();
	is_deeply $diag, {}, 'empty diagnostics';
};

subtest 'diagnose_mocks survives restore_all' => sub {
	{
		package DM::E1;
		sub d { 1 }
	}

	mock_return 'DM::E1::d' => 5;
	restore_all();
	my $diag = diagnose_mocks();
	is_deeply $diag, {}, 'diagnostics cleared after restore_all';
};

# ------------------------------------------------------------
# 8. Prototype preservation edge cases
#
# These tests cover boundary conditions around the set_prototype
# fix: the () case that triggered the original bug, stacked mocks
# on prototyped functions, mock_scoped, and spy (which does NOT
# currently apply set_prototype -- documented below).
# ------------------------------------------------------------

subtest 'mock(): () prototype suppresses mismatch warning' => sub {
	# The () no-args prototype is the canonical trigger for the bug:
	# I18N::LangTags::Detect::detect is defined as "sub detect ()",
	# and installing a replacement with no prototype caused Perl to
	# emit "Prototype mismatch: sub ... ()" on every redefinition.
	{
		package Proto::Edge::NoArgs;
		sub detect () { 'real' }
	}

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	mock 'Proto::Edge::NoArgs::detect' => sub { 'mocked' };

	ok !@warnings, 'no warning emitted when replacing () prototype function';

	restore_all();
};

subtest 'mock(): stacked mocks on () prototype function carry prototype at each layer' => sub {
	# Every mock() call pushes a new replacement.  Each replacement must
	# independently receive the prototype so that unwinding one layer
	# never leaves a prototype-free coderef exposed.
	{
		package Proto::Edge::Stack;
		sub fn () { 'orig' }
	}

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	mock 'Proto::Edge::Stack::fn' => sub { 'L1' };
	is prototype(\&Proto::Edge::Stack::fn), '',
		'L1 replacement carries () prototype';

	mock 'Proto::Edge::Stack::fn' => sub { 'L2' };
	is prototype(\&Proto::Edge::Stack::fn), '',
		'L2 replacement carries () prototype';

	# Pop L2: L1 must still carry the prototype.
	# Note: direct calls to () prototype functions are constant-folded by
	# Perl at compile time, so we verify the active coderef via ->can()
	# rather than a literal call that always returns the compile-time constant.
	unmock 'Proto::Edge::Stack::fn';
	is prototype(\&Proto::Edge::Stack::fn), '',
		'L1 still carries () prototype after L2 removed';
	# Use a temporary variable to avoid indirect-method-call ambiguity
	my $active = Proto::Edge::Stack->can('fn');
	is $active->(), 'L1', 'L1 is now active (verified via runtime ->can() lookup)';

	restore_all();
	is prototype(\&Proto::Edge::Stack::fn), '',
		'original () prototype restored after restore_all';

	ok !@warnings, 'no prototype-mismatch warnings across entire stack cycle';
};

subtest 'mock_scoped(): () prototype function -- no warning, correct prototype' => sub {
	{
		package Proto::Edge::Scoped;
		sub fn () { 'orig' }
	}

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	{
		# mock_scoped delegates to mock(), so set_prototype applies here too.
		# Return-value assertions use ->can() to bypass compile-time constant
		# inlining of the () prototype function.
		my $g = mock_scoped 'Proto::Edge::Scoped::fn' => sub { 'scoped' };
		is prototype(\&Proto::Edge::Scoped::fn), '',
			'mock_scoped replacement carries () prototype';
		my $active_scoped = Proto::Edge::Scoped->can('fn');
		is $active_scoped->(), 'scoped',
			'mock active inside scope (verified via ->can())';
	}

	# Guard destroyed: original coderef reinstated with its prototype
	my $after_guard = Proto::Edge::Scoped->can('fn');
	is $after_guard->(), 'orig',
		'original restored after guard destroyed (verified via ->can())';
	is prototype(\&Proto::Edge::Scoped::fn), '',
		'original () prototype intact after guard destruction';
	ok !@warnings, 'no warnings during mock_scoped on () prototype function';
};

subtest 'spy(): installing on () prototype function -- behaviour documented' => sub {
	# spy() installs its own wrapper coderef directly without going through
	# mock(), so set_prototype is NOT applied by spy().  This test documents
	# the current behaviour so any future fix to spy() is caught by
	# regression: if spy() is ever fixed, the wrapper's prototype will be
	# '' and the test description will still hold.
	{
		package Proto::Edge::Spy;
		sub fn () { 'orig' }
	}

	# spy() does NOT call mock() internally, so set_prototype is not applied.
	# Installing a spy on a () prototype function therefore still emits a
	# "Prototype mismatch" warning -- this is the known limitation documented
	# here so that a future fix to spy() will be caught by regression.
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	my $spy = spy 'Proto::Edge::Spy::fn';

	# Direct literal calls to a () prototype function are constant-folded
	# at compile time.  Use ->can() for a runtime lookup that goes through
	# the spy wrapper.
	Proto::Edge::Spy->can('fn')->();
	my @calls = $spy->();

	is scalar @calls, 1, 'spy captured the call';
	is $calls[0][0], 'Proto::Edge::Spy::fn', 'method name recorded';

	# Exactly one "Prototype mismatch" warning is expected because spy()
	# installs its wrapper without applying set_prototype.
	is scalar(grep { /Prototype mismatch/ } @warnings), 1,
		'spy() emits exactly one prototype-mismatch warning (known limitation)';

	restore_all();

	# Reinstating the original coderef also restores its () prototype
	is prototype(\&Proto::Edge::Spy::fn), '',
		'original () prototype restored after spy removed';
};

subtest 'mock(): ($$) prototype preserved through full mock/unmock cycle' => sub {
	{
		package Proto::Edge::TwoArgs;
		sub add ($$) { $_[0] + $_[1] }
	}

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	mock 'Proto::Edge::TwoArgs::add' => sub { 999 };
	is prototype(\&Proto::Edge::TwoArgs::add), '$$',
		'$$ prototype on replacement';

	unmock 'Proto::Edge::TwoArgs::add';
	is prototype(\&Proto::Edge::TwoArgs::add), '$$',
		'$$ prototype restored after unmock';

	ok !@warnings, 'no warnings for $$ prototype function';
};

# ------------------------------------------------------------
# 9. Global state integrity -- $@, $_ must survive mock operations
# ------------------------------------------------------------

subtest 'mock(): does not clobber $@' => sub {
	{ package EC::GS1; sub fn { 1 } }
	local $@ = 'sentinel error';
	mock 'EC::GS1::fn' => sub { 99 };
	is $@, 'sentinel error', 'mock() leaves $@ unchanged';
	restore_all();
};

subtest 'spy(): does not clobber $@' => sub {
	{ package EC::GS2; sub fn { 1 } }
	local $@ = 'sentinel error';
	my $spy = spy 'EC::GS2::fn';
	is $@, 'sentinel error', 'spy() leaves $@ unchanged';
	restore_all();
};

subtest 'spy wrapper does not clobber $_ during call' => sub {
	# A spy wrapper must not leak into $_ -- the intercepted call runs
	# under whatever $_ the caller set.
	{ package EC::GS3; sub fn { 1 } }
	my $spy = spy 'EC::GS3::fn';
	local $_ = 'outer sentinel';
	EC::GS3::fn('arg');
	is $_, 'outer sentinel', 'spy wrapper preserves $_ during call';
	restore_all();
};

# ------------------------------------------------------------
# 10. mock() -- hostile / boundary inputs
# ------------------------------------------------------------

subtest 'mock(): empty string package croaks' => sub {
	# Empty string is falsy; the check "unless $package" fires.
	throws_ok { mock('', 'method', sub { 1 }) }
		qr/\Q$ERR_MOCK_REQ\E/,
		'empty string package croaks';
};

subtest 'mock(): empty string method croaks' => sub {
	throws_ok { mock('Pkg', '', sub { 1 }) }
		qr/\Q$ERR_MOCK_REQ\E/,
		'empty string method croaks';
};

subtest 'mock(): numeric 0 as replacement croaks (falsy)' => sub {
	# 0 is falsy; the check "unless $replacement" fires.
	throws_ok { mock('EC::Z', 'fn', 0) }
		qr/\Q$ERR_MOCK_REQ\E/,
		'numeric 0 replacement croaks';
};

subtest 'mock(): empty string as replacement croaks (falsy)' => sub {
	throws_ok { mock('EC::Z', 'fn', '') }
		qr/\Q$ERR_MOCK_REQ\E/,
		'empty string replacement croaks';
};

subtest 'mock(): shorthand with empty package segment croaks' => sub {
	# '::method' parses to package='', method='method' -- empty pkg is falsy.
	throws_ok { mock('::method', sub { 1 }) }
		qr/\Q$ERR_MOCK_REQ\E/,
		'shorthand with empty package segment croaks';
};

# ------------------------------------------------------------
# 11. unmock() -- hostile inputs
# ------------------------------------------------------------

subtest 'unmock(): empty string target croaks' => sub {
	throws_ok { unmock '' }
		qr/\Q$ERR_UNMOCK_REQ\E/,
		'empty string croaks';
};

subtest 'unmock(): numeric 0 target croaks' => sub {
	throws_ok { unmock 0 }
		qr/\Q$ERR_UNMOCK_REQ\E/,
		'numeric 0 croaks';
};

subtest 'unmock(): more calls than mocks is idempotent' => sub {
	# Calling unmock() more times than mock() must not die.
	{ package EC::UM1; sub fn { 'real' } }
	mock 'EC::UM1::fn' => sub { 'mock' };
	unmock 'EC::UM1::fn';
	lives_ok { unmock 'EC::UM1::fn' } 'extra unmock is silent';
	is EC::UM1::fn(), 'real', 'original intact after extra unmock';
};

# ------------------------------------------------------------
# 12. inject() -- boundary values (undef, 0, '')
# ------------------------------------------------------------

subtest 'inject(): longhand undef value is valid (undef returned)' => sub {
	# The docs say "Injecting undef is valid" for the longhand (3-arg) form.
	{ package EC::INJ1; sub dep { 'real' } }
	inject('EC::INJ1', 'dep', undef);
	is EC::INJ1::dep(), undef, 'injected undef returned';
	restore_all();
};

subtest 'inject(): longhand 0 value is valid (0 returned)' => sub {
	{ package EC::INJ2; sub dep { 'real' } }
	inject('EC::INJ2', 'dep', 0);
	is EC::INJ2::dep(), 0, 'injected 0 returned';
	restore_all();
};

subtest 'inject(): longhand empty-string value is valid' => sub {
	{ package EC::INJ3; sub dep { 'real' } }
	inject('EC::INJ3', 'dep', '');
	is EC::INJ3::dep(), '', 'injected empty string returned';
	restore_all();
};

subtest 'inject(): shorthand with empty package segment croaks' => sub {
	# '::dep' → package='', dependency='dep' -- empty package is falsy.
	throws_ok { inject '::dep' => 'val' }
		qr/\Q$ERR_INJ_REQ\E/,
		'empty package segment croaks';
};

subtest 'inject(): empty string dependency croaks' => sub {
	# Longhand form with empty dependency string -- both package and dependency
	# must be truthy; an empty string for either triggers the guard.
	throws_ok { inject('EC::INJ4', '', 'val') }
		qr/\Q$ERR_INJ_REQ\E/,
		'empty string dependency croaks';
};

subtest 'inject(): circular reference value is injected as opaque scalar' => sub {
	# Circular refs must be stored verbatim, not traversed or stringified.
	{ package EC::CRC; sub dep { 'real' } }
	my $circular = {};
	$circular->{self} = $circular;
	inject('EC::CRC', 'dep', $circular);
	my $got = EC::CRC::dep();
	is ref($got), 'HASH', 'circular ref injected as HASH';
	is $got->{self}, $got, 'circular reference intact';
	restore_all();
};

# ------------------------------------------------------------
# 13. inject_all() -- hostile inputs
# ------------------------------------------------------------

subtest 'inject_all(): arrayref second arg croaks' => sub {
	throws_ok { inject_all('EC::IA', [foo => 1]) }
		qr/\Q$ERR_IA_HREF\E/,
		'arrayref second arg croaks';
};

subtest 'inject_all(): scalar string second arg croaks' => sub {
	throws_ok { inject_all('EC::IA', 'string') }
		qr/\Q$ERR_IA_HREF\E/,
		'scalar string second arg croaks';
};

subtest 'inject_all(): undef second arg croaks' => sub {
	throws_ok { inject_all('EC::IA', undef) }
		qr/\Q$ERR_IA_HREF\E/,
		'undef second arg croaks';
};

subtest 'inject_all(): hashref with undef values is valid' => sub {
	{ package EC::IA2; sub dep { 'real' } }
	inject_all('EC::IA2', { dep => undef });
	is EC::IA2::dep(), undef, 'undef value injected via inject_all';
	restore_all();
};

subtest 'inject_all(): undef package croaks' => sub {
	throws_ok { inject_all(undef, {}) }
		qr/\Q$ERR_IA_PKG\E/,
		'undef package croaks';
};

subtest 'inject_all(): empty string package croaks' => sub {
	throws_ok { inject_all('', {}) }
		qr/\Q$ERR_IA_PKG\E/,
		'empty string package croaks';
};

# ------------------------------------------------------------
# 14. intercept_new() -- boundary conditions
# ------------------------------------------------------------

subtest 'intercept_new(): undef as factory is valid (constructor returns undef)' => sub {
	# Use intermediate variable to avoid indirect-method-call mis-parse:
	# "is EC::IN1->new(), undef" parses as EC::IN1->is(...) not is(...).
	{ package EC::IN1; sub new { bless {}, shift } }
	intercept_new 'EC::IN1' => undef;
	my $got_undef = EC::IN1->new();
	is($got_undef, undef, 'undef factory: new() returns undef');
	restore_all();
};

subtest 'intercept_new(): numeric 0 as factory is valid' => sub {
	{ package EC::IN2; sub new { bless {}, shift } }
	intercept_new 'EC::IN2' => 0;
	my $got_zero = EC::IN2->new();
	is($got_zero, 0, 'numeric 0 factory: new() returns 0');
	restore_all();
};

subtest 'intercept_new(): empty string class croaks' => sub {
	throws_ok { intercept_new('', sub { 1 }) }
		qr/\Q$ERR_IN_CLASS\E/,
		'empty string class croaks';
};

subtest 'intercept_new(): undef class croaks' => sub {
	throws_ok { intercept_new(undef, sub { 1 }) }
		qr/\Q$ERR_IN_CLASS\E/,
		'undef class croaks';
};

subtest 'intercept_new(): missing factory arg croaks' => sub {
	throws_ok { intercept_new('EC::IN3') }
		qr/\Q$ERR_IN_REPL\E/,
		'missing second arg croaks';
};

# ------------------------------------------------------------
# 15. assert_call_order() -- hostile inputs and wrong-order case
# ------------------------------------------------------------

subtest 'assert_call_order(): zero args croaks' => sub {
	throws_ok { assert_call_order() }
		qr/\Q$ERR_ACO_MIN\E/,
		'zero args croaks';
};

subtest 'assert_call_order(): one arg croaks' => sub {
	throws_ok { assert_call_order('A::fn') }
		qr/\Q$ERR_ACO_MIN\E/,
		'one arg croaks';
};

subtest 'assert_call_order(): wrong order emits fail and returns false' => sub {
	# b is called before a, but we assert a then b -- should fail.
	# The assert_call_order() emits a TAP not-ok internally; wrap in TODO
	# so that internal failure does not pollute the suite result.
	{ package EC::CO1; sub a { 1 } sub b { 2 } }
	clear_call_log();
	spy 'EC::CO1::b';
	spy 'EC::CO1::a';
	EC::CO1::b();    # b first
	EC::CO1::a();    # a second

	my $result;
	TODO: {
		local $TODO = 'deliberate wrong-order -- verifying return value only';
		$result = assert_call_order('EC::CO1::a', 'EC::CO1::b');
	}
	ok !$result, 'wrong order returns false';
	restore_all();
};

subtest 'restore_all(pkg): prunes call_log entries for that package' => sub {
	# After restoring EC::CLA, its call_log entries are gone.
	# EC::CLB spy still has its record.
	{ package EC::CLA; sub fn { 'a' } }
	{ package EC::CLB; sub fn { 'b' } }
	clear_call_log();
	spy 'EC::CLA::fn';
	my $spy_b = spy 'EC::CLB::fn';
	EC::CLA::fn();
	EC::CLB::fn();

	restore_all('EC::CLA');

	my @calls_b = $spy_b->();
	is scalar @calls_b, 1, 'EC::CLB spy still has its call after scoped restore';

	# The EC::CLA call was pruned: assert_call_order(CLA, CLB) must fail.
	my $result;
	TODO: {
		local $TODO = 'EC::CLA entries pruned from call_log';
		$result = assert_call_order('EC::CLA::fn', 'EC::CLB::fn');
	}
	ok !$result, 'EC::CLA call pruned from call_log';

	restore_all();
};

# ------------------------------------------------------------
# 16. mock_exception() -- edge inputs
# ------------------------------------------------------------

subtest 'mock_exception(): empty string message still throws' => sub {
	# croak('') still dies; $@ receives the location-only message from Carp.
	{ package EC::ME1; sub fn { 'real' } }
	mock_exception 'EC::ME1::fn' => '';
	dies_ok { EC::ME1::fn() } 'empty string exception message still throws';
	restore_all();
};

subtest 'mock_exception(): newline-terminated message not extended by Carp' => sub {
	# Carp treats a message ending in \n as complete -- no "at file line N" appended.
	{ package EC::ME2; sub fn { 'real' } }
	mock_exception 'EC::ME2::fn' => "deliberate error\n";
	eval { EC::ME2::fn() };
	like $@, qr/deliberate error/, 'message text preserved';
	restore_all();
};

subtest 'mock_exception(): undef message croaks at install time' => sub {
	throws_ok { mock_exception 'EC::ME3::fn' }
		qr/mock_exception requires a target and an exception message/,
		'missing message arg croaks';
};

# ------------------------------------------------------------
# 17. mock_sequence() -- context and undef values
# ------------------------------------------------------------

subtest 'mock_sequence(): undef in sequence is returned verbatim' => sub {
	{ package EC::MS1; sub fn { 'real' } }
	mock_sequence 'EC::MS1::fn' => (undef, 'second');
	is EC::MS1::fn(), undef, 'first call returns undef from sequence';
	is EC::MS1::fn(), 'second', 'second call returns second value';
	restore_all();
};

subtest 'mock_sequence(): single-element sequence repeats on every call' => sub {
	{ package EC::MS2; sub fn { 'real' } }
	mock_sequence 'EC::MS2::fn' => 42;
	is EC::MS2::fn(), 42, 'call 1: 42';
	is EC::MS2::fn(), 42, 'call 2: 42 (repeated)';
	is EC::MS2::fn(), 42, 'call 3: 42 (still repeating)';
	restore_all();
};

subtest 'mock_sequence(): last element repeats after exhaustion' => sub {
	{ package EC::MS3; sub fn { 'real' } }
	mock_sequence 'EC::MS3::fn' => ('first', 'last_val');
	is EC::MS3::fn(), 'first', 'call 1: first';
	is EC::MS3::fn(), 'last_val', 'call 2: last_val';
	is EC::MS3::fn(), 'last_val', 'call 3: last_val repeated';
	is EC::MS3::fn(), 'last_val', 'call 4: last_val still repeating';
	restore_all();
};

# ------------------------------------------------------------
# 18. mock_once() -- return-value context sensitivity
# ------------------------------------------------------------

subtest 'mock_once(): scalar context propagated correctly' => sub {
	{ package EC::MO1; sub fn { ('a', 'b', 'c') } }
	mock_once 'EC::MO1::fn' => sub { 'once_scalar' };
	my $result = EC::MO1::fn();
	is $result, 'once_scalar', 'scalar context returns the scalar value';
	restore_all();
};

subtest 'mock_once(): list context propagated correctly' => sub {
	{ package EC::MO2; sub fn { 'real' } }
	mock_once 'EC::MO2::fn' => sub { (1, 2, 3) };
	my @result = EC::MO2::fn();
	is_deeply \@result, [1, 2, 3], 'list context returns full list';
	restore_all();
};

subtest 'mock_once(): second call hits original after auto-restore' => sub {
	{ package EC::MO3; sub fn { 'original' } }
	mock_once 'EC::MO3::fn' => sub { 'temporary' };
	is EC::MO3::fn(), 'temporary', 'first call: mock fires';
	is EC::MO3::fn(), 'original', 'second call: original restored';
};

# ------------------------------------------------------------
# 19. mock_scoped() -- hostile argument forms
# ------------------------------------------------------------

subtest 'mock_scoped(): zero args croaks' => sub {
	throws_ok { mock_scoped() }
		qr/\Q$ERR_MS_UNRECOG\E/,
		'zero args croaks';
};

subtest 'mock_scoped(): single string arg (no coderef) croaks' => sub {
	throws_ok { mock_scoped('Pkg::method') }
		qr/\Q$ERR_MS_UNRECOG\E/,
		'single string arg without coderef croaks';
};

subtest 'mock_scoped(): two args where second is non-CODE croaks' => sub {
	throws_ok { mock_scoped('Pkg::method', 'not_a_coderef') }
		qr/\Q$ERR_MS_UNRECOG\E/,
		'two args with non-CODE second croaks';
};

subtest 'mock_scoped(): guard restore_all() after DESTROY is idempotent' => sub {
	# The guard unmocks on DESTROY; a subsequent restore_all() must not die.
	{ package EC::GD1; sub fn { 'real' } }
	{
		my $g = mock_scoped 'EC::GD1::fn' => sub { 'scoped' };
		is EC::GD1::fn(), 'scoped', 'mock active in scope';
	}
	is EC::GD1::fn(), 'real', 'restored by guard DESTROY';
	lives_ok { restore_all() } 'restore_all() after DESTROY is safe';
	is EC::GD1::fn(), 'real', 'still real after restore_all';
};

# ------------------------------------------------------------
# 20. spy() -- call-list context behaviour and undef args
# ------------------------------------------------------------

subtest 'spy(): call list in list context' => sub {
	{ package EC::CTX1; sub fn { 1 } }
	my $spy = spy 'EC::CTX1::fn';
	EC::CTX1::fn('a');
	EC::CTX1::fn('b');
	my @calls = $spy->();
	is scalar @calls, 2, 'list context: both calls present';
	restore_all();
};

subtest 'spy(): call count in scalar context' => sub {
	# In scalar context the underlying @calls array evaluates as its count.
	{ package EC::CTX2; sub fn { 1 } }
	my $spy = spy 'EC::CTX2::fn';
	EC::CTX2::fn('x');
	EC::CTX2::fn('y');
	EC::CTX2::fn('z');
	my $count = scalar $spy->();
	is $count, 3, 'scalar context: count of captured calls';
	restore_all();
};

subtest 'spy(): captures undef arguments without error' => sub {
	{ package EC::UARG; sub fn { 1 } }
	my $spy = spy 'EC::UARG::fn';
	EC::UARG::fn(undef, 'val', undef);
	my @calls = $spy->();
	is scalar @calls, 1, 'one call captured';
	is $calls[0][1], undef, 'first arg is undef';
	is $calls[0][2], 'val', 'second arg preserved';
	is $calls[0][3], undef, 'third arg is undef';
	restore_all();
};

# ------------------------------------------------------------
# 21. Deep mock stack -- stress test
# ------------------------------------------------------------

subtest 'mock(): 50-layer stack is created and fully restored' => sub {
	{ package EC::DEEP; sub fn { 'original' } }
	for my $i (1..50) {
		my $layer = $i;
		mock 'EC::DEEP::fn' => sub { "layer_$layer" };
	}
	is EC::DEEP::fn(), 'layer_50', 'top layer (50) is active';
	restore_all();
	is EC::DEEP::fn(), 'original', 'original restored after 50-layer stack';
};

# ------------------------------------------------------------
# 22. _get_prototype() -- security: digit-starting identifiers rejected
# ------------------------------------------------------------

subtest '_get_prototype(): method segment starting with digit is rejected' => sub {
	# Perl identifiers cannot begin with a digit; the regex anchor [A-Za-z_]
	# must reject such names before dereferencing the typeglob.
	throws_ok {
		Test::Mockingbird::_get_prototype('Valid::1invalid_method')
	} qr/\Q$ERR_PROTO_NAME\E/,
		'digit-starting method component croaks';
};

subtest '_get_prototype(): package segment starting with digit is rejected' => sub {
	throws_ok {
		Test::Mockingbird::_get_prototype('1Invalid::method')
	} qr/\Q$ERR_PROTO_NAME\E/,
		'digit-starting package component croaks';
};

subtest '_get_prototype(): single-component name (no ::) is rejected' => sub {
	# Requires at least one :: separator.
	throws_ok {
		Test::Mockingbird::_get_prototype('NoColons')
	} qr/\Q$ERR_PROTO_NAME\E/,
		'name without :: is rejected';
};

# ------------------------------------------------------------
# 23. TimeTravel -- hostile inputs and exception safety
# ------------------------------------------------------------

subtest 'TimeTravel: travel_to() without freeze_time() croaks' => sub {
	throws_ok { travel_to($TS_2025_JAN1) }
		qr/\Q$ERR_TT_TRAVEL\E/,
		'travel_to when inactive croaks';
};

subtest 'TimeTravel: advance_time() without freeze_time() croaks' => sub {
	throws_ok { advance_time(60) }
		qr/\Q$ERR_TT_ADVANCE\E/,
		'advance_time when inactive croaks';
};

subtest 'TimeTravel: rewind_time() without freeze_time() croaks' => sub {
	throws_ok { rewind_time(60) }
		qr/\Q$ERR_TT_REWIND\E/,
		'rewind_time when inactive croaks';
};

subtest 'TimeTravel: with_frozen_time() non-CODE second arg croaks' => sub {
	throws_ok { with_frozen_time($TS_2025_JAN1, 'not_a_code') }
		qr/\Q$ERR_TT_CODE\E/,
		'non-CODE second arg croaks';
};

subtest 'TimeTravel: with_frozen_time() undef timestamp croaks' => sub {
	throws_ok { with_frozen_time(undef, sub { 1 }) }
		qr/\Q$ERR_TT_TS\E/,
		'undef timestamp croaks';
};

subtest 'TimeTravel: invalid timestamp format croaks' => sub {
	throws_ok { freeze_time('not-a-date') }
		qr/\Q$ERR_TT_INVALID\E/,
		'invalid format string croaks';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'TimeTravel: unknown time unit in advance_time() croaks' => sub {
	freeze_time($TS_2025_JAN1);
	throws_ok { advance_time(1 => 'fortnight') }
		qr/Unknown time unit 'fortnight'/,
		'unrecognised unit string croaks';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'TimeTravel: with_frozen_time() restores outer state after block throws' => sub {
	# Even when the code block dies, the saved state must be fully restored.
	freeze_time($TS_2025_JAN1);
	my $outer_epoch = now();

	eval {
		with_frozen_time $TS_2025_JUN1 => sub {
			die "block exploded\n";
		};
	};
	like $@, qr/block exploded/, 'exception propagated to caller';
	is now(), $outer_epoch, 'outer frozen time restored despite exception';

	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'TimeTravel: nested with_frozen_time() restores each level correctly' => sub {
	freeze_time($TS_2025_JAN1);
	my $outer_epoch = now();

	with_frozen_time $TS_2025_JUN1 => sub {
		my $mid_epoch = now();
		isnt $mid_epoch, $outer_epoch, 'mid block sees different time';

		with_frozen_time $TS_2025_DEC31 => sub {
			my $inner_epoch = now();
			isnt $inner_epoch, $mid_epoch, 'innermost sees yet another time';
		};

		is now(), $mid_epoch, 'mid-level time restored after innermost exits';
	};

	is now(), $outer_epoch, 'outer time restored after all nested blocks exit';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'TimeTravel: restore_all() when already inactive is idempotent' => sub {
	ok !$Test::Mockingbird::TimeTravel::ACTIVE,
		'precondition: TimeTravel not active';
	lives_ok { Test::Mockingbird::TimeTravel::restore_all() }
		'restore_all() on inactive state does not die';
	ok !$Test::Mockingbird::TimeTravel::ACTIVE,
		'still not active after idempotent restore_all';
};

subtest 'TimeTravel: advance_time(0) is a valid no-op' => sub {
	freeze_time($TS_2025_JAN1);
	my $before = now();
	advance_time(0);
	is now(), $before, 'advancing by 0 seconds leaves time unchanged';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'TimeTravel: rewind_time() with unit form reduces epoch' => sub {
	freeze_time($TS_2025_JAN1);
	my $before = now();
	rewind_time(1 => 'hour');
	is now(), $before - 3600, 'rewind by 1 hour subtracts 3600 seconds';
	Test::Mockingbird::TimeTravel::restore_all();
};

# ------------------------------------------------------------
# 24. Async module -- hostile inputs (self-gated on Future presence)
# ------------------------------------------------------------

subtest 'Async: mock_future_return() undef target croaks' => sub {
	if (!eval { require Future; 1 }) {
		plan skip_all => 'Future not installed';
		return;
	}
	require Test::Mockingbird::Async;
	my $mfr = \&Test::Mockingbird::Async::mock_future_return;
	throws_ok { $mfr->(undef) }
		qr/mock_future_return requires a target/,
		'undef target croaks';
	restore_all();
};

subtest 'Async: mock_future_fail() missing message croaks' => sub {
	if (!eval { require Future; 1 }) {
		plan skip_all => 'Future not installed';
		return;
	}
	require Test::Mockingbird::Async;
	my $mff = \&Test::Mockingbird::Async::mock_future_fail;
	throws_ok { $mff->('Pkg::fn') }
		qr/requires a target and a failure message/,
		'missing failure message croaks';
	throws_ok { $mff->(undef, 'msg') }
		qr/requires a target and a failure message/,
		'undef target also croaks';
	restore_all();
};

subtest 'Async: mock_future_sequence() no items croaks' => sub {
	if (!eval { require Future; 1 }) {
		plan skip_all => 'Future not installed';
		return;
	}
	require Test::Mockingbird::Async;
	my $mfs = \&Test::Mockingbird::Async::mock_future_sequence;
	throws_ok { $mfs->('Pkg::fn') }
		qr/requires a target and at least one item/,
		'missing items croaks';
	restore_all();
};

subtest 'Async: mock_future_once() undef target croaks' => sub {
	if (!eval { require Future; 1 }) {
		plan skip_all => 'Future not installed';
		return;
	}
	require Test::Mockingbird::Async;
	my $mfo = \&Test::Mockingbird::Async::mock_future_once;
	throws_ok { $mfo->(undef) }
		qr/mock_future_once requires a target/,
		'undef target croaks';
	restore_all();
};

subtest 'Async: async_spy() missing target croaks' => sub {
	if (!eval { require Future; 1 }) {
		plan skip_all => 'Future not installed';
		return;
	}
	require Test::Mockingbird::Async;
	my $asp = \&Test::Mockingbird::Async::async_spy;
	throws_ok { $asp->() }
		qr/Package and method are required for async_spy/,
		'empty target croaks';
	restore_all();
};

done_testing();
