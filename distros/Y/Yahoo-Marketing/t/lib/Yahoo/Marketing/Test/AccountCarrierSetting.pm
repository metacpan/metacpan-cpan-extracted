package Yahoo::Marketing::Test::AccountCarrierSetting;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::AccountCarrierSetting;

sub test_can_create_account_carrier_setting_and_set_all_fields : Test(3) {

    my $account_carrier_setting = Yahoo::Marketing::AccountCarrierSetting->new
                                                                         ->carrier( 'carrier' )
                                                                         ->status( 'status' )
                   ;

    ok( $account_carrier_setting );

    is( $account_carrier_setting->carrier, 'carrier', 'can get carrier' );
    is( $account_carrier_setting->status, 'status', 'can get status' );

};



1;

