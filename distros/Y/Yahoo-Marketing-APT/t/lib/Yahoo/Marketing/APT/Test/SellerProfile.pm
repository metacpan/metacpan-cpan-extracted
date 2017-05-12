package Yahoo::Marketing::APT::Test::SellerProfile;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::SellerProfile;

sub test_can_create_seller_profile_and_set_all_fields : Test(5) {

    my $seller_profile = Yahoo::Marketing::APT::SellerProfile->new
                                                        ->accountID( 'account id' )
                                                        ->contact( 'contact' )
                                                        ->description( 'description' )
                                                        ->pricingTypes( 'pricing types' )
                   ;

    ok( $seller_profile );

    is( $seller_profile->accountID, 'account id', 'can get account id' );
    is( $seller_profile->contact, 'contact', 'can get contact' );
    is( $seller_profile->description, 'description', 'can get description' );
    is( $seller_profile->pricingTypes, 'pricing types', 'can get pricing types' );

};



1;

