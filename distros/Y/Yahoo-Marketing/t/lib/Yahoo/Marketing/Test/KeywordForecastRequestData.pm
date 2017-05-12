package Yahoo::Marketing::Test::KeywordForecastRequestData;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::KeywordForecastRequestData;

sub test_can_create_keyword_forecast_request_data_and_set_all_fields : Test(6) {

    my $keyword_forecast_request_data = Yahoo::Marketing::KeywordForecastRequestData->new
                                                                                    ->accountID( 'account id' )
                                                                                    ->matchType( 'match type' )
                                                                                    ->maxBid( 'max bid' )
                                                                                    ->targetingAttributes( 'targeting attributes' )
                                                                                    ->targetingProfile( 'targeting profile' )
                   ;

    ok( $keyword_forecast_request_data );

    is( $keyword_forecast_request_data->accountID, 'account id', 'can get account id' );
    is( $keyword_forecast_request_data->matchType, 'match type', 'can get match type' );
    is( $keyword_forecast_request_data->maxBid, 'max bid', 'can get max bid' );
    is( $keyword_forecast_request_data->targetingAttributes, 'targeting attributes', 'can get targeting attributes' );
    is( $keyword_forecast_request_data->targetingProfile, 'targeting profile', 'can get targeting profile' );

};



1;

