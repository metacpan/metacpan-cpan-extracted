package Yahoo::Marketing::APT::Test::TargetingProfileResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::TargetingProfileResponse;

sub test_can_create_targeting_profile_response_and_set_all_fields : Test(4) {

    my $targeting_profile_response = Yahoo::Marketing::APT::TargetingProfileResponse->new
                                                                               ->errors( 'errors' )
                                                                               ->operationSucceeded( 'operation succeeded' )
                                                                               ->targetingProfile( 'targeting profile' )
                   ;

    ok( $targeting_profile_response );

    is( $targeting_profile_response->errors, 'errors', 'can get errors' );
    is( $targeting_profile_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $targeting_profile_response->targetingProfile, 'targeting profile', 'can get targeting profile' );

};



1;

