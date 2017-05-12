package Yahoo::Marketing::Test::ForecastKeywordBatchResponse;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::ForecastKeywordBatchResponse;

sub test_can_create_forecast_keyword_batch_response_and_set_all_fields : Test(4) {

    my $forecast_keyword_batch_response = Yahoo::Marketing::ForecastKeywordBatchResponse->new
                                                                                        ->errors( 'errors' )
                                                                                        ->forecastKeywordBatchResponseData( 'forecast keyword batch response data' )
                                                                                        ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $forecast_keyword_batch_response );

    is( $forecast_keyword_batch_response->errors, 'errors', 'can get errors' );
    is( $forecast_keyword_batch_response->forecastKeywordBatchResponseData, 'forecast keyword batch response data', 'can get forecast keyword batch response data' );
    is( $forecast_keyword_batch_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

