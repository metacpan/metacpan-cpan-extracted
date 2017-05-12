package Yahoo::Marketing::APT::Test::CustomGeoAreaResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::CustomGeoAreaResponse;

sub test_can_create_custom_geo_area_response_and_set_all_fields : Test(4) {

    my $custom_geo_area_response = Yahoo::Marketing::APT::CustomGeoAreaResponse->new
                                                                          ->customGeoArea( 'custom geo area' )
                                                                          ->errors( 'errors' )
                                                                          ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $custom_geo_area_response );

    is( $custom_geo_area_response->customGeoArea, 'custom geo area', 'can get custom geo area' );
    is( $custom_geo_area_response->errors, 'errors', 'can get errors' );
    is( $custom_geo_area_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

