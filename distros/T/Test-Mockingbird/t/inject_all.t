use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;

# -----------------------------------------------------------------
# Setup: a service package with several dependency accessors
# -----------------------------------------------------------------
{
    package My::Service;
    sub DB     { 'real_db'     }
    sub Logger { 'real_logger' }
    sub Cache  { 'real_cache'  }
    sub value  { 42            }
}

# -----------------------------------------------------------------
# 1. Basic multi-dependency injection
# -----------------------------------------------------------------
{
    inject_all('My::Service', {
        DB     => 'mock_db',
        Logger => 'mock_logger',
    });

    is My::Service::DB(),     'mock_db',     'DB injected';
    is My::Service::Logger(), 'mock_logger', 'Logger injected';
    is My::Service::Cache(),  'real_cache',  'Cache untouched';

    restore_all();

    is My::Service::DB(),     'real_db',     'DB restored';
    is My::Service::Logger(), 'real_logger', 'Logger restored';
}

# -----------------------------------------------------------------
# 2. Injected values can be objects, arrayrefs, coderefs, undef
# -----------------------------------------------------------------
{
    my $mock_obj  = bless { type => 'db' }, 'Mock::DB';
    my $mock_code = sub { 'from_code' };

    inject_all('My::Service', {
        DB     => $mock_obj,
        Logger => $mock_code,
        Cache  => undef,
    });

    is ref My::Service::DB(),     'Mock::DB', 'object injected';
    is My::Service::Logger()->(),  'from_code', 'coderef injected and callable';
    ok !defined My::Service::Cache(),          'undef injected';

    restore_all();
}

# -----------------------------------------------------------------
# 3. Empty hashref is a no-op (no croaks, no injections)
# -----------------------------------------------------------------
{
    lives_ok { inject_all('My::Service', {}) } 'empty hashref is a no-op';
    is My::Service::value(), 42, 'value() unaffected after empty inject_all';
    restore_all();
}

# -----------------------------------------------------------------
# 4. restore_all removes all injected dependencies
# -----------------------------------------------------------------
{
    inject_all('My::Service', {
        DB     => 'mock_db',
        Logger => 'mock_logger',
        Cache  => 'mock_cache',
    });

    restore_all();

    is My::Service::DB(),     'real_db',     'DB restored by restore_all';
    is My::Service::Logger(), 'real_logger', 'Logger restored by restore_all';
    is My::Service::Cache(),  'real_cache',  'Cache restored by restore_all';
}

# -----------------------------------------------------------------
# 5. Individual unmock after inject_all
# -----------------------------------------------------------------
{
    inject_all('My::Service', {
        DB     => 'mock_db',
        Logger => 'mock_logger',
    });

    unmock 'My::Service::DB';

    is My::Service::DB(),     'real_db',     'DB restored by unmock';
    is My::Service::Logger(), 'mock_logger', 'Logger still injected';

    restore_all();
    is My::Service::Logger(), 'real_logger', 'Logger restored by restore_all';
}

# -----------------------------------------------------------------
# 6. diagnose_mocks records all injected layers
# -----------------------------------------------------------------
{
    inject_all('My::Service', {
        DB     => 'mock_db',
        Logger => 'mock_logger',
    });

    my $diag = diagnose_mocks();

    ok exists $diag->{'My::Service::DB'},     'DB recorded in diagnose_mocks';
    ok exists $diag->{'My::Service::Logger'}, 'Logger recorded in diagnose_mocks';

    is $diag->{'My::Service::DB'}{layers}[0]{type},     'inject', 'DB layer type is inject';
    is $diag->{'My::Service::Logger'}{layers}[0]{type}, 'inject', 'Logger layer type is inject';

    restore_all();
}

# -----------------------------------------------------------------
# 7. Error: missing package argument
# -----------------------------------------------------------------
dies_ok { inject_all(undef, { DB => 'x' }) } 'undef package croaks';
dies_ok { inject_all('',    { DB => 'x' }) } 'empty string package croaks';

# -----------------------------------------------------------------
# 8. Error: second argument is not a hashref
# -----------------------------------------------------------------
dies_ok { inject_all('My::Service', 'not_a_hashref') } 'scalar second arg croaks';
dies_ok { inject_all('My::Service', [qw(DB Logger)])  } 'arrayref second arg croaks';

done_testing();
