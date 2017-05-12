#!/usr/bin/perl
use strict;
use warnings;

use FindBin qw( $Bin );
use File::Basename qw(dirname);
use File::Spec::Functions qw(catdir);

use lib catdir(dirname($Bin), 'lib');

use Test::More tests => 29;

use Test::Mock::Net::SNMP;
use Net::SNMP;

my $mock_net_snmp = Test::Mock::Net::SNMP->new();

my ($snmp, $error) = Net::SNMP->session(-hostname => 'localhost', -version => 'v2c');

ok($snmp->close(), 'can close the mocked snmp object');
is($mock_net_snmp->{closed}, 1, 'tmns object has closed set');
ok(!defined $snmp->get_request(-varbindlist => [ '1.1.1', '1.1.2' ]), q{Can't make get request on closed object});
is($mock_net_snmp->{error}, q{Can't call method on closed object}, q{get_request error message is set correctly});
is_deeply(
    $mock_net_snmp->get_option_val('get_request', '-varbindlist'),
    [ '1.1.1', '1.1.2' ],
    'tmns stores get_request options even if mocked object is closed'
);
ok(!defined $snmp->get_next_request(-varbindlist => [ '1.1.1', '1.1.2' ]),
    q{Can't make get next request on closed object});
is($mock_net_snmp->{error}, q{Can't call method on closed object}, q{get_next_request error message is set correctly});
is_deeply(
    $mock_net_snmp->get_option_val('get_next_request', '-varbindlist'),
    [ '1.1.1', '1.1.2' ],
    'tmns stores get_next_request options even if mocked object is closed'
);
ok(!defined $snmp->set_request(-varbindlist => [ '1.1.1', '1.1.2' ]), q{Can't make set request on closed object});
is($mock_net_snmp->{error}, q{Can't call method on closed object}, q{set_request error message is set correctly});
is_deeply(
    $mock_net_snmp->get_option_val('set_request', '-varbindlist'),
    [ '1.1.1', '1.1.2' ],
    'tmns stores set_request options even if mocked object is closed'
);
ok(!defined $snmp->trap(-varbindlist => [ '1.1.1', '1.1.2' ]), q{Can't make trap request on closed object});
is($mock_net_snmp->{error}, q{Can't call method on closed object}, q{trap error message is set correctly});
is_deeply(
    $mock_net_snmp->get_option_val('trap', '-varbindlist'),
    [ '1.1.1', '1.1.2' ],
    'tmns stores trap options even if mocked object is closed'
);
ok(!defined $snmp->get_bulk_request(-varbindlist => [ '1.1.1', '1.1.2' ]),
    q{Can't make get bulk request on closed object});
is($mock_net_snmp->{error}, q{Can't call method on closed object}, q{get_bulk_request error message is set correctly});
is_deeply(
    $mock_net_snmp->get_option_val('get_bulk_request', '-varbindlist'),
    [ '1.1.1', '1.1.2' ],
    'tmns stores get_bulk_request options even if mocked object is closed'
);
ok(!defined $snmp->inform_request(-varbindlist => [ '1.1.1', '1.1.2' ]), q{Can't make inform request on closed object});
is($mock_net_snmp->{error}, q{Can't call method on closed object}, q{inform_request error message is set correctly});
is_deeply(
    $mock_net_snmp->get_option_val('inform_request', '-varbindlist'),
    [ '1.1.1', '1.1.2' ],
    'tmns stores inform_request options even if mocked object is closed'
);
ok(!defined $snmp->snmpv2_trap(-varbindlist => [ '1.1.1', '1.1.2' ]), q{Can't call snmpv2_trap on closed object});
is($mock_net_snmp->{error}, q{Can't call method on closed object}, q{snmpv2_trap error message is set correctly});
is_deeply(
    $mock_net_snmp->get_option_val('snmpv2_trap', '-varbindlist'),
    [ '1.1.1', '1.1.2' ],
    'tmns stores snmpv2_trap options even if mocked object is closed'
);
ok(!defined $snmp->get_table(-varbindlist => [ '1.1.1', '1.1.2' ]), q{Can't make get table request on closed object});
is($mock_net_snmp->{error}, q{Can't call method on closed object}, q{get_table error message is set correctly});
is_deeply(
    $mock_net_snmp->get_option_val('get_table', '-varbindlist'),
    [ '1.1.1', '1.1.2' ],
    'tmns stores get_table options even if mocked object is closed'
);
ok(!defined $snmp->get_entries(-varbindlist => [ '1.1.1', '1.1.2' ]), q{Can't call get entries on closed object});
is($mock_net_snmp->{error}, q{Can't call method on closed object}, q{get_entries error message is set correctly});
is_deeply(
    $mock_net_snmp->get_option_val('get_entries', '-varbindlist'),
    [ '1.1.1', '1.1.2' ],
    'tmns stores get_entries options even if mocked object is closed'
);
