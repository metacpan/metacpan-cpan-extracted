package Yahoo::Marketing::APT::Test::SellingRuleResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::SellingRuleResponse;

sub test_can_create_selling_rule_response_and_set_all_fields : Test(4) {

    my $selling_rule_response = Yahoo::Marketing::APT::SellingRuleResponse->new
                                                                     ->errors( 'errors' )
                                                                     ->operationSucceeded( 'operation succeeded' )
                                                                     ->sellingRule( 'selling rule' )
                   ;

    ok( $selling_rule_response );

    is( $selling_rule_response->errors, 'errors', 'can get errors' );
    is( $selling_rule_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $selling_rule_response->sellingRule, 'selling rule', 'can get selling rule' );

};



1;

