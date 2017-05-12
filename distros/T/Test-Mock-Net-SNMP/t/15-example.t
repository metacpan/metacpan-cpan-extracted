#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 34;

use FindBin qw( $Bin );
use File::Basename qw(dirname);
use File::Spec::Functions qw(catdir);

use lib catdir(dirname($Bin), 'lib');

use Test::Mock::Net::SNMP;
use Net::SNMP;    # only need the module for the oid types

my $mock_net_snmp = Test::Mock::Net::SNMP->new();

use lib $Bin;
use_ok('Example');

$mock_net_snmp->set_varbindlist([ { '1.3.6.1.2.1.1.3.0' => 200 } ]);

my ($host, $return);
ok(($host, $return) = Example::example1(), q{Example1 returns ok});
is($host,   q{localhost}, q{Example1 returns localhost as host});
is($return, 200,          q{Example1 returns the value set in mocked object});
is($mock_net_snmp->get_option_val('session', '-community'), 'public', q{Example1 has community set correctly});
is_deeply($mock_net_snmp->get_option_val('get_request', '-varbindlist'),
    [q{1.3.6.1.2.1.1.3.0}], q{Example1 is getting the right oid});

$mock_net_snmp->set_varbindlist([ { '1.3.6.1.2.1.1.4.0' => 'Help Desk x911' } ]);
ok(($host, $return) = Example::example2(), q{Example2 returns ok});
is($host,   q{myv3host.example.com}, q{Example2 returns the correct host});
is($return, 'Help Desk x911',        q{Example2 returns the mocked value});
is($mock_net_snmp->get_option_val('session', '-version'),      'snmpv3',       q{Example2 uses snmpv3});
is($mock_net_snmp->get_option_val('session', '-username'),     'myv3Username', q{Example2 sets username correctly});
is($mock_net_snmp->get_option_val('session', '-authprotocol'), 'sha1',         q{Example2 sets authprotocol to sha1});
is(
    $mock_net_snmp->get_option_val('session', '-authkey'),
    '0x6695febc9288e36282235fc7151f128497b38f3f',
    q{Example2 has correct authkey}
);
is($mock_net_snmp->get_option_val('session', '-privprotocol'), 'des', q{Example2 privprotocol set correctly});
is(
    $mock_net_snmp->get_option_val('session', '-privkey'),
    '0x6695febc9288e36282235fc7151f1284',
    q{Example2 privkey is correct}
);
is_deeply(
    $mock_net_snmp->get_option_val('set_request', '-varbindlist'),
    [ '1.3.6.1.2.1.1.4.0', OCTET_STRING, 'Help Desk x911' ],
    'Example2 passes the right arguments to set_request'
);

$mock_net_snmp->reset_values();
$mock_net_snmp->set_varbindlist(
    [
        { '1.3.6.1.2.1.2.2.1' => 1, '1.3.6.1.2.1.2.2.2' => 2, '1.3.6.1.2.1.2.2.3' => 3, '1.3.6.1.2.1.2.2.4' => 4 },
        { '1.3.6.1.2.1.2.2.5' => 5, '1.3.6.1.2.1.2.3.1' => 1, '1.3.6.1.2.1.2.3.2' => 2, '1.3.6.1.2.1.2.3.3' => 5 }
    ]
);

my $table;
ok($table = Example::example3(), q{Example3 returns ok});
is_deeply(
    $table,
    {
        '1.3.6.1.2.1.2.2.1' => 1,
        '1.3.6.1.2.1.2.2.2' => 2,
        '1.3.6.1.2.1.2.2.3' => 3,
        '1.3.6.1.2.1.2.2.4' => 4,
        '1.3.6.1.2.1.2.2.5' => 5
    },
    q{Example3 returns the table hash}
);
is($mock_net_snmp->get_option_val('session', '-version'),   'snmpv2c',   q{Example3 uses snmpv2c});
is($mock_net_snmp->get_option_val('session', '-hostname'),  'localhost', q{Example3 uses localhost});
is($mock_net_snmp->get_option_val('session', '-community'), 'public',    q{Example3 uses public});
is_deeply($mock_net_snmp->get_option_val('get_bulk_request', '-varbindlist', 0),
    ['1.3.6.1.2.1.2.2'], q{Example3 first call to get_bulk_request is the table oid});
is_deeply($mock_net_snmp->get_option_val('get_bulk_request', '-varbindlist'),
    ['1.3.6.1.2.1.2.2.4'],
    q{Example3 last call to get_bulk_request is the last oid in the first element of varbindlist});

$mock_net_snmp->set_varbindlist(
    [
        { '1.3.6.1.2.1.1.3.0' => 600 },
        { '1.3.6.1.2.1.1.4.0' => 'Help Desk x911', '1.3.6.1.2.1.1.6.0' => 'Building 1, Second Floor' },
        { '1.3.6.1.2.1.1.3.0' => 600 },
        { '1.3.6.1.2.1.1.4.0' => 'Help Desk x911', '1.3.6.1.2.1.1.6.0' => 'Building 2, First Floor' },
        { '1.3.6.1.2.1.1.3.0' => 600 },
        { '1.3.6.1.2.1.1.4.0' => 'Help Desk x911', '1.3.6.1.2.1.1.6.0' => 'Right here!' }
    ]
);

ok(Example::example4(), q{Example4 returns true});
is($mock_net_snmp->get_num_method_calls('set_request'), 3, q{Example4 calls set_request 3 times});
is($mock_net_snmp->get_num_method_calls('get_request'), 3, q{Example4 calls get_request 3 times});

$mock_net_snmp->reset_values();
$mock_net_snmp->set_varbindlist(
    [
        { '1.3.6.1.2.1.1.3.0' => 600 },
        { '1.3.6.1.2.1.1.4.0' => 'Help Desk x911', '1.3.6.1.2.1.1.6.0' => 'Building 1, Second Floor' },
        undef,
        { '1.3.6.1.2.1.1.3.0' => 600 },
        { '1.3.6.1.2.1.1.4.0' => 'Help Desk x911', '1.3.6.1.2.1.1.6.0' => 'Right here!' }
    ]
);
$mock_net_snmp->set_error('failed varbindlist call');
ok(Example::example4(), q{Example4 returns true when a get request returns undef});
is($mock_net_snmp->get_num_method_calls('set_request'), 2, q{Example4 calls set_request 2 times when a get request returns undef});
is($mock_net_snmp->get_num_method_calls('get_request'), 3, q{Example4 calls get_request 3 times when a get request returns undef});

SKIP: {
    eval { require Test::Exception; Test::Exception->import };

    skip "Test::Exception not installed", 7 if $@;

    $mock_net_snmp->set_session_failure();
    dies_ok(sub { Example::example1() }, q{Example1 dies with session failure});
    dies_ok(sub { Example::example2() }, q{Example2 dies with session failure});
    dies_ok(sub { Example::example3() }, q{Example3 dies with session failure});

    $mock_net_snmp->reset_values();
    dies_ok(sub { Example::example1() }, q{Example1 dies with no varbindlist});
    dies_ok(sub { Example::example2() }, q{Example2 dies with no varbindlist});
}
