#!/usr/bin/perl
use strict;
use warnings;

use FindBin qw( $Bin );
use File::Basename qw(dirname);
use File::Spec::Functions qw(catdir);

use lib catdir(dirname($Bin), 'lib');

use Test::More tests => 33;

use Test::Mock::Net::SNMP;
use Net::SNMP;

my $mock_net_snmp = Test::Mock::Net::SNMP->new();

my ($snmp, $error) = Net::SNMP->session();

#defaults
is($snmp->version(),      1,           'mocked version returns the default 1');
is($snmp->hostname(),     'localhost', 'mocked hostname returns the default localhost');
is($snmp->error_status(), 0,           'mocked error status returns the default 0');
is($snmp->error_index(),  0,           'mocked error index returns the default 0');
is($snmp->timeout(),      5.0,         'mocked timeout returns the default 5.0');
is($snmp->timeout(5.5),   5.5,         'can set timeout');
is($snmp->timeout(),      5.5,         'changed timeout is returned with next call');
is($snmp->retries(),      1,           'mocked retries returns the default 1');
is($snmp->retries(2),     2,           'can set retries');
is($snmp->retries(),      2,           'changed retries is returned with next call');
ok(!defined $snmp->retries(21), 'retries greater than max returns undef');
is($snmp->error(), 'retries out of range', 'retries out of range error set if greater than max');
ok(!defined $snmp->retries(-1), 'retries less than min returns undef');
is($snmp->error(),            'retries out of range', 'retries out of range error set if less than min');
is($snmp->max_msg_size(),     1472,                   'mocked max msg size returns the default 1472');
is($snmp->max_msg_size(1655), 1655,                   'can set the max msg size');
is($snmp->max_msg_size(),     1655,                   'changed max msg size is returned with next call');
ok(!defined $snmp->max_msg_size(65536), 'msg size greater than max returns undef');
is($snmp->error(), 'max msg size out of range', 'out of range error set if greater than max');
ok(!defined $snmp->max_msg_size(483), 'msg size less than min returns undef');
is($snmp->error(),      'max msg size out of range', 'out of range error set if less than min');
is($snmp->translate(),  1,                           'default translate is 1');
is($snmp->translate(2), 2,                           'can set translate');
is($snmp->translate(),  2,                           'once set translate stays set');
is($snmp->debug(),      0,                           'default debug is 0');
is($snmp->debug(2),     2,                           'can set debug');
is($snmp->debug(),      2,                           'once set debug stays set');

$snmp = Net::SNMP->session(-hostname => 'blah', -version => 'snmpv2c');
is($snmp->version(),  2,      'mocked version returns the session variable');
is($snmp->hostname(), 'blah', 'mocked hostname returns the session variable');

$mock_net_snmp->set_varbindlist(
    [
        { '1.2.1.1' => 'test', '1.2.1.2' => 'test2', '1.2.1.3' => 'test3' },
        { '1.2.2.1' => 'tset', '1.2.2.2' => 'tset2', '1.2.2.3' => 'tset3' }
    ]
);

$mock_net_snmp->set_varbindtypes(
    [
        { '1.2.1.1' => OCTET_STRING, '1.2.1.2' => OCTET_STRING, '1.2.1.3' => OCTET_STRING },
        { '1.2.2.1' => OCTET_STRING, '1.2.2.2' => OCTET_STRING, '1.2.2.3' => OCTET_STRING }
    ]
);

is_deeply(
    $snmp->var_bind_list(),
    { '1.2.1.1' => 'test', '1.2.1.2' => 'test2', '1.2.1.3' => 'test3' },
    'check mocked var_bind_list'
);
my @names = $snmp->var_bind_names();
is_deeply(\@names, [qw( 1.2.1.1 1.2.1.2 1.2.1.3 )], 'check automatically created var_bind_names');
is_deeply(
    $snmp->var_bind_types(),
    { '1.2.1.1' => OCTET_STRING, '1.2.1.2' => OCTET_STRING, '1.2.1.3' => OCTET_STRING },
    'check var_bind_types returns'
);

$mock_net_snmp->set_varbindnames([ [qw( 2.2.1 2.2.3 2.2.4 )] ]);
@names = $snmp->var_bind_names();
is_deeply(\@names, [qw( 2.2.1 2.2.3 2.2.4 )], 'check manually created var_bind_names');

