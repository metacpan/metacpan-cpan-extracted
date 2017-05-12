package Yahoo::Marketing::Test::OptInCampaignResponse;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::OptInCampaignResponse;

sub test_can_create_opt_in_campaign_response_and_set_all_fields : Test(5) {

    my $opt_in_campaign_response = Yahoo::Marketing::OptInCampaignResponse->new
                                                                          ->campaignID( 'campaign id' )
                                                                          ->errors( 'errors' )
                                                                          ->operationSucceeded( 'operation succeeded' )
                                                                          ->optInStatus( 'opt in status' )
                   ;

    ok( $opt_in_campaign_response );

    is( $opt_in_campaign_response->campaignID, 'campaign id', 'can get campaign id' );
    is( $opt_in_campaign_response->errors, 'errors', 'can get errors' );
    is( $opt_in_campaign_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $opt_in_campaign_response->optInStatus, 'opt in status', 'can get opt in status' );

};



1;

