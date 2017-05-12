package Yahoo::Marketing::Test::HistoricalRequestData;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::HistoricalRequestData;

sub test_can_create_historical_request_data_and_set_all_fields : Test(8) {

    my $historical_request_data = Yahoo::Marketing::HistoricalRequestData->new
                                                                         ->accountID( 'account id' )
                                                                         ->endDate( '2008-01-06T17:51:55' )
                                                                         ->marketID( 'market id' )
                                                                         ->matchType( 'match type' )
                                                                         ->startDate( '2008-01-07T17:51:55' )
                                                                         ->targetingAttributes( 'targeting attributes' )
                                                                         ->targetingProfile( 'targeting profile' )
                   ;

    ok( $historical_request_data );

    is( $historical_request_data->accountID, 'account id', 'can get account id' );
    is( $historical_request_data->endDate, '2008-01-06T17:51:55', 'can get 2008-01-06T17:51:55' );
    is( $historical_request_data->marketID, 'market id', 'can get market id' );
    is( $historical_request_data->matchType, 'match type', 'can get match type' );
    is( $historical_request_data->startDate, '2008-01-07T17:51:55', 'can get 2008-01-07T17:51:55' );
    is( $historical_request_data->targetingAttributes, 'targeting attributes', 'can get targeting attributes' );
    is( $historical_request_data->targetingProfile, 'targeting profile', 'can get targeting profile' );

};



1;

