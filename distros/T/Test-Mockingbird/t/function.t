use strict;
use warnings;

use Readonly;
use Test::Most;
use Test::Deep;
use Test::Memory::Cycle;

# Import core module.  TimeTravel is pulled in later with an explicit import
# list to avoid its restore_all() silently shadowing the core one.
use Test::Mockingbird;
use Test::Mockingbird::TimeTravel qw(
	now freeze_time travel_to advance_time rewind_time with_frozen_time
);
use Test::Mockingbird::DeepMock qw(deep_mock);

# ---------------------------------------------------------------------------
# Magic-string elimination: type names used in diagnose_mocks() assertions
# ---------------------------------------------------------------------------
Readonly my $T_MOCK        => 'mock';
Readonly my $T_SPY         => 'spy';
Readonly my $T_INJECT      => 'inject';
Readonly my $T_MOCK_RETURN => 'mock_return';
Readonly my $T_MOCK_EXCEPT => 'mock_exception';
Readonly my $T_MOCK_SEQ    => 'mock_sequence';
Readonly my $T_MOCK_ONCE   => 'mock_once';
Readonly my $T_MOCK_SCOPED => 'mock_scoped';
Readonly my $T_INTERCEPT   => 'intercept_new';
Readonly my $T_BEFORE      => 'before';
Readonly my $T_AFTER       => 'after';
Readonly my $T_AROUND      => 'around';

# ---------------------------------------------------------------------------
# Shortcuts to private helpers (white-box access).  These functions are
# convention-private (leading underscore) but not enforced at runtime.
# ---------------------------------------------------------------------------
my $parse_target    = \&Test::Mockingbird::_parse_target;
my $caller_info     = \&Test::Mockingbird::_caller_info;
my $drain_restore   = \&Test::Mockingbird::_drain_and_restore;
my $get_prototype   = \&Test::Mockingbird::_get_prototype;
my $record_call     = \&Test::Mockingbird::_record_call;
my $parse_timestamp = \&Test::Mockingbird::TimeTravel::_parse_timestamp;
my $parse_datetime  = \&Test::Mockingbird::TimeTravel::_parse_datetime;
my $unit_to_secs    = \&Test::Mockingbird::TimeTravel::_unit_to_seconds;
my $norm_target     = \&Test::Mockingbird::DeepMock::_normalize_target;

# ============================================================================
#  SECTION 1 -- Test::Mockingbird (core private helpers)
# ============================================================================

subtest '_parse_target: shorthand Pkg::method string' => sub {
	# Strategy: verify that a single 'A::B' string is split on the LAST '::'.
	my ($pkg, $meth) = $parse_target->('My::Deep::Pkg::greet');
	is $pkg,  'My::Deep::Pkg', 'package portion correct';
	is $meth, 'greet',         'method portion correct';
};

subtest '_parse_target: longhand two-arg form' => sub {
	my ($pkg, $meth) = $parse_target->('Alpha', 'beta');
	is $pkg,  'Alpha', 'package unchanged';
	is $meth, 'beta',  'method unchanged';
};

subtest '_parse_target: single arg without :: returned as-is' => sub {
	# A string with no '::' cannot be split; the function should return
	# the two raw args rather than attempt a split.
	my ($a, $b) = $parse_target->('NoPkg');
	is $a, 'NoPkg', 'first arg returned';
	ok !defined $b,  'second arg is undef';
};

subtest '_caller_info: returns file and line string' => sub {
	# The helper must skip frames inside Test::Mockingbird and return the
	# first frame that belongs to a different package (this test file).
	my $info = $caller_info->();
	like $info, qr/line \d+/, 'contains "line N"';
	# Should NOT point into the Test::Mockingbird namespace itself
	unlike $info, qr/Test::Mockingbird/, 'does not reference internal frame';
};

subtest '_get_prototype: extracts prototype' => sub {
	{
		package GP::Pkg;
		sub no_proto   { }
		sub two_args ($$) { }
		sub no_args  ()   { }
	}

	is $get_prototype->('GP::Pkg::two_args'), '$$', 'two-arg prototype';
	is $get_prototype->('GP::Pkg::no_args'),  '',   'no-arg () prototype';
	ok !defined $get_prototype->('GP::Pkg::no_proto'),
		'undef for no-prototype sub';
	ok !defined $get_prototype->('GP::Pkg::nonexistent'),
		'undef for missing sub';
};

subtest '_get_prototype: croaks on invalid fully-qualified name' => sub {
	throws_ok { $get_prototype->('not::a::valid::name::1bad') }
		qr/Invalid fully-qualified name/,
		'symbol starting with digit rejected';

	throws_ok { $get_prototype->('single') }
		qr/Invalid fully-qualified name/,
		'single-component name rejected';
};

subtest '_record_call: appends to call log visible via assert_call_order' => sub {
	# _record_call is the cross-module bridge used by Async to write into
	# @call_log without bypassing the lexical boundary.
	{
		package RC::A;
		sub ping { 1 }
	}
	spy 'RC::A::ping';
	RC::A::ping();
	$record_call->('RC::A::ping');    # direct write -- simulates Async usage

	# assert_call_order verifies the log contains the name twice.  We wrap
	# in a local $TODO so that the TAP ok/not-ok lines from the helper do
	# not count as test failures while we inspect the return value.
	my $ok;
	{
		local $TODO = 'internal whitebox assert';
		$ok = assert_call_order('RC::A::ping', 'RC::A::ping');
	}
	ok $ok, '_record_call entry visible to assert_call_order';

	Test::Mockingbird::restore_all();
};

# ============================================================================
#  SECTION 2 -- mock() and unmock()
# ============================================================================

subtest 'mock(): shorthand installs and returns undef' => sub {
	{ package M::S; sub fn { 'orig' } }

	my $rv = mock 'M::S::fn' => sub { 'mocked' };
	ok !defined $rv, 'mock returns undef';
	is M::S::fn(), 'mocked', 'shorthand mock active';
	Test::Mockingbird::restore_all();
};

subtest 'mock(): longhand three-arg form' => sub {
	{ package M::L; sub fn { 'orig' } }

	mock('M::L', 'fn', sub { 'longhand' });
	is M::L::fn(), 'longhand', 'longhand mock active';
	Test::Mockingbird::restore_all();
};

subtest 'mock(): $TYPE variable propagates to meta layer type' => sub {
	# Sugar functions set local $TYPE before calling mock() so that
	# diagnose_mocks() records the correct category.
	{ package M::T; sub fn { 1 } }

	{
		local $Test::Mockingbird::TYPE = 'custom_type';
		mock 'M::T::fn' => sub { 2 };
	}

	my $diag = diagnose_mocks();
	is $diag->{'M::T::fn'}{layers}[0]{type}, 'custom_type',
		'custom TYPE propagated into meta';
	Test::Mockingbird::restore_all();
};

subtest 'mock(): default type is "mock" when $TYPE not set' => sub {
	{ package M::D; sub fn { 1 } }

	mock 'M::D::fn' => sub { 2 };
	my $diag = diagnose_mocks();
	is $diag->{'M::D::fn'}{layers}[0]{type}, $T_MOCK, 'default type is mock';
	Test::Mockingbird::restore_all();
};

subtest 'mock(): original_existed recorded correctly' => sub {
	{ package M::OE; sub exists_before { 1 } }

	mock 'M::OE::exists_before'   => sub { 2 };
	mock 'M::OE::created_by_mock' => sub { 3 };

	my $diag = diagnose_mocks();
	is $diag->{'M::OE::exists_before'}{original_existed},   1,
		'existing method: original_existed = 1';
	is $diag->{'M::OE::created_by_mock'}{original_existed}, 0,
		'new method: original_existed = 0';

	Test::Mockingbird::restore_all();
};

subtest 'mock(): stacking multiple layers, LIFO order' => sub {
	{ package M::Stack; sub fn { 'orig' } }

	mock 'M::Stack::fn' => sub { 'L1' };
	mock 'M::Stack::fn' => sub { 'L2' };

	is M::Stack::fn(), 'L2', 'top layer (L2) active';
	my $d = diagnose_mocks();
	is $d->{'M::Stack::fn'}{depth}, 2, 'depth is 2';

	unmock 'M::Stack::fn';
	is M::Stack::fn(), 'L1', 'L1 active after popping L2';

	unmock 'M::Stack::fn';
	is M::Stack::fn(), 'orig', 'original active after popping L1';

	Test::Mockingbird::restore_all();
};

subtest 'mock(): croaks when package, method or coderef missing' => sub {
	throws_ok { mock(undef, 'fn', sub {}) }
		qr/Package, method and replacement are required/,
		'undef package croaks';

	throws_ok { mock('Pkg', undef, sub {}) }
		qr/Package, method and replacement are required/,
		'undef method croaks';

	throws_ok { mock('Pkg', 'fn', undef) }
		qr/Package, method and replacement are required/,
		'undef replacement croaks';
};

subtest 'mock(): installed_at reflects user call site, not internal frame' => sub {
	{ package M::AT; sub fn { 1 } }
	my $line = __LINE__ + 1;
	mock 'M::AT::fn' => sub { 2 };

	my $d = diagnose_mocks();
	my $at = $d->{'M::AT::fn'}{layers}[0]{installed_at};
	# The file part must contain this test file's name (not the module)
	like $at, qr/function\.t/, 'installed_at points to test file';
	like $at, qr/line $line/,  'installed_at contains correct line';

	Test::Mockingbird::restore_all();
};

subtest 'unmock(): pops ONE meta entry per call (bug-fix verification)' => sub {
	# Before the fix, unmock() deleted the ENTIRE meta key, wiping metadata
	# for lower layers even though they were still on the stack.
	{ package UN::M; sub fn { 'orig' } }

	mock 'UN::M::fn' => sub { 'L1' };
	mock 'UN::M::fn' => sub { 'L2' };

	unmock 'UN::M::fn';

	my $d = diagnose_mocks();
	is $d->{'UN::M::fn'}{depth},                   1, 'one layer remains';
	is scalar @{ $d->{'UN::M::fn'}{layers} },      1, 'exactly one meta entry';
	is $d->{'UN::M::fn'}{layers}[0]{type}, $T_MOCK,  'remaining meta is L1 type';

	Test::Mockingbird::restore_all();
};

subtest 'unmock(): shorthand and longhand forms both work' => sub {
	{ package UN::Forms; sub fn { 'orig' } }

	mock 'UN::Forms::fn' => sub { 'A' };
	unmock 'UN::Forms::fn';
	is UN::Forms::fn(), 'orig', 'shorthand unmock';

	mock('UN::Forms', 'fn', sub { 'B' });
	unmock('UN::Forms', 'fn');
	is UN::Forms::fn(), 'orig', 'longhand unmock';

	Test::Mockingbird::restore_all();
};

subtest 'unmock(): no-op when method was never mocked' => sub {
	{ package UN::Clean; sub fn { 'orig' } }
	lives_ok { unmock 'UN::Clean::fn' } 'unmock on clean method does not die';
	is UN::Clean::fn(), 'orig', 'method unchanged';
};

subtest 'unmock(): croaks when target is missing' => sub {
	throws_ok { unmock(undef) }
		qr/Package and method are required for unmocking/,
		'undef target croaks';
};

# ============================================================================
#  SECTION 2.5 -- before(), after(), around()
# ============================================================================

subtest 'before(): $TYPE is set to "before" in the mock layer' => sub {
	# White-box: local $TYPE = _T_BEFORE is set before the mock() call;
	# diagnose_mocks() must report 'before', not 'mock'.
	{ package F::Before; sub fn { 'orig' } }
	before 'F::Before::fn' => sub { };

	my $d = diagnose_mocks();
	is $d->{'F::Before::fn'}{layers}[0]{type}, $T_BEFORE,
		'$TYPE propagated correctly to meta layer';
	restore_all();
};

subtest 'before(): $orig captured at install time, not at call time' => sub {
	# White-box: $orig = \&{$full_method} before mock() installs the wrapper.
	# Subsequent mocks must not affect what $orig points to.
	{ package F::BeforeCapture; sub fn { 'original' } }
	before 'F::BeforeCapture::fn' => sub { };
	# Stack another mock on top -- before's $orig must still see the real fn
	mock 'F::BeforeCapture::fn' => sub { 'layer2' };

	unmock 'F::BeforeCapture::fn';   # peel the mock layer

	# Now the active slot is the before wrapper; its $orig is the real fn
	is F::BeforeCapture::fn(), 'original',
		'before wrapper still calls the real original after mock is peeled';
	restore_all();
};

subtest 'before(): list / scalar / void context dispatch' => sub {
	{ package F::BeforeCtx; sub multi { wantarray ? (1, 2, 3) : 'scalar' } }
	before 'F::BeforeCtx::multi' => sub { };

	my @list   = F::BeforeCtx::multi();
	my $scalar = F::BeforeCtx::multi();
	lives_ok { F::BeforeCtx::multi() } 'void context does not die';

	is_deeply \@list, [1, 2, 3], 'list context forwarded correctly';
	is $scalar, 'scalar',        'scalar context forwarded correctly';
	restore_all();
};

subtest 'after(): $TYPE is set to "after" in the mock layer' => sub {
	{ package F::After; sub fn { 'orig' } }
	after 'F::After::fn' => sub { };

	my $d = diagnose_mocks();
	is $d->{'F::After::fn'}{layers}[0]{type}, $T_AFTER,
		'$TYPE propagated correctly to meta layer';
	restore_all();
};

subtest 'after(): $orig captured at install time' => sub {
	{ package F::AfterCapture; sub fn { 'original' } }
	after 'F::AfterCapture::fn' => sub { };
	mock 'F::AfterCapture::fn' => sub { 'layer2' };

	unmock 'F::AfterCapture::fn';

	is F::AfterCapture::fn(), 'original',
		'after wrapper calls real original after mock is peeled';
	restore_all();
};

subtest 'after(): list / scalar / void context dispatch' => sub {
	{ package F::AfterCtx; sub multi { wantarray ? ('a', 'b') : 'scalar' } }
	after 'F::AfterCtx::multi' => sub { };

	my @list   = F::AfterCtx::multi();
	my $scalar = F::AfterCtx::multi();
	lives_ok { F::AfterCtx::multi() } 'void context does not die';

	is_deeply \@list, ['a', 'b'], 'list context forwarded correctly';
	is $scalar, 'scalar',         'scalar context forwarded correctly';
	restore_all();
};

subtest 'around(): $TYPE is set to "around" in the mock layer' => sub {
	{ package F::Around; sub fn { 'orig' } }
	around 'F::Around::fn' => sub { my ($o, @a) = @_; $o->(@a) };

	my $d = diagnose_mocks();
	is $d->{'F::Around::fn'}{layers}[0]{type}, $T_AROUND,
		'$TYPE propagated correctly to meta layer';
	restore_all();
};

subtest 'around(): $orig is the pre-install slot, not the wrapper itself' => sub {
	# White-box: $orig must point to what existed BEFORE mock() ran.
	# If it pointed at the installed wrapper we'd have infinite recursion.
	{ package F::AroundOrig; sub fn { 'real' } }
	my $calls = 0;
	around 'F::AroundOrig::fn' => sub {
		my ($orig, @args) = @_;
		$calls++;
		return $orig->(@args);   # must reach the real fn, not loop
	};

	my $r = F::AroundOrig::fn();
	is $calls, 1, 'wrapper called exactly once (no infinite recursion)';
	is $r, 'real', 'original return value returned';
	restore_all();
};

subtest 'around(): stacking — each layer gets the previous layer as $orig' => sub {
	{ package F::AroundStack; sub fn { 1 } }
	around 'F::AroundStack::fn' => sub { my ($o) = @_; $o->() + 10 };  # +10
	around 'F::AroundStack::fn' => sub { my ($o) = @_; $o->() * 3  };  # *3

	# Call: *3 wrapper; $orig = +10 wrapper; +10's $orig = real fn returning 1
	# 1 + 10 = 11; 11 * 3 = 33
	is F::AroundStack::fn(), 33, 'stacked around layers compose via $orig chain';
	restore_all();
};

# ============================================================================
#  SECTION 3 -- mock_scoped() and Test::Mockingbird::Guard
# ============================================================================

subtest 'mock_scoped(): shorthand 2-arg form' => sub {
	{ package MS::S2; sub fn { 'orig' } }

	{
		my $g = mock_scoped 'MS::S2::fn' => sub { 'scoped' };
		is MS::S2::fn(), 'scoped', 'mock active inside block';
		isa_ok $g, 'Test::Mockingbird::Guard', 'guard is Guard object';
		memory_cycle_ok $g, 'Guard object has no memory cycles';
	}
	is MS::S2::fn(), 'orig', 'mock removed after guard destroyed';
};

subtest 'mock_scoped(): longhand 3-arg form' => sub {
	{ package MS::L3; sub fn { 'orig' } }

	{
		my $g = mock_scoped('MS::L3', 'fn', sub { 'scoped3' });
		is MS::L3::fn(), 'scoped3', 'longhand mock active';
	}
	is MS::L3::fn(), 'orig', 'restored after guard DESTROY';
};

subtest 'mock_scoped(): multi-method cross-package form' => sub {
	{
		package MS::X1;
		sub a { 'a' }
		package MS::X2;
		sub b { 'b' }
	}

	{
		my $g = mock_scoped(
			'MS::X1::a' => sub { 'A' },
			'MS::X2::b' => sub { 'B' },
		);
		is MS::X1::a(), 'A', 'first cross-pkg mock active';
		is MS::X2::b(), 'B', 'second cross-pkg mock active';
	}
	is MS::X1::a(), 'a', 'first restored';
	is MS::X2::b(), 'b', 'second restored';
};

subtest 'mock_scoped(): multi-method same-package form' => sub {
	{
		package MS::P;
		sub fetch { 'f' }
		sub save  { 's' }
	}

	{
		my $g = mock_scoped(
			'MS::P',
			fetch => sub { 'F' },
			save  => sub { 'S' },
		);
		is MS::P::fetch(), 'F', 'fetch mocked';
		is MS::P::save(),  'S', 'save mocked';
	}
	is MS::P::fetch(), 'f', 'fetch restored';
	is MS::P::save(),  's', 'save restored';
};

subtest 'mock_scoped(): records type mock_scoped in meta' => sub {
	{ package MS::Type; sub fn { 1 } }

	my $g = mock_scoped 'MS::Type::fn' => sub { 2 };
	my $d = diagnose_mocks();
	is $d->{'MS::Type::fn'}{layers}[0]{type}, $T_MOCK_SCOPED,
		'layer type is mock_scoped';
};

subtest 'mock_scoped(): croaks on unrecognised argument form' => sub {
	throws_ok { mock_scoped('Only::One::Arg') }
		qr/unrecognised argument form/,
		'single non-coderef arg croaks';
};

# ============================================================================
#  SECTION 4 -- spy()
# ============================================================================

subtest 'spy(): returns coderef yielding call records' => sub {
	{ package Spy::P; sub greet { "hello $_[0]" } }

	my $spy = spy 'Spy::P::greet';
	Spy::P::greet('world');
	Spy::P::greet('Perl');

	my @calls = $spy->();
	is scalar @calls, 2, 'two call records';
	is_deeply $calls[0], [ 'Spy::P::greet', 'world' ], 'first call args';
	is_deeply $calls[1], [ 'Spy::P::greet', 'Perl'  ], 'second call args';

	Test::Mockingbird::restore_all();
};

subtest 'spy(): passes through return value from original' => sub {
	{ package Spy::RT; sub double { $_[0] * 2 } }

	spy 'Spy::RT::double';
	is Spy::RT::double(21), 42, 'original return value passes through';

	Test::Mockingbird::restore_all();
};

subtest 'spy(): appends to call-order log' => sub {
	{
		package Spy::Log;
		sub a { 1 }
		sub b { 2 }
	}

	spy 'Spy::Log::a';
	spy 'Spy::Log::b';
	Spy::Log::a();
	Spy::Log::b();

	my $ok;
	{
		local $TODO = 'whitebox call-order assertion';
		$ok = assert_call_order('Spy::Log::a', 'Spy::Log::b');
	}
	ok $ok, 'spy writes to call-order log';

	Test::Mockingbird::restore_all();
};

subtest 'spy(): records type "spy" in meta with original_existed flag' => sub {
	{ package Spy::Meta; sub fn { 1 } }

	spy 'Spy::Meta::fn';
	my $d = diagnose_mocks();
	is $d->{'Spy::Meta::fn'}{layers}[0]{type},             $T_SPY, 'type is spy';
	is $d->{'Spy::Meta::fn'}{layers}[0]{original_existed}, 1,      'original_existed = 1';

	Test::Mockingbird::restore_all();
};

subtest 'spy(): croaks when target is missing' => sub {
	throws_ok { spy(undef) }
		qr/Package and method are required for spying/,
		'undef target croaks';
};

# ============================================================================
#  SECTION 5 -- inject() and inject_all()
# ============================================================================

subtest 'inject(): shorthand form returns injected value' => sub {
	{ package Inj::S; sub dep { 'real' } }

	inject 'Inj::S::dep' => 'mocked';
	is Inj::S::dep(), 'mocked', 'shorthand inject active';

	Test::Mockingbird::restore_all();
};

subtest 'inject(): longhand 3-arg form' => sub {
	{ package Inj::L; sub dep { 'real' } }

	inject('Inj::L', 'dep', 'value');
	is Inj::L::dep(), 'value', 'longhand inject active';

	Test::Mockingbird::restore_all();
};

subtest 'inject(): undef is a valid injected value' => sub {
	{ package Inj::U; sub dep { 'real' } }

	inject('Inj::U', 'dep', undef);
	ok !defined Inj::U::dep(), 'undef value returned correctly';

	Test::Mockingbird::restore_all();
};

subtest 'inject(): respects $TYPE for meta layer type' => sub {
	# inject() now reads $Test::Mockingbird::TYPE so callers can override
	# the diagnostic label (e.g. inject_all could label layers distinctly).
	{ package Inj::T; sub dep { 1 } }

	{
		local $Test::Mockingbird::TYPE = 'special_inject';
		inject 'Inj::T::dep' => 'x';
	}

	my $d = diagnose_mocks();
	is $d->{'Inj::T::dep'}{layers}[0]{type}, 'special_inject',
		'custom TYPE propagated through inject()';

	Test::Mockingbird::restore_all();
};

subtest 'inject(): default meta type is "inject"' => sub {
	{ package Inj::D; sub dep { 1 } }

	inject 'Inj::D::dep' => 2;
	my $d = diagnose_mocks();
	is $d->{'Inj::D::dep'}{layers}[0]{type}, $T_INJECT, 'default type inject';

	Test::Mockingbird::restore_all();
};

subtest 'inject(): croaks when package or dependency missing' => sub {
	throws_ok { inject(undef, 'dep', 'v') }
		qr/Package and dependency are required/,
		'undef package croaks';

	throws_ok { inject('Pkg', undef, 'v') }
		qr/Package and dependency are required/,
		'undef dependency croaks';
};

subtest 'inject_all(): batch-injects all hashref pairs' => sub {
	{ package IA::P; sub db { 'real_db' } sub cache { 'real_cache' } }

	inject_all('IA::P', { db => 'mock_db', cache => 'mock_cache' });

	is IA::P::db(),    'mock_db',    'db injected';
	is IA::P::cache(), 'mock_cache', 'cache injected';

	Test::Mockingbird::restore_all();
};

subtest 'inject_all(): empty hashref is a no-op' => sub {
	lives_ok { inject_all('SomePkg', {}) } 'empty hashref does not die';
	my $d = diagnose_mocks();
	ok !exists $d->{'SomePkg::anything'}, 'no mock state created';
};

subtest 'inject_all(): croaks on bad arguments' => sub {
	throws_ok { inject_all(undef, {}) }
		qr/inject_all requires a package name/,
		'undef package croaks';

	throws_ok { inject_all('', {}) }
		qr/inject_all requires a package name/,
		'empty-string package croaks';

	throws_ok { inject_all('Pkg', []) }
		qr/inject_all requires a hashref/,
		'arrayref instead of hashref croaks';
};

# ============================================================================
#  SECTION 6 -- intercept_new()
# ============================================================================

subtest 'intercept_new(): plain scalar returned on every call' => sub {
	{ package IN::Plain; sub new { bless {}, shift } }

	my $stub = bless {}, 'IN::Stub';
	intercept_new 'IN::Plain' => $stub;

	my $obj = IN::Plain->new;
	is $obj, $stub, 'stub returned from new()';

	Test::Mockingbird::restore_all();
};

subtest 'intercept_new(): coderef factory receives class and args' => sub {
	{ package IN::Fact; sub new { bless {}, shift } }

	my @received;
	intercept_new 'IN::Fact' => sub { @received = @_; bless {}, 'IN::Double' };

	IN::Fact->new(key => 'val');

	is $received[0], 'IN::Fact', 'factory receives class name';
	is $received[1], 'key',      'factory receives arg key';

	Test::Mockingbird::restore_all();
};

subtest 'intercept_new(): undef is a valid factory value' => sub {
	{ package IN::Undef; sub new { bless {}, shift } }

	intercept_new 'IN::Undef' => undef;
	ok !defined IN::Undef->new, 'undef returned from intercepted new()';

	Test::Mockingbird::restore_all();
};

subtest 'intercept_new(): records type intercept_new in meta' => sub {
	{ package IN::Meta; sub new { bless {}, shift } }

	intercept_new 'IN::Meta' => 'stub';
	my $d = diagnose_mocks();
	is $d->{'IN::Meta::new'}{layers}[0]{type}, $T_INTERCEPT,
		'layer type is intercept_new';

	Test::Mockingbird::restore_all();
};

subtest 'intercept_new(): croaks on bad args' => sub {
	throws_ok { intercept_new(undef, 'stub') }
		qr/intercept_new requires a class name/,
		'undef class croaks';

	throws_ok { intercept_new('', 'stub') }
		qr/intercept_new requires a class name/,
		'empty class croaks';

	throws_ok { intercept_new('SomeClass') }
		qr/intercept_new requires a replacement/,
		'missing factory arg croaks';
};

# ============================================================================
#  SECTION 7 -- restore_all() and restore()
# ============================================================================

subtest 'restore_all(): global clears all mocks and call log' => sub {
	{
		package RA::A;
		sub m { 'orig_a' }
		package RA::B;
		sub m { 'orig_b' }
	}

	spy 'RA::A::m';
	mock 'RA::B::m' => sub { 'mocked' };
	RA::A::m();

	Test::Mockingbird::restore_all();

	my $d = diagnose_mocks();
	is_deeply $d, {}, 'all mocks cleared';
	is RA::A::m(), 'orig_a', 'A restored';
	is RA::B::m(), 'orig_b', 'B restored';
};

subtest 'restore_all(): package-scoped restores only matching mocks' => sub {
	{
		package RA::Scope::A;
		sub fn { 'a' }
		package RA::Scope::B;
		sub fn { 'b' }
	}

	mock 'RA::Scope::A::fn' => sub { 'A_mocked' };
	mock 'RA::Scope::B::fn' => sub { 'B_mocked' };

	Test::Mockingbird::restore_all('RA::Scope::A');

	is RA::Scope::A::fn(), 'a',         'A restored by scoped restore_all';
	is RA::Scope::B::fn(), 'B_mocked',  'B untouched';

	Test::Mockingbird::restore_all();
};

subtest 'restore_all(): package-scoped prunes call log entries for that package' => sub {
	{
		package RA::Log::X;
		sub fn { 1 }
		package RA::Log::Y;
		sub fn { 2 }
	}

	spy 'RA::Log::X::fn';
	spy 'RA::Log::Y::fn';
	RA::Log::X::fn();
	RA::Log::Y::fn();

	# Restore X -- its call-log entries should disappear.
	# Y::fn was called AFTER X::fn, so if the log is pruned correctly
	# assert_call_order('Y', 'X') would fail (X entry gone).
	Test::Mockingbird::restore_all('RA::Log::X');

	# Y::fn is still spied; calling it again writes another entry
	RA::Log::Y::fn();

	# The first Y entry and second Y entry are present but no X entry.
	# assert_call_order with X should fail since X was pruned.
	my $x_present;
	{
		local $TODO = 'whitebox log pruning check';
		$x_present = assert_call_order('RA::Log::X::fn', 'RA::Log::Y::fn');
	}
	ok !$x_present, 'X::fn call log entries pruned';

	Test::Mockingbird::restore_all();
};

subtest 'restore_all(): no-op on empty state' => sub {
	lives_ok { Test::Mockingbird::restore_all() } 'global restore on clean state';
	lives_ok { Test::Mockingbird::restore_all('NonExistent::Pkg') }
		'package restore on clean state';
};

subtest 'restore(): restores a single method target' => sub {
	{ package Rst::P; sub fn { 'orig' } }

	mock 'Rst::P::fn' => sub { 'mocked' };
	restore 'Rst::P::fn';
	is Rst::P::fn(), 'orig', 'single-method restore works';

	my $d = diagnose_mocks();
	ok !exists $d->{'Rst::P::fn'}, 'entry removed from diagnose_mocks';
};

subtest 'restore(): drains multi-layer stacks to the original' => sub {
	{ package Rst::ML; sub fn { 'orig' } }

	mock 'Rst::ML::fn' => sub { 'L1' };
	mock 'Rst::ML::fn' => sub { 'L2' };
	restore 'Rst::ML::fn';
	is Rst::ML::fn(), 'orig', 'all layers drained to original';
};

subtest 'restore(): no-op when method was never mocked' => sub {
	{ package Rst::Clean; sub fn { 'orig' } }
	lives_ok { restore 'Rst::Clean::fn' } 'no-op does not die';
	is Rst::Clean::fn(), 'orig', 'method unchanged';
};

subtest 'restore(): croaks on undef target' => sub {
	throws_ok { restore(undef) }
		qr/restore requires a target/,
		'undef target croaks';
};

# ============================================================================
#  SECTION 8 -- Sugar functions: mock_return, mock_exception, mock_sequence,
#               mock_once
# ============================================================================

subtest 'mock_return(): sets layer type mock_return and returns value' => sub {
	{ package MR::P; sub fn { 'orig' } }

	mock_return 'MR::P::fn' => 99;
	is MR::P::fn(), 99, 'return value is mocked';

	my $d = diagnose_mocks();
	is $d->{'MR::P::fn'}{layers}[0]{type}, $T_MOCK_RETURN,
		'layer type is mock_return';

	Test::Mockingbird::restore_all();
};

subtest 'mock_return(): croaks when target is undef' => sub {
	throws_ok { mock_return(undef, 42) }
		qr/mock_return requires a target/,
		'undef target croaks';
};

subtest 'mock_exception(): throws exact message every call' => sub {
	{ package ME::P; sub fn { 'orig' } }

	mock_exception 'ME::P::fn' => 'database exploded';
	throws_ok { ME::P::fn() }
		qr/database exploded/,
		'exact exception message thrown';

	# Each call throws -- not just the first
	throws_ok { ME::P::fn() } qr/database exploded/, 'second call also throws';

	my $d = diagnose_mocks();
	is $d->{'ME::P::fn'}{layers}[0]{type}, $T_MOCK_EXCEPT,
		'layer type is mock_exception';

	Test::Mockingbird::restore_all();
};

subtest 'mock_exception(): croaks when target or message missing' => sub {
	throws_ok { mock_exception(undef, 'msg') }
		qr/mock_exception requires a target and an exception message/,
		'undef target croaks';

	throws_ok { mock_exception('Pkg::fn', undef) }
		qr/mock_exception requires a target and an exception message/,
		'undef message croaks';
};

subtest 'mock_sequence(): advances through values, repeats last' => sub {
	{ package MSQ::P; sub fn { 'orig' } }

	mock_sequence 'MSQ::P::fn' => (10, 20, 30);
	is MSQ::P::fn(), 10, 'first value';
	is MSQ::P::fn(), 20, 'second value';
	is MSQ::P::fn(), 30, 'third value';
	is MSQ::P::fn(), 30, 'last value repeats';
	is MSQ::P::fn(), 30, 'still repeating';

	my $d = diagnose_mocks();
	is $d->{'MSQ::P::fn'}{layers}[0]{type}, $T_MOCK_SEQ,
		'layer type is mock_sequence';

	Test::Mockingbird::restore_all();
};

subtest 'mock_sequence(): single value repeats indefinitely' => sub {
	{ package MSQ::One; sub fn { 'orig' } }

	mock_sequence 'MSQ::One::fn' => ('only');
	is MSQ::One::fn(), 'only', 'first call';
	is MSQ::One::fn(), 'only', 'second call, same value';

	Test::Mockingbird::restore_all();
};

subtest 'mock_sequence(): croaks when sequence is empty' => sub {
	throws_ok { mock_sequence('Pkg::fn') }
		qr/mock_sequence requires a target and at least one value/,
		'empty sequence croaks';
};

subtest 'mock_once(): fires exactly once, then restores' => sub {
	{ package MO::P; sub fn { 'orig' } }

	mock_once 'MO::P::fn' => sub { 'once' };
	is MO::P::fn(), 'once', 'first call uses the mock';
	is MO::P::fn(), 'orig', 'second call uses the original';

	my $d = diagnose_mocks();
	ok !exists $d->{'MO::P::fn'}, 'no mock state after firing';

	Test::Mockingbird::restore_all();
};

subtest 'mock_once(): list context propagated correctly' => sub {
	# The wrapper always captures @result in list context, then returns
	# either the list or $result[0] depending on caller context.
	{ package MO::Ctx; sub fn { (1, 2, 3) } }

	mock_once 'MO::Ctx::fn' => sub { (10, 20, 30) };
	my @list = MO::Ctx::fn();
	is_deeply \@list, [10, 20, 30], 'list context: all values returned';

	mock_once 'MO::Ctx::fn' => sub { (10, 20, 30) };
	my $scalar = MO::Ctx::fn();
	is $scalar, 10, 'scalar context: first element returned';

	Test::Mockingbird::restore_all();
};

subtest 'mock_once(): layer type recorded as mock_once' => sub {
	{ package MO::Meta; sub fn { 1 } }

	mock_once 'MO::Meta::fn' => sub { 2 };
	my $d = diagnose_mocks();
	is $d->{'MO::Meta::fn'}{layers}[0]{type}, $T_MOCK_ONCE,
		'layer type is mock_once';

	Test::Mockingbird::restore_all();
};

subtest 'mock_once(): croaks when target or coderef missing' => sub {
	throws_ok { mock_once(undef, sub {}) }
		qr/mock_once requires a target and a coderef/,
		'undef target croaks';

	throws_ok { mock_once('Pkg::fn', 'not_code') }
		qr/mock_once requires a target and a coderef/,
		'non-coderef croaks';
};

# ============================================================================
#  SECTION 9 -- assert_call_order() and clear_call_log()
# ============================================================================

subtest 'assert_call_order(): passes when methods called in sequence' => sub {
	{
		package ACO::P;
		sub a { 1 }
		sub b { 2 }
		sub c { 3 }
	}
	spy 'ACO::P::a';
	spy 'ACO::P::b';
	spy 'ACO::P::c';
	ACO::P::a();
	ACO::P::b();
	ACO::P::c();

	my $ok;
	{
		local $TODO = 'call order pass';
		$ok = assert_call_order('ACO::P::a', 'ACO::P::b', 'ACO::P::c');
	}
	ok $ok, 'in-order assertion passes';

	Test::Mockingbird::restore_all();
};

subtest 'assert_call_order(): passes with intervening unrelated calls' => sub {
	{
		package ACO::I;
		sub a { 1 }
		sub z { 9 }
		sub b { 2 }
	}
	spy 'ACO::I::a';
	spy 'ACO::I::z';
	spy 'ACO::I::b';
	ACO::I::a();
	ACO::I::z();   # intervening call -- must be ignored
	ACO::I::b();

	my $ok;
	{
		local $TODO = 'order with intervening';
		$ok = assert_call_order('ACO::I::a', 'ACO::I::b');
	}
	ok $ok, 'intervening calls are ignored';

	Test::Mockingbird::restore_all();
};

subtest 'assert_call_order(): fails when order is wrong' => sub {
	{
		package ACO::F;
		sub a { 1 }
		sub b { 2 }
	}
	spy 'ACO::F::a';
	spy 'ACO::F::b';
	ACO::F::b();   # b BEFORE a -- wrong order
	ACO::F::a();

	my $ok;
	{
		local $TODO = 'call order failure expected';
		$ok = assert_call_order('ACO::F::a', 'ACO::F::b');
	}
	ok !$ok, 'out-of-order assertion returns false';

	Test::Mockingbird::restore_all();
};

subtest 'assert_call_order(): croaks with fewer than two names' => sub {
	throws_ok { assert_call_order('Only::One') }
		qr/assert_call_order requires at least two method names/,
		'fewer than two names croaks';
};

subtest 'clear_call_log(): empties log without touching mocks' => sub {
	{
		package CCL::P;
		sub fn { 1 }
	}
	spy 'CCL::P::fn';
	CCL::P::fn();
	clear_call_log();

	# After clearing, a call-order assertion that requires two entries
	# should fail because the log is empty.
	my $ok;
	{
		local $TODO = 'log should be empty';
		$ok = assert_call_order('CCL::P::fn', 'CCL::P::fn');
	}
	ok !$ok, 'call log empty after clear_call_log';

	# But the spy is still installed (not restored)
	CCL::P::fn();
	my $d = diagnose_mocks();
	ok exists $d->{'CCL::P::fn'}, 'spy still registered after clear_call_log';

	Test::Mockingbird::restore_all();
};

# ============================================================================
#  SECTION 10 -- diagnose_mocks() and diagnose_mocks_pretty()
# ============================================================================

subtest 'diagnose_mocks(): returns empty hashref when no mocks active' => sub {
	Test::Mockingbird::restore_all();
	my $d = diagnose_mocks();
	is ref $d, 'HASH', 'returns a hashref';
	is_deeply $d, {}, 'empty when clean';
};

subtest 'diagnose_mocks(): correct structure for a single mock layer' => sub {
	{ package DM::One; sub fn { 1 } }

	mock_return 'DM::One::fn' => 42;
	my $d = diagnose_mocks();

	ok exists $d->{'DM::One::fn'},               'entry present';
	is $d->{'DM::One::fn'}{depth},            1,  'depth is 1';
	is $d->{'DM::One::fn'}{original_existed}, 1,  'original_existed = 1';

	my $layer = $d->{'DM::One::fn'}{layers}[0];
	is $layer->{type}, $T_MOCK_RETURN, 'type is mock_return';
	like $layer->{installed_at}, qr/line \d+/, 'installed_at has line info';

	Test::Mockingbird::restore_all();
};

subtest 'diagnose_mocks(): stacked layers all reported' => sub {
	{ package DM::Multi; sub fn { 1 } }

	mock 'DM::Multi::fn' => sub { 2 };
	mock 'DM::Multi::fn' => sub { 3 };
	spy 'DM::Multi::fn';

	my $d = diagnose_mocks();
	is $d->{'DM::Multi::fn'}{depth}, 3, 'depth reflects three layers';
	is scalar @{ $d->{'DM::Multi::fn'}{layers} }, 3, 'three meta entries';

	Test::Mockingbird::restore_all();
};

subtest 'diagnose_mocks(): original_existed = 0 for newly-created method' => sub {
	# A method mocked without ever having been defined should show 0.
	mock 'DM::Ghost::only_in_mock' => sub { 'x' };
	my $d = diagnose_mocks();
	is $d->{'DM::Ghost::only_in_mock'}{original_existed}, 0,
		'original_existed = 0 for never-defined method';

	Test::Mockingbird::restore_all();
};

subtest 'diagnose_mocks_pretty(): contains required fields' => sub {
	{ package DMP::P; sub fn { 1 } }

	mock_return 'DMP::P::fn' => 99;
	my $out = diagnose_mocks_pretty();

	like $out, qr/DMP::P::fn/,       'method name present';
	like $out, qr/depth: 1/,         'depth field present';
	like $out, qr/original_existed/, 'original_existed field present';
	like $out, qr/type: mock_return/, 'type label present';
	like $out, qr/installed_at:/,    'installed_at field present';

	Test::Mockingbird::restore_all();
};

subtest 'diagnose_mocks_pretty(): methods sorted alphabetically' => sub {
	{
		package DMP::Sort;
		sub z { 1 }
		sub a { 2 }
	}

	mock 'DMP::Sort::z' => sub { 3 };
	mock 'DMP::Sort::a' => sub { 4 };

	my $out = diagnose_mocks_pretty();
	my $a_pos = index($out, 'DMP::Sort::a');
	my $z_pos = index($out, 'DMP::Sort::z');
	ok $a_pos < $z_pos, 'methods appear in alphabetical order';

	Test::Mockingbird::restore_all();
};

# ============================================================================
#  SECTION 11 -- Prototype preservation
# ============================================================================

subtest 'mock(): copies () prototype to suppress Prototype mismatch warning' => sub {
	{ package Proto::Empty; sub fn () { 'real' } }

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	mock 'Proto::Empty::fn' => sub { 'mocked' };

	my $caller = Proto::Empty->can('fn');
	my $val    = $caller->();
	unmock 'Proto::Empty::fn';

	is $val, 'mocked', 'mocked value returned via ->can() lookup';
	ok !@warnings, 'no Prototype mismatch warning';
};

subtest 'mock(): copies $$ prototype, no warning' => sub {
	{ package Proto::Two; sub fn ($$) { $_[0] + $_[1] } }

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	mock 'Proto::Two::fn' => sub { 99 };
	Proto::Two::fn(1, 2);
	restore_all();

	ok !@warnings, 'no warning for $$ prototype';
};

subtest 'mock(): no warning for no-prototype function' => sub {
	{ package Proto::None; sub fn { 'real' } }

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	mock   'Proto::None::fn' => sub { 'mocked' };
	unmock 'Proto::None::fn';

	ok !@warnings, 'no warning when original had no prototype';
};

# ============================================================================
#  SECTION 12 -- _get_prototype() and _parse_target() (repeated for completeness)
# ============================================================================

subtest '_get_prototype(): existing sub with prototype' => sub {
	{ package GP2::P; sub fn ($$) { } }
	is $get_prototype->('GP2::P::fn'), '$$', 'prototype extracted';
};

subtest '_get_prototype(): missing sub returns undef' => sub {
	{ package GP2::Q; }
	ok !defined $get_prototype->('GP2::Q::missing'), 'undef for missing sub';
};

# ============================================================================
#  SECTION 13 -- Test::Mockingbird::DeepMock
# ============================================================================

subtest '_normalize_target: shorthand Pkg::method' => sub {
	my ($pkg, $meth) = $norm_target->('My::Pkg::method');
	is $pkg,  'My::Pkg', 'package parsed';
	is $meth, 'method',  'method parsed';
};

subtest '_normalize_target: longhand two-arg form' => sub {
	my ($pkg, $meth) = $norm_target->('Foo', 'bar');
	is $pkg,  'Foo', 'package passthrough';
	is $meth, 'bar', 'method passthrough';
};

subtest '_normalize_target: delegates to _parse_target' => sub {
	# Both functions must produce identical output for the same input.
	my @via_norm  = $norm_target->('X::y');
	my @via_parse = $parse_target->('X::y');
	is_deeply \@via_norm, \@via_parse, 'results are identical';
};

subtest '_install_mocks: installs spy and mock, returns installed list' => sub {
	{
		package DM::IM;
		sub a { 1 }
		sub b { 2 }
	}

	my %handles;
	my @installed = Test::Mockingbird::DeepMock::_install_mocks(
		[
			{ target => 'DM::IM::a', type => 'spy',  tag => 'sa' },
			{ target => 'DM::IM::b', type => 'mock', tag => 'mb',
			  with => sub { 99 } },
		],
		\%handles,
	);

	is scalar @installed, 2, 'returns two installed method names';
	ok $handles{sa}{spy},   'spy handle stored';
	ok $handles{mb}{guard}, 'mock guard stored';
	is DM::IM::b(), 99, 'mocked value active';

	Test::Mockingbird::restore_all();
};

subtest '_install_mocks: inject type stores handle' => sub {
	{ package DM::Inj; sub dep { 'real' } }

	my %handles;
	Test::Mockingbird::DeepMock::_install_mocks(
		[{ target => 'DM::Inj::dep', type => 'inject', tag => 'di',
		   with => 'mocked' }],
		\%handles,
	);

	ok $handles{di}{inject}, 'inject handle stored';
	is DM::Inj::dep(), 'mocked', 'injection active';

	Test::Mockingbird::restore_all();
};

subtest '_install_mocks: croaks on missing target' => sub {
	throws_ok {
		Test::Mockingbird::DeepMock::_install_mocks(
			[{ type => 'mock', with => sub {} }], {}
		)
	} qr/missing target/, 'missing target croaks';
};

subtest '_install_mocks: croaks on unknown type' => sub {
	throws_ok {
		Test::Mockingbird::DeepMock::_install_mocks(
			[{ target => 'A::b', type => 'wut' }], {}
		)
	} qr/Unknown mock type/, 'unknown type croaks';
};

subtest '_install_mocks: croaks when mock type lacks "with" coderef' => sub {
	throws_ok {
		Test::Mockingbird::DeepMock::_install_mocks(
			[{ target => 'A::b', type => 'mock' }], {}
		)
	} qr/requires 'with' coderef/, 'missing with croaks';
};

subtest '_run_expectations: call count assertion' => sub {
	{ package DM::RE1; sub fn { 1 } }

	my %handles;
	my $spy = spy('DM::RE1', 'fn');
	$handles{s}{spy} = $spy;
	DM::RE1::fn();
	DM::RE1::fn();

	lives_ok {
		Test::Mockingbird::DeepMock::_run_expectations(
			[{ tag => 's', calls => 2 }], \%handles,
		);
	} 'call count expectation passes';

	Test::Mockingbird::restore_all();
};

subtest '_run_expectations: args_eq exact matching' => sub {
	{ package DM::RE2; sub fn { 1 } }

	my %handles;
	my $spy = spy('DM::RE2', 'fn');
	$handles{s}{spy} = $spy;
	DM::RE2::fn('exact', 42);

	lives_ok {
		Test::Mockingbird::DeepMock::_run_expectations(
			[{ tag => 's', args_eq => [['exact', 42]] }], \%handles,
		);
	} 'args_eq exact match passes';

	Test::Mockingbird::restore_all();
};

subtest '_run_expectations: args_like regex matching' => sub {
	{ package DM::RE3; sub fn { 1 } }

	my %handles;
	my $spy = spy('DM::RE3', 'fn');
	$handles{s}{spy} = $spy;
	DM::RE3::fn('hello-world');

	lives_ok {
		Test::Mockingbird::DeepMock::_run_expectations(
			[{ tag => 's', args_like => [[qr/hello/]] }], \%handles,
		);
	} 'args_like regex match passes';

	Test::Mockingbird::restore_all();
};

subtest '_run_expectations: never assertion' => sub {
	{ package DM::RE4; sub fn { 1 } }

	my %handles;
	my $spy = spy('DM::RE4', 'fn');
	$handles{s}{spy} = $spy;
	# Do NOT call fn -- "never" should pass

	lives_ok {
		Test::Mockingbird::DeepMock::_run_expectations(
			[{ tag => 's', never => 1 }], \%handles,
		);
	} 'never expectation passes when no calls made';

	Test::Mockingbird::restore_all();
};

subtest '_run_expectations: order key delegates to assert_call_order' => sub {
	{
		package DM::RE5;
		sub a { 1 }
		sub b { 2 }
	}

	spy 'DM::RE5::a';
	spy 'DM::RE5::b';
	DM::RE5::a();
	DM::RE5::b();

	lives_ok {
		Test::Mockingbird::DeepMock::_run_expectations(
			[{ order => ['DM::RE5::a', 'DM::RE5::b'] }], {},
		);
	} 'order key accepted without a tag';

	Test::Mockingbird::restore_all();
};

subtest '_run_expectations: croaks on missing spy tag' => sub {
	throws_ok {
		Test::Mockingbird::DeepMock::_run_expectations(
			[{ calls => 1 }], {},   # no tag
		)
	} qr/expectation missing tag/, 'missing tag croaks';
};

subtest '_run_expectations: croaks on missing spy handle for tag' => sub {
	throws_ok {
		Test::Mockingbird::DeepMock::_run_expectations(
			[{ tag => 'ghost', calls => 1 }],
			{},   # no handle for 'ghost'
		)
	} qr/no spy handle/, 'missing handle croaks';
};

subtest 'deep_mock(): basic end-to-end execution' => sub {
	{ package DM::E2E; sub fn { 'orig' } sub fn2 { 'orig2' } }

	my $inner_val;
	lives_ok {
		deep_mock(
			{
				mocks => [
					{ target => 'DM::E2E::fn',  type => 'mock', with => sub { 'dm_val' } },
					{ target => 'DM::E2E::fn2', type => 'spy',  tag => 'sp' },
				],
				expectations => [{ tag => 'sp', calls => 1 }],
			},
			sub { $inner_val = DM::E2E::fn(); DM::E2E::fn2() },
		);
	} 'deep_mock basic integration passes';

	is $inner_val,    'dm_val', 'mock value was active inside block';
	is DM::E2E::fn(), 'orig',   'mock removed after deep_mock';
};

subtest 'deep_mock(): exception in code block is re-thrown after restore' => sub {
	{ package DM::Err; sub fn { 'orig' } }

	my $mocked_while_throwing;
	throws_ok {
		deep_mock(
			{ mocks => [{ target => 'DM::Err::fn', type => 'mock',
			              with => sub { 'x' } }] },
			sub {
				$mocked_while_throwing = DM::Err::fn();
				die "inner error\n";
			},
		);
	} qr/inner error/, 'exception from code block is re-thrown';

	is $mocked_while_throwing, 'x', 'mock was active during block';
	is DM::Err::fn(), 'orig', 'mock removed even after exception';
};

subtest 'deep_mock(): croaks when plan is not a hashref' => sub {
	throws_ok { deep_mock('not a hashref', sub {}) }
		qr/HASHREF plan/, 'non-hashref plan croaks';
};

# ============================================================================
#  SECTION 14 -- Test::Mockingbird::TimeTravel
# ============================================================================

subtest 'TimeTravel::_parse_timestamp: ISO8601 UTC format' => sub {
	my $epoch = $parse_timestamp->('2025-01-01T00:00:00Z');
	ok $epoch =~ /^\d+$/, 'returns integer epoch';
	ok $epoch > 0,        'epoch is positive';
};

subtest 'TimeTravel::_parse_timestamp: space-separated format' => sub {
	my $e1 = $parse_timestamp->('2025-01-01T00:00:00Z');
	my $e2 = $parse_timestamp->('2025-01-01 00:00:00');
	is $e1, $e2, 'space-separated and T-separated produce same epoch';
};

subtest 'TimeTravel::_parse_timestamp: date-only defaults to midnight UTC' => sub {
	my $date = $parse_timestamp->('2025-01-01');
	my $full = $parse_timestamp->('2025-01-01T00:00:00Z');
	is $date, $full, 'date-only equals midnight UTC';
};

subtest 'TimeTravel::_parse_timestamp: raw epoch integer passthrough' => sub {
	is $parse_timestamp->(1234567890), 1234567890, 'raw epoch returned unchanged';
};

subtest 'TimeTravel::_parse_timestamp: later timestamps produce larger epochs' => sub {
	my $e1 = $parse_timestamp->('2025-01-01T00:00:00Z');
	my $e2 = $parse_timestamp->('2025-01-01T01:00:00Z');
	ok $e2 > $e1, 'later timestamp has larger epoch';
};

subtest 'TimeTravel::_parse_timestamp: rejects invalid formats' => sub {
	throws_ok { $parse_timestamp->('not-a-date') }
		qr/Invalid timestamp format/, 'free text rejected';

	throws_ok { $parse_timestamp->('2025/01/01') }
		qr/Invalid timestamp format/, 'slash-delimited date rejected';

	throws_ok { $parse_timestamp->(undef) }
		qr/Invalid timestamp format/, 'undef rejected';

	throws_ok { $parse_timestamp->('') }
		qr/Invalid timestamp format/, 'empty string rejected';
};

subtest 'TimeTravel::_parse_datetime: alias delegates to _parse_timestamp' => sub {
	my $e1 = $parse_datetime->('2025-06-01T00:00:00Z');
	my $e2 = $parse_timestamp->('2025-06-01T00:00:00Z');
	is $e1, $e2, '_parse_datetime and _parse_timestamp agree';
};

subtest 'TimeTravel::_unit_to_seconds: raw seconds (no unit)' => sub {
	is $unit_to_secs->(5), 5, 'raw integer passthrough';
};

subtest 'TimeTravel::_unit_to_seconds: known units' => sub {
	is $unit_to_secs->(1, 'second'),  1,     'second';
	is $unit_to_secs->(3, 'seconds'), 3,     'seconds (plural)';
	is $unit_to_secs->(2, 'minutes'), 120,   'minutes';
	is $unit_to_secs->(1, 'hour'),    3600,  'hour';
	is $unit_to_secs->(2, 'hours'),   7200,  'hours';
	is $unit_to_secs->(1, 'day'),     86400, 'day';
	is $unit_to_secs->(2, 'days'),    172800,'days';
};

subtest 'TimeTravel::_unit_to_seconds: case-insensitive' => sub {
	is $unit_to_secs->(1, 'HOUR'),    3600, 'upper-case HOUR';
	is $unit_to_secs->(1, 'Minutes'), 60,   'mixed-case Minutes';
};

subtest 'TimeTravel::_unit_to_seconds: croaks on unknown unit' => sub {
	throws_ok { $unit_to_secs->(1, 'fortnights') }
		qr/Unknown time unit/, 'unknown unit croaks';
};

subtest 'TimeTravel::freeze_time: activates and returns epoch' => sub {
	my $epoch = freeze_time('2025-01-01T00:00:00Z');
	ok $epoch =~ /^\d+$/, 'returns integer epoch';
	is now(), $epoch,     'now() returns frozen value';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'TimeTravel::freeze_time: accepts raw epoch integer' => sub {
	my $epoch = freeze_time(1234567890);
	is now(), 1234567890, 'raw epoch accepted';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'TimeTravel::travel_to: changes current epoch while frozen' => sub {
	freeze_time('2025-01-01T00:00:00Z');
	my $t1 = now();
	travel_to('2025-01-01T01:00:00Z');
	my $t2 = now();
	ok $t2 > $t1, 'travel_to updated epoch';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'TimeTravel::travel_to: croaks when not frozen' => sub {
	Test::Mockingbird::TimeTravel::restore_all();
	throws_ok { travel_to('2025-01-01T00:00:00Z') }
		qr/travel_to\(\) called while TimeTravel is inactive/,
		'travel_to croaks when inactive';
};

subtest 'TimeTravel::advance_time: adds seconds to frozen clock' => sub {
	freeze_time('2025-01-01T00:00:00Z');
	my $t1 = now();
	advance_time(60);
	is now(), $t1 + 60, 'advance +60 seconds';
	advance_time(2, 'minutes');
	is now(), $t1 + 60 + 120, 'advance +2 minutes';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'TimeTravel::advance_time: croaks when inactive' => sub {
	Test::Mockingbird::TimeTravel::restore_all();
	throws_ok { advance_time(10) }
		qr/advance_time\(\) called while TimeTravel is inactive/,
		'advance_time croaks when inactive';
};

subtest 'TimeTravel::rewind_time: subtracts from frozen clock' => sub {
	freeze_time('2025-01-01T00:00:00Z');
	my $t1 = now();
	rewind_time(30);
	is now(), $t1 - 30, 'rewind -30 seconds';
	rewind_time(1, 'hour');
	is now(), $t1 - 30 - 3600, 'rewind -1 hour';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'TimeTravel::rewind_time: croaks when inactive' => sub {
	Test::Mockingbird::TimeTravel::restore_all();
	throws_ok { rewind_time(10) }
		qr/rewind_time\(\) called while TimeTravel is inactive/,
		'rewind_time croaks when inactive';
};

subtest 'TimeTravel::with_frozen_time: block sees overridden time, outer restored' => sub {
	freeze_time('2025-01-01T00:00:00Z');
	my $outer = now();
	my $inner;
	with_frozen_time '2025-01-02T00:00:00Z' => sub {
		$inner = now();
	};
	is $inner, $parse_timestamp->('2025-01-02T00:00:00Z'),
		'block sees the overridden time';
	is now(), $outer, 'outer frozen time restored after block';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'TimeTravel::with_frozen_time: exception is re-thrown after state restore' => sub {
	freeze_time('2025-01-01T00:00:00Z');
	my $outer = now();

	throws_ok {
		with_frozen_time '2025-01-02T00:00:00Z' => sub { die "block error\n" };
	} qr/block error/, 'block exception propagates';

	is now(), $outer, 'outer time still correct after exception in block';
	Test::Mockingbird::TimeTravel::restore_all();
};

subtest 'TimeTravel::with_frozen_time: croaks on bad arguments' => sub {
	throws_ok { with_frozen_time undef, sub {} }
		qr/requires a timestamp/, 'undef timestamp croaks';

	throws_ok { with_frozen_time '2025-01-01', 'not_code' }
		qr/requires a coderef/, 'non-coderef croaks';
};

subtest 'TimeTravel::restore_all: returns to real time' => sub {
	freeze_time('2025-01-01T00:00:00Z');
	ok now() != CORE::time(), 'frozen time differs from real time';
	Test::Mockingbird::TimeTravel::restore_all();
	cmp_ok abs(now() - CORE::time()), '<', 3, 'real time restored';
};

subtest 'TimeTravel::restore_all: idempotent (safe to call twice)' => sub {
	freeze_time('2025-01-01T00:00:00Z');
	Test::Mockingbird::TimeTravel::restore_all();
	lives_ok { Test::Mockingbird::TimeTravel::restore_all() }
		'second restore_all does not die';
};

# ============================================================================
#  SECTION 15 -- Test::Mockingbird::Async (gated on Future being installed)
# ============================================================================

SKIP: {
	eval { require Future; 1 } or skip 'Future not installed', 10;
	require Test::Mockingbird::Async;

	# Use fully-qualified names to avoid compile-time bareword ambiguity --
	# the import happens at runtime so the parser never sees the exported names.
	my $mfr = \&Test::Mockingbird::Async::mock_future_return;
	my $mff = \&Test::Mockingbird::Async::mock_future_fail;
	my $mfs = \&Test::Mockingbird::Async::mock_future_sequence;
	my $mfo = \&Test::Mockingbird::Async::mock_future_once;
	my $asp = \&Test::Mockingbird::Async::async_spy;

	subtest 'Async::mock_future_return: returns resolved Future with value' => sub {
		{ package Async::R; sub fetch { Future->done('real') } }

		$mfr->('Async::R::fetch', 'mocked');
		my $f = Async::R::fetch();
		isa_ok $f, 'Future', 'returns a Future';
		ok $f->is_done, 'Future is resolved';
		is $f->get, 'mocked', 'resolved value correct';

		my $d = diagnose_mocks();
		is $d->{'Async::R::fetch'}{layers}[0]{type}, 'mock_future_return',
			'type is mock_future_return';

		Test::Mockingbird::restore_all();
	};

	subtest 'Async::mock_future_fail: returns pre-failed Future' => sub {
		{ package Async::F; sub fetch { Future->done('ok') } }

		$mff->('Async::F::fetch', 'not found');
		my $f = Async::F::fetch();
		ok $f->is_failed, 'Future is failed';
		my ($msg) = $f->failure;
		is $msg, 'not found', 'failure message correct';

		my $d = diagnose_mocks();
		is $d->{'Async::F::fetch'}{layers}[0]{type}, 'mock_future_fail',
			'type is mock_future_fail';

		Test::Mockingbird::restore_all();
	};

	subtest 'Async::mock_future_sequence: advances, repeats last' => sub {
		{ package Async::S; sub fetch { Future->done('real') } }

		$mfs->('Async::S::fetch', 10, 20, 30);
		is Async::S::fetch()->get, 10, 'first item';
		is Async::S::fetch()->get, 20, 'second item';
		is Async::S::fetch()->get, 30, 'third item';
		is Async::S::fetch()->get, 30, 'last item repeats';

		Test::Mockingbird::restore_all();
	};

	subtest 'Async::mock_future_sequence: pre-built Future passed through' => sub {
		{ package Async::S2; sub fetch { Future->done('real') } }

		my $pre_failed = Future->fail('injected failure');
		$mfs->('Async::S2::fetch', $pre_failed);
		my $f = Async::S2::fetch();
		ok $f->is_failed, 'pre-built failed Future passed through unchanged';

		Test::Mockingbird::restore_all();
	};

	subtest 'Async::mock_future_once: fires once, then restores' => sub {
		{ package Async::O; sub fetch { Future->done('real') } }

		$mfo->('Async::O::fetch', 'temporary');
		is Async::O::fetch()->get, 'temporary', 'first call: once value';
		is Async::O::fetch()->get, 'real',      'second call: original restored';

		my $d = diagnose_mocks();
		ok !exists $d->{'Async::O::fetch'}, 'no mock state after firing';
	};

	subtest 'Async::mock_future_once: layer type is mock_future_once' => sub {
		{ package Async::OM; sub fetch { Future->done('r') } }

		$mfo->('Async::OM::fetch', 'x');
		my $d = diagnose_mocks();
		is $d->{'Async::OM::fetch'}{layers}[0]{type}, 'mock_future_once',
			'type is mock_future_once (not mock_once)';

		Test::Mockingbird::restore_all();
	};

	subtest 'Async::async_spy: captures call records with future field' => sub {
		{ package Async::Spy; sub fetch { Future->done("result $_[0]") } }

		my $spy = $asp->('Async::Spy::fetch');
		my $f   = Async::Spy::fetch('key');
		isa_ok $f, 'Future', 'original Future returned to caller';

		my @calls = $spy->();
		is scalar @calls, 1, 'one call recorded';
		is_deeply $calls[0]{args}, ['Async::Spy::fetch', 'key'],
			'args field correct';
		isa_ok $calls[0]{future}, 'Future', 'future field holds a Future';

		Test::Mockingbird::restore_all();
	};

	subtest 'Async::async_spy: writes to assert_call_order log' => sub {
		{ package Async::Spy2; sub fn { Future->done(1) } }

		my $spy = $asp->('Async::Spy2::fn');
		Async::Spy2::fn();

		my $ok;
		{
			local $TODO = 'async spy call log';
			$ok = assert_call_order('Async::Spy2::fn', 'Async::Spy2::fn');
		}
		# We called fn once, so order with TWO entries should fail
		ok !$ok, 'one call does not satisfy two-entry order assertion';

		Test::Mockingbird::restore_all();
	};

	subtest 'Async::async_spy: croaks when target is missing' => sub {
		throws_ok { $asp->(undef) }
			qr/Package and method are required/,
			'undef target croaks';
	};
} # end SKIP

# ---------------------------------------------------------------------------
# Ensure any mock state left over from test failures is always cleaned up so
# subsequent tests in the harness are not contaminated.
# ---------------------------------------------------------------------------
Test::Mockingbird::restore_all();
Test::Mockingbird::TimeTravel::restore_all();

done_testing();
