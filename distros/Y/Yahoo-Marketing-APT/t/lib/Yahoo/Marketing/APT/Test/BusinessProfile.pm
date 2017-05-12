package Yahoo::Marketing::APT::Test::BusinessProfile;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::BusinessProfile;

sub test_can_create_business_profile_and_set_all_fields : Test(5) {

    my $business_profile = Yahoo::Marketing::APT::BusinessProfile->new
                                                            ->accountID( 'account id' )
                                                            ->description( 'description' )
                                                            ->name( 'name' )
                                                            ->url( 'url' )
                   ;

    ok( $business_profile );

    is( $business_profile->accountID, 'account id', 'can get account id' );
    is( $business_profile->description, 'description', 'can get description' );
    is( $business_profile->name, 'name', 'can get name' );
    is( $business_profile->url, 'url', 'can get url' );

};



1;

