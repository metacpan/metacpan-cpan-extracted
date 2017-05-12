package Yahoo::Marketing::APT::Test::TargetingRule;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::TargetingRule;

sub test_can_create_targeting_rule_and_set_all_fields : Test(4) {

    my $targeting_rule = Yahoo::Marketing::APT::TargetingRule->new
                                                        ->targetingAttributeTypesDisabledInOrders( 'targeting attribute types disabled in orders' )
                                                        ->targetingAttributesAllowedInOrders( 'targeting attributes allowed in orders' )
                                                        ->targetingAttributesPresetInOrders( 'targeting attributes preset in orders' )
                   ;

    ok( $targeting_rule );

    is( $targeting_rule->targetingAttributeTypesDisabledInOrders, 'targeting attribute types disabled in orders', 'can get targeting attribute types disabled in orders' );
    is( $targeting_rule->targetingAttributesAllowedInOrders, 'targeting attributes allowed in orders', 'can get targeting attributes allowed in orders' );
    is( $targeting_rule->targetingAttributesPresetInOrders, 'targeting attributes preset in orders', 'can get targeting attributes preset in orders' );

};



1;

