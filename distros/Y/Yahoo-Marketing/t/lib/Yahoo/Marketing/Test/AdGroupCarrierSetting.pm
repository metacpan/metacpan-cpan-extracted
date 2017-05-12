package Yahoo::Marketing::Test::AdGroupCarrierSetting;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::AdGroupCarrierSetting;

sub test_can_create_ad_group_carrier_setting_and_set_all_fields : Test(5) {

    my $ad_group_carrier_setting = Yahoo::Marketing::AdGroupCarrierSetting->new
                                                                          ->carrier( 'carrier' )
                                                                          ->sponsoredSearchMaxBid( 'sponsored search max bid' )
                                                                          ->status( 'status' )
                                                                          ->sponsoredSearchMaxBidTimestamp( '2008-01-06T17:51:55' )
                   ;

    ok( $ad_group_carrier_setting );

    is( $ad_group_carrier_setting->carrier, 'carrier', 'can get carrier' );
    is( $ad_group_carrier_setting->sponsoredSearchMaxBid, 'sponsored search max bid', 'can get sponsored search max bid' );
    is( $ad_group_carrier_setting->status, 'status', 'can get status' );
    is( $ad_group_carrier_setting->sponsoredSearchMaxBidTimestamp, '2008-01-06T17:51:55', 'can get 2008-01-06T17:51:55' );

};



1;

