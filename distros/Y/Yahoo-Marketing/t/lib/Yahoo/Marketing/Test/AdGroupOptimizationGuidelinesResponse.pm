package Yahoo::Marketing::Test::AdGroupOptimizationGuidelinesResponse;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::AdGroupOptimizationGuidelinesResponse;

sub test_can_create_ad_group_optimization_guidelines_response_and_set_all_fields : Test(5) {

    my $ad_group_optimization_guidelines_response = Yahoo::Marketing::AdGroupOptimizationGuidelinesResponse->new
                                                                                                           ->adGroupOptimizationGuidelines( 'ad group optimization guidelines' )
                                                                                                           ->errors( 'errors' )
                                                                                                           ->operationSucceeded( 'operation succeeded' )
                                                                                                           ->warnings( 'warnings' )
                   ;

    ok( $ad_group_optimization_guidelines_response );

    is( $ad_group_optimization_guidelines_response->adGroupOptimizationGuidelines, 'ad group optimization guidelines', 'can get ad group optimization guidelines' );
    is( $ad_group_optimization_guidelines_response->errors, 'errors', 'can get errors' );
    is( $ad_group_optimization_guidelines_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $ad_group_optimization_guidelines_response->warnings, 'warnings', 'can get warnings' );

};



1;

