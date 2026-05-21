use strict;
use warnings;
use Test::Most;
use Test::Mockingbird;

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

done_testing();
