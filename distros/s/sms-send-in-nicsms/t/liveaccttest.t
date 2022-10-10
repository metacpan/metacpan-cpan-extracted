#!/usr/bin/env perl
#
use strict;
use warnings;

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl SMS-Send-IN-NICSMS.t'

#########################
#  Actual live test of sending transactional SMS via NIC's SMS Gateway
#  Requires a properly setup account with at least one DLT approved content
#  template along with login credentials

use Test::More;
use SMS::Send;

if ( $ENV{'NIC_LOGIN'} && $ENV{'NIC_PASS'} && $ENV{'NIC_SENDERID'} && $ENV{'NIC_ENTITY_ID'} && $ENV{'NIC_DEST'} && $ENV{'NIC_TEXT'} && $ENV{'NIC_TEMPLATE_ID'}) {
    plan tests => 2;
} else {
    plan skip_all => 'No or insufficient parameters available, skipping all tests.';
}

# Get the sender and login
my $sender = SMS::Send->new( 'IN::NICSMS',
                             _login         => $ENV{'NIC_LOGIN'},
                             _password      => $ENV{'NIC_PASS'},
                             _signature     => $ENV{'NIC_SENDERID'},
                             _dlt_entity_id => $ENV{'NIC_ENTITY_ID'},
                        );

isa_ok( $sender, 'SMS::Send' );

my $sent = $sender->send_sms( text             => $ENV{'NIC_TEXT'},
                              to               => $ENV{'NIC_DEST'},
                              _dlt_template_id => $ENV{'NIC_TEMPLATE_ID'},
                         );

ok( $sent );
