package Yahoo::Marketing::Test::ForecastKeywordResponse;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::ForecastKeywordResponse;

sub test_can_create_forecast_keyword_response_and_set_all_fields : Test(7) {

    my $forecast_keyword_response = Yahoo::Marketing::ForecastKeywordResponse->new
                                                                             ->customizedResponseByAdGroup( 'customized response by ad group' )
                                                                             ->defaultResponseByAdGroup( 'default response by ad group' )
                                                                             ->errors( 'errors' )
                                                                             ->landscapeByAdGroup( 'landscape by ad group' )
                                                                             ->operationSucceeded( 'operation succeeded' )
                                                                             ->warnings( 'warnings' )
                   ;

    ok( $forecast_keyword_response );

    is( $forecast_keyword_response->customizedResponseByAdGroup, 'customized response by ad group', 'can get customized response by ad group' );
    is( $forecast_keyword_response->defaultResponseByAdGroup, 'default response by ad group', 'can get default response by ad group' );
    is( $forecast_keyword_response->errors, 'errors', 'can get errors' );
    is( $forecast_keyword_response->landscapeByAdGroup, 'landscape by ad group', 'can get landscape by ad group' );
    is( $forecast_keyword_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $forecast_keyword_response->warnings, 'warnings', 'can get warnings' );

};



1;

