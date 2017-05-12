package Yahoo::Marketing::APT::Test::AudienceSharingRuleResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AudienceSharingRuleResponse;

sub test_can_create_audience_sharing_rule_response_and_set_all_fields : Test(4) {

    my $audience_sharing_rule_response = Yahoo::Marketing::APT::AudienceSharingRuleResponse->new
                                                                                      ->audienceSharingRule( 'audience sharing rule' )
                                                                                      ->errors( 'errors' )
                                                                                      ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $audience_sharing_rule_response );

    is( $audience_sharing_rule_response->audienceSharingRule, 'audience sharing rule', 'can get audience sharing rule' );
    is( $audience_sharing_rule_response->errors, 'errors', 'can get errors' );
    is( $audience_sharing_rule_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

