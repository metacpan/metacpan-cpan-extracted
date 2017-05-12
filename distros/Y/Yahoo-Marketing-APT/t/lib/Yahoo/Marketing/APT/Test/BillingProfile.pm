package Yahoo::Marketing::APT::Test::BillingProfile;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::BillingProfile;

sub test_can_create_billing_profile_and_set_all_fields : Test(4) {

    my $billing_profile = Yahoo::Marketing::APT::BillingProfile->new
                                                          ->accountID( 'account id' )
                                                          ->address( 'address' )
                                                          ->contactID( 'contact id' )
                   ;

    ok( $billing_profile );

    is( $billing_profile->accountID, 'account id', 'can get account id' );
    is( $billing_profile->address, 'address', 'can get address' );
    is( $billing_profile->contactID, 'contact id', 'can get contact id' );

};



1;

