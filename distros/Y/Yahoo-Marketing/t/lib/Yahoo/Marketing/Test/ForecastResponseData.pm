package Yahoo::Marketing::Test::ForecastResponseData;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::ForecastResponseData;

sub test_can_create_forecast_response_data_and_set_all_fields : Test(7) {

    my $forecast_response_data = Yahoo::Marketing::ForecastResponseData->new
                                                                       ->averagePosition( 'average position' )
                                                                       ->clicks( 'clicks' )
                                                                       ->costPerClick( 'cost per click' )
                                                                       ->impressions( 'impressions' )
                                                                       ->maxBid( 'max bid' )
                                                                       ->missedClicks( 'missed clicks' )
                   ;

    ok( $forecast_response_data );

    is( $forecast_response_data->averagePosition, 'average position', 'can get average position' );
    is( $forecast_response_data->clicks, 'clicks', 'can get clicks' );
    is( $forecast_response_data->costPerClick, 'cost per click', 'can get cost per click' );
    is( $forecast_response_data->impressions, 'impressions', 'can get impressions' );
    is( $forecast_response_data->maxBid, 'max bid', 'can get max bid' );
    is( $forecast_response_data->missedClicks, 'missed clicks', 'can get missed clicks' );

};



1;

