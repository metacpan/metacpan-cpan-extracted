package Yahoo::Marketing::APT::Test::CustomGeoArea;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::CustomGeoArea;

sub test_can_create_custom_geo_area_and_set_all_fields : Test(11) {

    my $custom_geo_area = Yahoo::Marketing::APT::CustomGeoArea->new
                                                         ->ID( 'id' )
                                                         ->accountID( 'account id' )
                                                         ->activationTimestamp( '2009-01-06T17:51:55' )
                                                         ->createTimestamp( '2009-01-07T17:51:55' )
                                                         ->deactivationTimestamp( '2009-01-08T17:51:55' )
                                                         ->description( 'description' )
                                                         ->lastUpdateTimestamp( '2009-01-09T17:51:55' )
                                                         ->name( 'name' )
                                                         ->status( 'status' )
                                                         ->zipCodes( 'zip codes' )
                   ;

    ok( $custom_geo_area );

    is( $custom_geo_area->ID, 'id', 'can get id' );
    is( $custom_geo_area->accountID, 'account id', 'can get account id' );
    is( $custom_geo_area->activationTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $custom_geo_area->createTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $custom_geo_area->deactivationTimestamp, '2009-01-08T17:51:55', 'can get 2009-01-08T17:51:55' );
    is( $custom_geo_area->description, 'description', 'can get description' );
    is( $custom_geo_area->lastUpdateTimestamp, '2009-01-09T17:51:55', 'can get 2009-01-09T17:51:55' );
    is( $custom_geo_area->name, 'name', 'can get name' );
    is( $custom_geo_area->status, 'status', 'can get status' );
    is( $custom_geo_area->zipCodes, 'zip codes', 'can get zip codes' );

};



1;

