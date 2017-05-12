package Yahoo::Marketing::APT::Test::OrderContact;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::OrderContact;

sub test_can_create_order_contact_and_set_all_fields : Test(4) {

    my $order_contact = Yahoo::Marketing::APT::OrderContact->new
                                                      ->contactID( 'contact id' )
                                                      ->primary( 'primary' )
                                                      ->type( 'type' )
                   ;

    ok( $order_contact );

    is( $order_contact->contactID, 'contact id', 'can get contact id' );
    is( $order_contact->primary, 'primary', 'can get primary' );
    is( $order_contact->type, 'type', 'can get type' );

};



1;

