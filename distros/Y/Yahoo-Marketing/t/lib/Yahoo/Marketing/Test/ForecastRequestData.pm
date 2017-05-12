package Yahoo::Marketing::Test::ForecastRequestData;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::ForecastRequestData;

sub test_can_create_forecast_request_data_and_set_all_fields : Test(7) {

    my $forecast_request_data = Yahoo::Marketing::ForecastRequestData->new
                                                                     ->accountID( 'account id' )
                                                                     ->contentMatchMaxBid( 'content match max bid' )
                                                                     ->geoTargets( 'geo targets' )
                                                                     ->marketID( 'market id' )
                                                                     ->matchTypes( 'match types' )
                                                                     ->sponsoredSearchMaxBid( 'sponsored search max bid' )
                   ;

    ok( $forecast_request_data );

    is( $forecast_request_data->accountID, 'account id', 'can get account id' );
    is( $forecast_request_data->contentMatchMaxBid, 'content match max bid', 'can get content match max bid' );
    is( $forecast_request_data->geoTargets, 'geo targets', 'can get geo targets' );
    is( $forecast_request_data->marketID, 'market id', 'can get market id' );
    is( $forecast_request_data->matchTypes, 'match types', 'can get match types' );
    is( $forecast_request_data->sponsoredSearchMaxBid, 'sponsored search max bid', 'can get sponsored search max bid' );

};



1;

