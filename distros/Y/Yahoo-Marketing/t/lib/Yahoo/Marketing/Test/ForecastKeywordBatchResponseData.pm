package Yahoo::Marketing::Test::ForecastKeywordBatchResponseData;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::ForecastKeywordBatchResponseData;

sub test_can_create_forecast_keyword_batch_response_data_and_set_all_fields : Test(9) {

    my $forecast_keyword_batch_response_data = Yahoo::Marketing::ForecastKeywordBatchResponseData->new
                                                                                                 ->canonKeyword( 'canon keyword' )
                                                                                                 ->errors( 'errors' )
                                                                                                 ->forecastLandscape( 'forecast landscape' )
                                                                                                 ->forecastResponseDetail( 'forecast response detail' )
                                                                                                 ->keyword( 'keyword' )
                                                                                                 ->matchType( 'match type' )
                                                                                                 ->operationSucceeded( 'operation succeeded' )
                                                                                                 ->warnings( 'warnings' )
                   ;

    ok( $forecast_keyword_batch_response_data );

    is( $forecast_keyword_batch_response_data->canonKeyword, 'canon keyword', 'can get canon keyword' );
    is( $forecast_keyword_batch_response_data->errors, 'errors', 'can get errors' );
    is( $forecast_keyword_batch_response_data->forecastLandscape, 'forecast landscape', 'can get forecast landscape' );
    is( $forecast_keyword_batch_response_data->forecastResponseDetail, 'forecast response detail', 'can get forecast response detail' );
    is( $forecast_keyword_batch_response_data->keyword, 'keyword', 'can get keyword' );
    is( $forecast_keyword_batch_response_data->matchType, 'match type', 'can get match type' );
    is( $forecast_keyword_batch_response_data->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $forecast_keyword_batch_response_data->warnings, 'warnings', 'can get warnings' );

};



1;

