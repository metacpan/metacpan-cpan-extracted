package Yahoo::Marketing::Test::AmbiguousGeoMatch;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::AmbiguousGeoMatch;

sub test_can_create_ambiguous_geo_match_and_set_all_fields : Test(3) {

    my $ambiguous_geo_match = Yahoo::Marketing::AmbiguousGeoMatch->new
                                                                 ->geoString( 'geo string' )
                                                                 ->possibleMatches( 'possible matches' )
                   ;

    ok( $ambiguous_geo_match );

    is( $ambiguous_geo_match->geoString, 'geo string', 'can get geo string' );
    is( $ambiguous_geo_match->possibleMatches, 'possible matches', 'can get possible matches' );

};



1;

