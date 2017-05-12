package Yahoo::Marketing::Test::GeoLocation;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::GeoLocation;

sub test_can_create_geo_location_and_set_all_fields : Test(5) {

    my $geo_location = Yahoo::Marketing::GeoLocation->new
                                                    ->description( 'description' )
                                                    ->name( 'name' )
                                                    ->placeType( 'place type' )
                                                    ->woeid( 'woeid' )
                   ;

    ok( $geo_location );

    is( $geo_location->description, 'description', 'can get description' );
    is( $geo_location->name, 'name', 'can get name' );
    is( $geo_location->placeType, 'place type', 'can get place type' );
    is( $geo_location->woeid, 'woeid', 'can get woeid' );

};



1;

