package Yahoo::Marketing::Test::HistoricalKeywordResponse;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::HistoricalKeywordResponse;

sub test_can_create_historical_keyword_response_and_set_all_fields : Test(4) {

    my $historical_keyword_response = Yahoo::Marketing::HistoricalKeywordResponse->new
                                                                                 ->errors( 'errors' )
                                                                                 ->historicalKeywordResponseData( 'historical keyword response data' )
                                                                                 ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $historical_keyword_response );

    is( $historical_keyword_response->errors, 'errors', 'can get errors' );
    is( $historical_keyword_response->historicalKeywordResponseData, 'historical keyword response data', 'can get historical keyword response data' );
    is( $historical_keyword_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

