package Yahoo::Marketing::Test::Authorization;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::Authorization;

sub test_can_create_authorization_and_set_all_fields : Test(4) {

    my $authorization = Yahoo::Marketing::Authorization->new
                                                       ->accountID( 'account id' )
                                                       ->accountType( 'account type' )
                                                       ->role( 'role' )
                   ;

    ok( $authorization );

    is( $authorization->accountID, 'account id', 'can get account id' );
    is( $authorization->accountType, 'account type', 'can get account type' );
    is( $authorization->role, 'role', 'can get role' );

};



1;

