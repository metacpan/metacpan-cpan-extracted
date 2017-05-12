package Yahoo::Marketing::Test::ForecastResponse;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::ForecastResponse;

sub test_can_create_forecast_response_and_set_all_fields : Test(6) {

    my $forecast_response = Yahoo::Marketing::ForecastResponse->new
                                                              ->errors( 'errors' )
                                                              ->forecastLandscape( 'forecast landscape' )
                                                              ->forecastResponseDetail( 'forecast response detail' )
                                                              ->operationSucceeded( 'operation succeeded' )
                                                              ->warnings( 'warnings' )
                   ;

    ok( $forecast_response );

    is( $forecast_response->errors, 'errors', 'can get errors' );
    is( $forecast_response->forecastLandscape, 'forecast landscape', 'can get forecast landscape' );
    is( $forecast_response->forecastResponseDetail, 'forecast response detail', 'can get forecast response detail' );
    is( $forecast_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $forecast_response->warnings, 'warnings', 'can get warnings' );

};



1;

