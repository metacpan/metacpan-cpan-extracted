package Yahoo::Marketing::APT::Test::ContactResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ContactResponse;

sub test_can_create_contact_response_and_set_all_fields : Test(4) {

    my $contact_response = Yahoo::Marketing::APT::ContactResponse->new
                                                            ->contact( 'contact' )
                                                            ->errors( 'errors' )
                                                            ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $contact_response );

    is( $contact_response->contact, 'contact', 'can get contact' );
    is( $contact_response->errors, 'errors', 'can get errors' );
    is( $contact_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

