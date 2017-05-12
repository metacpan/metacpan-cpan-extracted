package Yahoo::Marketing::APT::Test::SellingRule;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::SellingRule;

sub test_can_create_selling_rule_and_set_all_fields : Test(7) {

    my $selling_rule = Yahoo::Marketing::APT::SellingRule->new
                                                    ->ID( 'id' )
                                                    ->accountID( 'account id' )
                                                    ->createTimestamp( '2009-01-06T17:51:55' )
                                                    ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                                    ->name( 'name' )
                                                    ->targetingRule( 'targeting rule' )
                   ;

    ok( $selling_rule );

    is( $selling_rule->ID, 'id', 'can get id' );
    is( $selling_rule->accountID, 'account id', 'can get account id' );
    is( $selling_rule->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $selling_rule->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $selling_rule->name, 'name', 'can get name' );
    is( $selling_rule->targetingRule, 'targeting rule', 'can get targeting rule' );

};



1;

