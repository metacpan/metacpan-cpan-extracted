package Yahoo::Marketing::Test::KeywordCarrierSetting;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::KeywordCarrierSetting;

sub test_can_create_keyword_carrier_setting_and_set_all_fields : Test(6) {

    my $keyword_carrier_setting = Yahoo::Marketing::KeywordCarrierSetting->new
                                                                         ->carrier( 'carrier' )
                                                                         ->editorialStatus( 'editorial status' )
                                                                         ->sponsoredSearchMaxBid( 'sponsored search max bid' )
                                                                         ->url( 'url' )
                                                                         ->sponsoredSearchMaxBidTimestamp( '2008-01-06T17:51:55' )
                   ;

    ok( $keyword_carrier_setting );

    is( $keyword_carrier_setting->carrier, 'carrier', 'can get carrier' );
    is( $keyword_carrier_setting->editorialStatus, 'editorial status', 'can get editorial status' );
    is( $keyword_carrier_setting->sponsoredSearchMaxBid, 'sponsored search max bid', 'can get sponsored search max bid' );
    is( $keyword_carrier_setting->url, 'url', 'can get url' );
    is( $keyword_carrier_setting->sponsoredSearchMaxBidTimestamp, '2008-01-06T17:51:55', 'can get 2008-01-06T17:51:55' );

};



1;

