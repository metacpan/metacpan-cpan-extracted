package Yahoo::Marketing::Test::AdGroupForecastRequestData;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::AdGroupForecastRequestData;

sub test_can_create_ad_group_forecast_request_data_and_set_all_fields : Test(7) {

    my $ad_group_forecast_request_data = Yahoo::Marketing::AdGroupForecastRequestData->new
                                                                                     ->accountID( 'account id' )
                                                                                     ->creatives( 'creatives' )
                                                                                     ->matchType( 'match type' )
                                                                                     ->maxBid( 'max bid' )
                                                                                     ->targetingAttributes( 'targeting attributes' )
                                                                                     ->targetingProfile( 'targeting profile' )
                   ;

    ok( $ad_group_forecast_request_data );

    is( $ad_group_forecast_request_data->accountID, 'account id', 'can get account id' );
    is( $ad_group_forecast_request_data->creatives, 'creatives', 'can get creatives' );
    is( $ad_group_forecast_request_data->matchType, 'match type', 'can get match type' );
    is( $ad_group_forecast_request_data->maxBid, 'max bid', 'can get max bid' );
    is( $ad_group_forecast_request_data->targetingAttributes, 'targeting attributes', 'can get targeting attributes' );
    is( $ad_group_forecast_request_data->targetingProfile, 'targeting profile', 'can get targeting profile' );

};



1;

