package Yahoo::Marketing::Test::SpendLimit;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::SpendLimit;

sub test_can_create_spend_limit_and_set_all_fields : Test(4) {

    my $spend_limit = Yahoo::Marketing::SpendLimit->new
                                                  ->limit( 'limit' )
                                                  ->status( 'status' )
                                                  ->tacticSpendCap( 'tactic spend cap' )
                   ;

    ok( $spend_limit );

    is( $spend_limit->limit, 'limit', 'can get limit' );
    is( $spend_limit->status, 'status', 'can get status' );
    is( $spend_limit->tacticSpendCap, 'tactic spend cap', 'can get tactic spend cap' );

};



1;

