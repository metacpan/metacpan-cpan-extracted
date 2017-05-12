package Yahoo::Marketing::APT::Test::PlacementTransferResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::PlacementTransferResponse;

sub test_can_create_placement_transfer_response_and_set_all_fields : Test(5) {

    my $placement_transfer_response = Yahoo::Marketing::APT::PlacementTransferResponse->new
                                                                                 ->ads( 'ads' )
                                                                                 ->errors( 'errors' )
                                                                                 ->operationResult( 'operation result' )
                                                                                 ->placements( 'placements' )
                   ;

    ok( $placement_transfer_response );

    is( $placement_transfer_response->ads, 'ads', 'can get ads' );
    is( $placement_transfer_response->errors, 'errors', 'can get errors' );
    is( $placement_transfer_response->operationResult, 'operation result', 'can get operation result' );
    is( $placement_transfer_response->placements, 'placements', 'can get placements' );

};



1;

