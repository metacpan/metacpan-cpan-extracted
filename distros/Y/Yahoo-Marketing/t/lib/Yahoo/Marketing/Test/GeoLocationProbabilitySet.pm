package Yahoo::Marketing::Test::GeoLocationProbabilitySet;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::GeoLocationProbabilitySet;

sub test_can_create_geo_location_probability_set_and_set_all_fields : Test(3) {

    my $geo_location_probability_set = Yahoo::Marketing::GeoLocationProbabilitySet->new
                                                                                  ->geoLocationProbabilities( 'geo location probabilities' )
                                                                                  ->geoString( 'geo string' )
                   ;

    ok( $geo_location_probability_set );

    is( $geo_location_probability_set->geoLocationProbabilities, 'geo location probabilities', 'can get geo location probabilities' );
    is( $geo_location_probability_set->geoString, 'geo string', 'can get geo string' );

};



1;

