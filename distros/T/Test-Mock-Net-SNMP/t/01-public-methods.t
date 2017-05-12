#!/usr/bin/perl
use strict;
use warnings;

use FindBin qw( $Bin );
use File::Basename qw(dirname);
use File::Spec::Functions qw(catdir);

use lib catdir(dirname($Bin), 'lib');

use Test::More tests => 26;
use Test::Exception;

BEGIN { use_ok('Test::Mock::Net::SNMP') }

use Net::SNMP;

can_ok('Test::Mock::Net::SNMP',
    qw( new set_varbindlist set_varbindtypes set_session_failure set_error set_error_status set_error_index get_option_val get_num_method_calls reset_values )
);

my $obj = new_ok('Test::Mock::Net::SNMP');

ok(
    $obj->set_varbindlist(
        [
            { '1.2.1.1' => 'test', '1.2.1.2' => 'test2', '1.2.1.3' => 'test3' },
            { '1.2.2.1' => 'tset', '1.2.2.2' => 'tset2', '1.2.2.3' => 'tset3' }
        ]
    ),
    'setting up var bind list'
);
is_deeply(
    $obj->{varbindlist},
    [
        { '1.2.1.1' => 'test', '1.2.1.2' => 'test2', '1.2.1.3' => 'test3' },
        { '1.2.2.1' => 'tset', '1.2.2.2' => 'tset2', '1.2.2.3' => 'tset3' }
    ],
    'varbindlist set correctly'
);
is_deeply(
    $obj->{varbindnames},
    [ [ '1.2.1.1', '1.2.1.2', '1.2.1.3' ], [ '1.2.2.1', '1.2.2.2', '1.2.2.3' ] ],
    'varbindnames set correctly'
);

ok(
    $obj->set_varbindtypes(
        [
            { '1.2.1.1' => OCTET_STRING, '1.2.1.2' => OCTET_STRING, '1.2.1.3' => OCTET_STRING },
            { '1.2.2.1' => OCTET_STRING, '1.2.2.2' => OCTET_STRING, '1.2.2.3' => OCTET_STRING }
        ]
    ),
    'setting up varbindtypes'
);
is_deeply(
    $obj->{varbindtypes},
    [
        { '1.2.1.1' => OCTET_STRING, '1.2.1.2' => OCTET_STRING, '1.2.1.3' => OCTET_STRING },
        { '1.2.2.1' => OCTET_STRING, '1.2.2.2' => OCTET_STRING, '1.2.2.3' => OCTET_STRING }
    ],
    'varbindtypes contains correct values'
);

ok($obj->set_session_failure(), 'can set session failure');
is($obj->{session_failure}, 1, 'session failure has been set');
is($obj->{net_snmp}->session(-hostname => 'blah'), undef, 'session failure causes mocked session method to fail');
is($obj->get_option_val('session', '-hostname'), 'blah', 'object still captures session options despite failure');
dies_ok(sub { $obj->get_option_val('made',    'up') },       'get_option_val dies with unknown method');
dies_ok(sub { $obj->get_option_val('session', 'variable') }, 'get_option_val dies with unset variable');
ok($obj->set_error('This is an error'), 'can set error');
is($obj->{error},             'This is an error', 'object stores error internally');
is($obj->{net_snmp}->error(), 'This is an error', 'mocked error method returns error message');
ok($obj->set_error_status(1), 'can set error status');
is($obj->{error_status},             1, 'object stores error status internally');
is($obj->{net_snmp}->error_status(), 1, 'mocked method returns objects error status');
ok($obj->set_error_index(1), 'can set error index');
is($obj->{error_index},             1, 'object stores error index internally');
is($obj->{net_snmp}->error_index(), 1, 'mocked method returns objects error index');
ok($obj->reset_values(),            'can reset values');
ok(exists $obj->{net_snmp},         'reset values does not get rid of mocked object');
ok(!exists $obj->{session_failure}, 'reset values only leaves the mocked object');
