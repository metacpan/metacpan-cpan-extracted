package Yahoo::Marketing::Test::AccountAggregate;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::AccountAggregate;

sub test_can_create_account_aggregate_and_set_all_fields : Test(3) {

    my $account_aggregate = Yahoo::Marketing::AccountAggregate->new
                                                              ->accounts( 'accounts' )
                                                              ->masterAccount( 'master account' )
                   ;

    ok( $account_aggregate );

    is( $account_aggregate->accounts, 'accounts', 'can get accounts' );
    is( $account_aggregate->masterAccount, 'master account', 'can get master account' );

};



1;

