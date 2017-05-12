package Yahoo::Marketing::Test::UserAuthorization;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::UserAuthorization;

sub test_can_create_user_authorization_and_set_all_fields : Test(4) {

    my $user_authorization = Yahoo::Marketing::UserAuthorization->new
                                                                ->accountID( 'account id' )
                                                                ->role( 'role' )
                                                                ->username( 'username' )
                   ;

    ok( $user_authorization );

    is( $user_authorization->accountID, 'account id', 'can get account id' );
    is( $user_authorization->role, 'role', 'can get role' );
    is( $user_authorization->username, 'username', 'can get username' );

};



1;

