package Yahoo::Marketing::Test::AdCarrierEditorialReasonInfo;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::AdCarrierEditorialReasonInfo;

sub test_can_create_ad_carrier_editorial_reason_info_and_set_all_fields : Test(3) {

    my $ad_carrier_editorial_reason_info = Yahoo::Marketing::AdCarrierEditorialReasonInfo->new
                                                                                         ->adEditorialReasons( 'ad editorial reasons' )
                                                                                         ->carrier( 'carrier' )
                   ;

    ok( $ad_carrier_editorial_reason_info );

    is( $ad_carrier_editorial_reason_info->adEditorialReasons, 'ad editorial reasons', 'can get ad editorial reasons' );
    is( $ad_carrier_editorial_reason_info->carrier, 'carrier', 'can get carrier' );

};



1;

