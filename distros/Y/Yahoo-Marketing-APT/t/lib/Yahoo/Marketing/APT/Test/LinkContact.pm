package Yahoo::Marketing::APT::Test::LinkContact;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::LinkContact;

sub test_can_create_link_contact_and_set_all_fields : Test(4) {

    my $link_contact = Yahoo::Marketing::APT::LinkContact->new
                                                    ->email( 'email' )
                                                    ->name( 'name' )
                                                    ->phoneNumber( 'phone number' )
                   ;

    ok( $link_contact );

    is( $link_contact->email, 'email', 'can get email' );
    is( $link_contact->name, 'name', 'can get name' );
    is( $link_contact->phoneNumber, 'phone number', 'can get phone number' );

};



1;

