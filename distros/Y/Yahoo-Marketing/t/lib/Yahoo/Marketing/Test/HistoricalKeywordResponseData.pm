package Yahoo::Marketing::Test::HistoricalKeywordResponseData;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::HistoricalKeywordResponseData;

sub test_can_create_historical_keyword_response_data_and_set_all_fields : Test(4) {

    my $historical_keyword_response_data = Yahoo::Marketing::HistoricalKeywordResponseData->new
                                                                                          ->historicalData( 'historical data' )
                                                                                          ->keyword( 'keyword' )
                                                                                          ->matchType( 'match type' )
                   ;

    ok( $historical_keyword_response_data );

    is( $historical_keyword_response_data->historicalData, 'historical data', 'can get historical data' );
    is( $historical_keyword_response_data->keyword, 'keyword', 'can get keyword' );
    is( $historical_keyword_response_data->matchType, 'match type', 'can get match type' );

};



1;

