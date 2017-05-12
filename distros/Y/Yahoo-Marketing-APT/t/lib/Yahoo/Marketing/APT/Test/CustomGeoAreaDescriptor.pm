package Yahoo::Marketing::APT::Test::CustomGeoAreaDescriptor;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::CustomGeoAreaDescriptor;

sub test_can_create_custom_geo_area_descriptor_and_set_all_fields : Test(5) {

    my $custom_geo_area_descriptor = Yahoo::Marketing::APT::CustomGeoAreaDescriptor->new
                                                                              ->ID( 'id' )
                                                                              ->accountID( 'account id' )
                                                                              ->description( 'description' )
                                                                              ->name( 'name' )
                   ;

    ok( $custom_geo_area_descriptor );

    is( $custom_geo_area_descriptor->ID, 'id', 'can get id' );
    is( $custom_geo_area_descriptor->accountID, 'account id', 'can get account id' );
    is( $custom_geo_area_descriptor->description, 'description', 'can get description' );
    is( $custom_geo_area_descriptor->name, 'name', 'can get name' );

};



1;

