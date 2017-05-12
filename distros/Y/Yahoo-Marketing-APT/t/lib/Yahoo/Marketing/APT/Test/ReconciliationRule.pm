package Yahoo::Marketing::APT::Test::ReconciliationRule;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ReconciliationRule;

sub test_can_create_reconciliation_rule_and_set_all_fields : Test(3) {

    my $reconciliation_rule = Yahoo::Marketing::APT::ReconciliationRule->new
                                                                  ->ID( 'id' )
                                                                  ->name( 'name' )
                   ;

    ok( $reconciliation_rule );

    is( $reconciliation_rule->ID, 'id', 'can get id' );
    is( $reconciliation_rule->name, 'name', 'can get name' );

};



1;

