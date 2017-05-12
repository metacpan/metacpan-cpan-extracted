package Yahoo::Marketing::APT::Test::UpdatePlacementResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::UpdatePlacementResponse;

sub test_can_create_update_placement_response_and_set_all_fields : Test(5) {

    my $update_placement_response = Yahoo::Marketing::APT::UpdatePlacementResponse->new
                                                                             ->errors( 'errors' )
                                                                             ->operationSucceeded( 'operation succeeded' )
                                                                             ->placement( 'placement' )
                                                                             ->revision( 'revision' )
                   ;

    ok( $update_placement_response );

    is( $update_placement_response->errors, 'errors', 'can get errors' );
    is( $update_placement_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $update_placement_response->placement, 'placement', 'can get placement' );
    is( $update_placement_response->revision, 'revision', 'can get revision' );

};



1;

