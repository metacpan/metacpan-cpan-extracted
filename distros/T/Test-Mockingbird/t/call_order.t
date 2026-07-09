use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;
use Test::Mockingbird::DeepMock qw(deep_mock);

# -----------------------------------------------------------------
# Setup: three tiny packages to spy on
# -----------------------------------------------------------------
{
    package Step::A;
    sub fetch   { 'real_fetch'   }
}
{
    package Step::B;
    sub process { 'real_process' }
}
{
    package Step::C;
    sub save    { 'real_save'    }
}

# -----------------------------------------------------------------
# 1. Correct order passes
# -----------------------------------------------------------------
{
    spy 'Step::A::fetch';
    spy 'Step::B::process';
    spy 'Step::C::save';

    Step::A::fetch();
    Step::B::process();
    Step::C::save();

    assert_call_order('Step::A::fetch', 'Step::B::process', 'Step::C::save');

    restore_all();
}

# -----------------------------------------------------------------
# 2. Wrong order fails (test the failure path without breaking the suite)
# -----------------------------------------------------------------
{
    spy 'Step::A::fetch';
    spy 'Step::B::process';

    Step::B::process();   # B before A
    Step::A::fetch();

    my $result;
    {
        # $TODO makes the harness ignore the expected not-ok while still
        # letting us capture the boolean return value.
        local $TODO = 'deliberate wrong-order assertion';
        $result = assert_call_order('Step::A::fetch', 'Step::B::process');
    }

    ok(!$result, 'assert_call_order returns false when order is wrong');

    restore_all();
}

# -----------------------------------------------------------------
# 3. Intervening calls are ignored
# -----------------------------------------------------------------
{
    spy 'Step::A::fetch';
    spy 'Step::B::process';
    spy 'Step::C::save';

    Step::A::fetch();
    Step::C::save();       # extra call in between
    Step::B::process();

    assert_call_order('Step::A::fetch', 'Step::B::process');  # C ignored

    restore_all();
}

# -----------------------------------------------------------------
# 4. clear_call_log resets between phases
# -----------------------------------------------------------------
{
    spy 'Step::A::fetch';
    spy 'Step::B::process';

    Step::B::process();
    Step::A::fetch();

    clear_call_log();

    Step::A::fetch();
    Step::B::process();

    assert_call_order('Step::A::fetch', 'Step::B::process');

    restore_all();
}

# -----------------------------------------------------------------
# 5. DeepMock 'order' expectation
# -----------------------------------------------------------------
{
    package Svc::Alpha;
    sub open  { 1 }
}
{
    package Svc::Beta;
    sub close { 1 }
}

deep_mock(
    {
        mocks => [
            { target => 'Svc::Alpha::open',  type => 'spy', tag => 'open'  },
            { target => 'Svc::Beta::close',  type => 'spy', tag => 'close' },
        ],
        expectations => [
            { tag => 'open',  calls => 1 },
            { tag => 'close', calls => 1 },
            { order => [ 'Svc::Alpha::open', 'Svc::Beta::close' ] },
        ],
    },
    sub {
        Svc::Alpha::open();
        Svc::Beta::close();
    }
);

done_testing();
