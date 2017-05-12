package Yahoo::Marketing::Test::GeoLocationProbability;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::GeoLocationProbability;

sub test_can_create_geo_location_probability_and_set_all_fields : Test(3) {

    my $geo_location_probability = Yahoo::Marketing::GeoLocationProbability->new
                                                                           ->geoLocation( 'geo location' )
                                                                           ->probability( 'probability' )
                   ;

    ok( $geo_location_probability );

    is( $geo_location_probability->geoLocation, 'geo location', 'can get geo location' );
    is( $geo_location_probability->probability, 'probability', 'can get probability' );

};



1;

