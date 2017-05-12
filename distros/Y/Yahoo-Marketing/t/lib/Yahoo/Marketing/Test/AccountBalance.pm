package Yahoo::Marketing::Test::AccountBalance;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::AccountBalance;

sub test_can_create_account_balance_and_set_all_fields : Test(3) {

    my $account_balance = Yahoo::Marketing::AccountBalance->new
                                                          ->accountBalance( 'account balance' )
                                                          ->accountBalanceAsOf( 'account balance as of' )
                   ;

    ok( $account_balance );

    is( $account_balance->accountBalance, 'account balance', 'can get account balance' );
    is( $account_balance->accountBalanceAsOf, 'account balance as of', 'can get account balance as of' );

};



1;

