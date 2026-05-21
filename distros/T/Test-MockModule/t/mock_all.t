use warnings;
use strict;

use Test::More;
use Test::Warnings;

use Test::MockModule;

# Set up test package with multiple subs
{
    package MockAllTarget; ## no critic (Modules::RequireFilenameMatchesPackage)
    our $VERSION = 1;

    sub alpha   { return 'alpha' }
    sub beta    { return 'beta' }
    sub gamma   { return 'gamma' }
    sub _private { return 'private' }
    sub import  { return 'import' }  # should be skipped
}

# 1. Default behavior: die on unmocked call
{
    my $mock = Test::MockModule->new('MockAllTarget');
    $mock->mock_all();

    eval { MockAllTarget::alpha() };
    like( $@, qr/MockAllTarget::alpha was not mocked/, 'mock_all dies on unmocked call (alpha)' );

    eval { MockAllTarget::beta() };
    like( $@, qr/MockAllTarget::beta was not mocked/, 'mock_all dies on unmocked call (beta)' );

    # import should NOT be mocked
    is( MockAllTarget::import(), 'import', 'mock_all skips import()' );
}

# Verify unmocking restores originals
is( MockAllTarget::alpha(), 'alpha', 'alpha restored after mock object goes out of scope' );
is( MockAllTarget::beta(), 'beta', 'beta restored after mock object goes out of scope' );

# 2. noop mode
# GH #81 contract: mock_all(noop => 1) MUST return 1 (truthy), to stay consistent
# with noop() — see lib/Test/MockModule.pm POD. Do not "fix" these assertions to
# undef without auditing the public-API impact.
{
    my $mock = Test::MockModule->new('MockAllTarget');
    $mock->mock_all(noop => 1);

    is( MockAllTarget::alpha(), 1, 'noop mode returns 1 (alpha) (GH #81 contract — DO NOT CHANGE)' );
    is( MockAllTarget::beta(),  1, 'noop mode returns 1 (beta) (GH #81 contract — DO NOT CHANGE)' );
}
is( MockAllTarget::alpha(), 'alpha', 'alpha restored after noop mock goes out of scope' );

# 3. Custom handler
{
    my $mock = Test::MockModule->new('MockAllTarget');
    $mock->mock_all(handler => sub { return 'handled' });

    is( MockAllTarget::alpha(), 'handled', 'custom handler works (alpha)' );
    is( MockAllTarget::gamma(), 'handled', 'custom handler works (gamma)' );
}
is( MockAllTarget::gamma(), 'gamma', 'gamma restored after handler mock goes out of scope' );

# 4. Already-mocked subs are skipped
{
    my $mock = Test::MockModule->new('MockAllTarget');
    $mock->redefine('alpha', sub { return 'custom_alpha' });
    $mock->mock_all();

    is( MockAllTarget::alpha(), 'custom_alpha', 'already-mocked sub keeps its mock' );
    eval { MockAllTarget::beta() };
    like( $@, qr/MockAllTarget::beta was not mocked/, 'non-mocked sub gets mock_all treatment' );
}

# 5. Chaining works
{
    my $mock = Test::MockModule->new('MockAllTarget');
    my $ret = $mock->mock_all(noop => 1);
    is( $ret, $mock, 'mock_all returns $self for chaining' );
}

# 6. Private subs are mocked too
{
    my $mock = Test::MockModule->new('MockAllTarget');
    $mock->mock_all();

    eval { MockAllTarget::_private() };
    like( $@, qr/MockAllTarget::_private was not mocked/, 'private subs are mocked by mock_all' );
}

# 7. Selective unmocking after mock_all
{
    my $mock = Test::MockModule->new('MockAllTarget');
    $mock->mock_all();
    $mock->unmock('alpha');

    is( MockAllTarget::alpha(), 'alpha', 'unmock restores individual sub after mock_all' );
    eval { MockAllTarget::beta() };
    like( $@, qr/MockAllTarget::beta was not mocked/, 'other subs remain mocked' );
}

# 8. mock_all + redefine specific subs
{
    my $mock = Test::MockModule->new('MockAllTarget');
    $mock->mock_all();
    $mock->redefine('alpha', sub { return 'real_mock' });

    is( MockAllTarget::alpha(), 'real_mock', 'redefine after mock_all works' );
    eval { MockAllTarget::beta() };
    like( $@, qr/MockAllTarget::beta was not mocked/, 'mock_all still covers other subs' );
}

# 9. Special Perl subs are skipped by mock_all
{
    package SpecialSubTarget;
    our $VERSION = 1;

    sub new     { return bless {}, shift }
    sub alpha   { return 'alpha' }
    sub DESTROY { }
    sub AUTOLOAD { our $AUTOLOAD; return "auto:$AUTOLOAD" }
    sub BEGIN { }   # technically already ran, but the symbol exists
    sub import  { return 'import' }

    # Simulate overloaded operator subs (these appear in the stash with '(' prefix)
    use overload '""' => sub { 'stringified' }, fallback => 1;
}

{
    # Create object BEFORE mocking so new() works
    my $obj = SpecialSubTarget->new();

    my $mock = Test::MockModule->new('SpecialSubTarget');
    $mock->mock_all();

    # alpha should be mocked (normal sub)
    eval { SpecialSubTarget::alpha() };
    like( $@, qr/SpecialSubTarget::alpha was not mocked/, 'normal sub is mocked by mock_all' );

    # DESTROY should NOT be mocked — mocking it causes crashes during cleanup
    # If DESTROY were mocked, this would croak when $obj goes out of scope
    undef $obj;
    pass('DESTROY is skipped by mock_all — no crash on object cleanup');

    # import should NOT be mocked
    is( SpecialSubTarget::import(), 'import', 'import is skipped by mock_all' );
}

# Verify the skip list by inspecting which subs got mocked
{
    my $mock = Test::MockModule->new('SpecialSubTarget');
    $mock->mock_all(noop => 1);

    ok( !$mock->is_mocked('DESTROY'),  'DESTROY is not mocked by mock_all' );
    ok( !$mock->is_mocked('AUTOLOAD'), 'AUTOLOAD is not mocked by mock_all' );
    ok( !$mock->is_mocked('import'),   'import is not mocked by mock_all' );

    # Overload subs (starting with '(') should be skipped
    my $has_overload_sub = 0;
    {
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        for my $name (keys %{'SpecialSubTarget::'}) {
            if ($name =~ /^\(/ && defined &{"SpecialSubTarget::$name"}) {
                ok( !$mock->is_mocked($name), "overload sub '$name' is not mocked by mock_all" );
                $has_overload_sub = 1;
            }
        }
    }
    ok( $has_overload_sub, 'SpecialSubTarget has at least one overload sub to test' );

    # But normal subs ARE mocked
    ok( $mock->is_mocked('alpha'), 'normal sub alpha IS mocked' );
    ok( $mock->is_mocked('new'),   'new IS mocked' );
}

done_testing();
