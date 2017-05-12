package Yahoo::Marketing::APT::Test::AdMarkerResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AdMarkerResponse;

sub test_can_create_ad_marker_response_and_set_all_fields : Test(4) {

    my $ad_marker_response = Yahoo::Marketing::APT::AdMarkerResponse->new
                                                               ->adMarker( 'ad marker' )
                                                               ->errors( 'errors' )
                                                               ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $ad_marker_response );

    is( $ad_marker_response->adMarker, 'ad marker', 'can get ad marker' );
    is( $ad_marker_response->errors, 'errors', 'can get errors' );
    is( $ad_marker_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

