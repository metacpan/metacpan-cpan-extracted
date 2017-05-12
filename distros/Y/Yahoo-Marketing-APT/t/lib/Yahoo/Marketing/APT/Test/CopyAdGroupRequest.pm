package Yahoo::Marketing::APT::Test::CopyAdGroupRequest;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::CopyAdGroupRequest;

sub test_can_create_copy_ad_group_request_and_set_all_fields : Test(3) {

    my $copy_ad_group_request = Yahoo::Marketing::APT::CopyAdGroupRequest->new
                                                                    ->adGroupID( 'ad group id' )
                                                                    ->newAdGroupName( 'new ad group name' )
                   ;

    ok( $copy_ad_group_request );

    is( $copy_ad_group_request->adGroupID, 'ad group id', 'can get ad group id' );
    is( $copy_ad_group_request->newAdGroupName, 'new ad group name', 'can get new ad group name' );

};



1;

