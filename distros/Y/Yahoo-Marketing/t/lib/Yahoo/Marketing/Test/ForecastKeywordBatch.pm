package Yahoo::Marketing::Test::ForecastKeywordBatch;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::ForecastKeywordBatch;

sub test_can_create_forecast_keyword_batch_and_set_all_fields : Test(5) {

    my $forecast_keyword_batch = Yahoo::Marketing::ForecastKeywordBatch->new
                                                                       ->adGroupID( 'ad group id' )
                                                                       ->keyword( 'keyword' )
                                                                       ->matchType( 'match type' )
                                                                       ->maxBidOverride( 'max bid override' )
                   ;

    ok( $forecast_keyword_batch );

    is( $forecast_keyword_batch->adGroupID, 'ad group id', 'can get ad group id' );
    is( $forecast_keyword_batch->keyword, 'keyword', 'can get keyword' );
    is( $forecast_keyword_batch->matchType, 'match type', 'can get match type' );
    is( $forecast_keyword_batch->maxBidOverride, 'max bid override', 'can get max bid override' );

};



1;

