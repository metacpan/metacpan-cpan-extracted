package Yahoo::Marketing::APT::Test::ProfileContact;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ProfileContact;

sub test_can_create_profile_contact_and_set_all_fields : Test(4) {

    my $profile_contact = Yahoo::Marketing::APT::ProfileContact->new
                                                          ->email( 'email' )
                                                          ->name( 'name' )
                                                          ->phoneNumber( 'phone number' )
                   ;

    ok( $profile_contact );

    is( $profile_contact->email, 'email', 'can get email' );
    is( $profile_contact->name, 'name', 'can get name' );
    is( $profile_contact->phoneNumber, 'phone number', 'can get phone number' );

};



1;

