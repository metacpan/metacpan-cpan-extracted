package Yahoo::Marketing::Test::OptInAdGroupResponse;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::OptInAdGroupResponse;

sub test_can_create_opt_in_ad_group_response_and_set_all_fields : Test(5) {

    my $opt_in_ad_group_response = Yahoo::Marketing::OptInAdGroupResponse->new
                                                                         ->adGroupID( 'ad group id' )
                                                                         ->errors( 'errors' )
                                                                         ->operationSucceeded( 'operation succeeded' )
                                                                         ->optInStatus( 'opt in status' )
                   ;

    ok( $opt_in_ad_group_response );

    is( $opt_in_ad_group_response->adGroupID, 'ad group id', 'can get ad group id' );
    is( $opt_in_ad_group_response->errors, 'errors', 'can get errors' );
    is( $opt_in_ad_group_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $opt_in_ad_group_response->optInStatus, 'opt in status', 'can get opt in status' );

};



1;

