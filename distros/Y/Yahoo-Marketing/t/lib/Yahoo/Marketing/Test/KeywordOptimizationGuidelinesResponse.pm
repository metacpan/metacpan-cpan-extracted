package Yahoo::Marketing::Test::KeywordOptimizationGuidelinesResponse;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::KeywordOptimizationGuidelinesResponse;

sub test_can_create_keyword_optimization_guidelines_response_and_set_all_fields : Test(5) {

    my $keyword_optimization_guidelines_response = Yahoo::Marketing::KeywordOptimizationGuidelinesResponse->new
                                                                                                          ->errors( 'errors' )
                                                                                                          ->keywordOptimizationGuidelines( 'keyword optimization guidelines' )
                                                                                                          ->operationSucceeded( 'operation succeeded' )
                                                                                                          ->warnings( 'warnings' )
                   ;

    ok( $keyword_optimization_guidelines_response );

    is( $keyword_optimization_guidelines_response->errors, 'errors', 'can get errors' );
    is( $keyword_optimization_guidelines_response->keywordOptimizationGuidelines, 'keyword optimization guidelines', 'can get keyword optimization guidelines' );
    is( $keyword_optimization_guidelines_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $keyword_optimization_guidelines_response->warnings, 'warnings', 'can get warnings' );

};



1;

