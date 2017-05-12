package Yahoo::Marketing::APT::Test::AccountResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AccountResponse;

sub test_can_create_account_response_and_set_all_fields : Test(4) {

    my $account_response = Yahoo::Marketing::APT::AccountResponse->new
                                                            ->account( 'account' )
                                                            ->errors( 'errors' )
                                                            ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $account_response );

    is( $account_response->account, 'account', 'can get account' );
    is( $account_response->errors, 'errors', 'can get errors' );
    is( $account_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

