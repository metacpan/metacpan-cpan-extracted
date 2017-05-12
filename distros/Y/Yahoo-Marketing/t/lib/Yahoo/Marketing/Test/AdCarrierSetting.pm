package Yahoo::Marketing::Test::AdCarrierSetting;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::AdCarrierSetting;

sub test_can_create_ad_carrier_setting_and_set_all_fields : Test(4) {

    my $ad_carrier_setting = Yahoo::Marketing::AdCarrierSetting->new
                                                               ->carrier( 'carrier' )
                                                               ->editorialStatus( 'editorial status' )
                                                               ->status( 'status' )
                   ;

    ok( $ad_carrier_setting );

    is( $ad_carrier_setting->carrier, 'carrier', 'can get carrier' );
    is( $ad_carrier_setting->editorialStatus, 'editorial status', 'can get editorial status' );
    is( $ad_carrier_setting->status, 'status', 'can get status' );

};



1;

