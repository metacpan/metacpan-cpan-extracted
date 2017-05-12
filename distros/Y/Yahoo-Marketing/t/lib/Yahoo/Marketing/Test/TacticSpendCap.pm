package Yahoo::Marketing::Test::TacticSpendCap;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::TacticSpendCap;

sub test_can_create_tactic_spend_cap_and_set_all_fields : Test(4) {

    my $tactic_spend_cap = Yahoo::Marketing::TacticSpendCap->new
                                                           ->spendCap( 'spend cap' )
                                                           ->spendCapType( 'spend cap type' )
                                                           ->tactic( 'tactic' )
                   ;

    ok( $tactic_spend_cap );

    is( $tactic_spend_cap->spendCap, 'spend cap', 'can get spend cap' );
    is( $tactic_spend_cap->spendCapType, 'spend cap type', 'can get spend cap type' );
    is( $tactic_spend_cap->tactic, 'tactic', 'can get tactic' );

};



1;

