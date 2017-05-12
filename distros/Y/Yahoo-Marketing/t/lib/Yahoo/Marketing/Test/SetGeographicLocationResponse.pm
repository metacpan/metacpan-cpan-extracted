package Yahoo::Marketing::Test::SetGeographicLocationResponse;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::SetGeographicLocationResponse;

sub test_can_create_set_geographic_location_response_and_set_all_fields : Test(4) {

    my $set_geographic_location_response = Yahoo::Marketing::SetGeographicLocationResponse->new
                                                                                          ->ambiguousMatches( 'ambiguous matches' )
                                                                                          ->setSucceeded( 'set succeeded' )
                                                                                          ->stringsWithNoMatches( 'strings with no matches' )
                   ;

    ok( $set_geographic_location_response );

    is( $set_geographic_location_response->ambiguousMatches, 'ambiguous matches', 'can get ambiguous matches' );
    is( $set_geographic_location_response->setSucceeded, 'set succeeded', 'can get set succeeded' );
    is( $set_geographic_location_response->stringsWithNoMatches, 'strings with no matches', 'can get strings with no matches' );

};



1;

