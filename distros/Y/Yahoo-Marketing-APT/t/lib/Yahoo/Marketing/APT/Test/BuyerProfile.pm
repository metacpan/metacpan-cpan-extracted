package Yahoo::Marketing::APT::Test::BuyerProfile;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::BuyerProfile;

sub test_can_create_buyer_profile_and_set_all_fields : Test(5) {

    my $buyer_profile = Yahoo::Marketing::APT::BuyerProfile->new
                                                      ->accountID( 'account id' )
                                                      ->contact( 'contact' )
                                                      ->description( 'description' )
                                                      ->pricingTypes( 'pricing types' )
                   ;

    ok( $buyer_profile );

    is( $buyer_profile->accountID, 'account id', 'can get account id' );
    is( $buyer_profile->contact, 'contact', 'can get contact' );
    is( $buyer_profile->description, 'description', 'can get description' );
    is( $buyer_profile->pricingTypes, 'pricing types', 'can get pricing types' );

};



1;

