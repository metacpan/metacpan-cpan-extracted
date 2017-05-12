package Yahoo::Marketing::Test::BillingUser;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::BillingUser;

sub test_can_create_billing_user_and_set_all_fields : Test(6) {

    my $billing_user = Yahoo::Marketing::BillingUser->new
                                                    ->email( 'email' )
                                                    ->firstName( 'first name' )
                                                    ->lastName( 'last name' )
                                                    ->middleInitial( 'middle initial' )
                                                    ->phone( 'phone' )
                   ;

    ok( $billing_user );

    is( $billing_user->email, 'email', 'can get email' );
    is( $billing_user->firstName, 'first name', 'can get first name' );
    is( $billing_user->lastName, 'last name', 'can get last name' );
    is( $billing_user->middleInitial, 'middle initial', 'can get middle initial' );
    is( $billing_user->phone, 'phone', 'can get phone' );

};



1;

