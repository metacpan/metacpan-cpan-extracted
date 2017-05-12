package Yahoo::Marketing::APT::Test::PlacementResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::PlacementResponse;

sub test_can_create_placement_response_and_set_all_fields : Test(4) {

    my $placement_response = Yahoo::Marketing::APT::PlacementResponse->new
                                                                ->errors( 'errors' )
                                                                ->operationSucceeded( 'operation succeeded' )
                                                                ->placement( 'placement' )
                   ;

    ok( $placement_response );

    is( $placement_response->errors, 'errors', 'can get errors' );
    is( $placement_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $placement_response->placement, 'placement', 'can get placement' );

};



1;

