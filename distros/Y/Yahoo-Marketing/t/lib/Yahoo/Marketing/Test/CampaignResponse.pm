package Yahoo::Marketing::Test::CampaignResponse;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::CampaignResponse;

sub test_can_create_campaign_response_and_set_all_fields : Test(5) {

    my $campaign_response = Yahoo::Marketing::CampaignResponse->new
                                                              ->campaign( 'campaign' )
                                                              ->errors( 'errors' )
                                                              ->operationSucceeded( 'operation succeeded' )
                                                              ->warnings( 'warnings' )
                   ;

    ok( $campaign_response );

    is( $campaign_response->campaign, 'campaign', 'can get campaign' );
    is( $campaign_response->errors, 'errors', 'can get errors' );
    is( $campaign_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $campaign_response->warnings, 'warnings', 'can get warnings' );

};



1;

