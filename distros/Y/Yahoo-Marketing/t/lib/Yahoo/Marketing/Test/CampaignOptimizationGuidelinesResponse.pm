package Yahoo::Marketing::Test::CampaignOptimizationGuidelinesResponse;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::CampaignOptimizationGuidelinesResponse;

sub test_can_create_campaign_optimization_guidelines_response_and_set_all_fields : Test(5) {

    my $campaign_optimization_guidelines_response = Yahoo::Marketing::CampaignOptimizationGuidelinesResponse->new
                                                                                                            ->campaignOptimizationGuidelines( 'campaign optimization guidelines' )
                                                                                                            ->errors( 'errors' )
                                                                                                            ->operationSucceeded( 'operation succeeded' )
                                                                                                            ->warnings( 'warnings' )
                   ;

    ok( $campaign_optimization_guidelines_response );

    is( $campaign_optimization_guidelines_response->campaignOptimizationGuidelines, 'campaign optimization guidelines', 'can get campaign optimization guidelines' );
    is( $campaign_optimization_guidelines_response->errors, 'errors', 'can get errors' );
    is( $campaign_optimization_guidelines_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $campaign_optimization_guidelines_response->warnings, 'warnings', 'can get warnings' );

};



1;

