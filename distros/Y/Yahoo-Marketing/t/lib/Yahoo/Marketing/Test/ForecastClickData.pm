package Yahoo::Marketing::Test::ForecastClickData;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::ForecastClickData;

sub test_can_create_forecast_click_data_and_set_all_fields : Test(4) {

    my $forecast_click_data = Yahoo::Marketing::ForecastClickData->new
                                                                 ->clicks( 'clicks' )
                                                                 ->maxClicks( 'max clicks' )
                                                                 ->minClicks( 'min clicks' )
                   ;

    ok( $forecast_click_data );

    is( $forecast_click_data->clicks, 'clicks', 'can get clicks' );
    is( $forecast_click_data->maxClicks, 'max clicks', 'can get max clicks' );
    is( $forecast_click_data->minClicks, 'min clicks', 'can get min clicks' );

};



1;

