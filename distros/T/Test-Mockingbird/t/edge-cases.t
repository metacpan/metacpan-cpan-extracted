use strict;
use warnings;
use Test::Most;
use Test::Mockingbird;

# A dummy package for testing
{
	package Edge::Target;
	sub a   { 'A' }
	sub b   { 'B' }
	sub c   { 'C' }
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

subtest 'mock(): undef replacement becomes empty sub' => sub {
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
    dies_ok { mock_once 'Edge::Target::x' => undef }
        'undef coderef rejected';
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

done_testing();
