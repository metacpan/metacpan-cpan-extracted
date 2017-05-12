package Yahoo::Marketing::Test::Campaign;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::Campaign;

sub test_can_create_campaign_and_set_all_fields : Test(17) {

    my $campaign = Yahoo::Marketing::Campaign->new
                                             ->ID( 'id' )
                                             ->accountID( 'account id' )
                                             ->advancedMatchON( 'advanced match on' )
                                             ->carrierConfig( 'carrier config' )
                                             ->contentMatchON( 'content match on' )
                                             ->description( 'description' )
                                             ->endDate( '2008-01-06T17:51:55' )
                                             ->name( 'name' )
                                             ->sponsoredSearchON( 'sponsored search on' )
                                             ->startDate( '2008-01-07T17:51:55' )
                                             ->status( 'status' )
                                             ->watchON( 'watch on' )
                                             ->campaignOptimizationON( 'campaign optimization on' )
                                             ->createTimestamp( '2008-01-08T17:51:55' )
                                             ->deleteTimestamp( '2008-01-09T17:51:55' )
                                             ->lastUpdateTimestamp( '2008-01-10T17:51:55' )
                   ;

    ok( $campaign );

    is( $campaign->ID, 'id', 'can get id' );
    is( $campaign->accountID, 'account id', 'can get account id' );
    is( $campaign->advancedMatchON, 'advanced match on', 'can get advanced match on' );
    is( $campaign->carrierConfig, 'carrier config', 'can get carrier config' );
    is( $campaign->contentMatchON, 'content match on', 'can get content match on' );
    is( $campaign->description, 'description', 'can get description' );
    is( $campaign->endDate, '2008-01-06T17:51:55', 'can get 2008-01-06T17:51:55' );
    is( $campaign->name, 'name', 'can get name' );
    is( $campaign->sponsoredSearchON, 'sponsored search on', 'can get sponsored search on' );
    is( $campaign->startDate, '2008-01-07T17:51:55', 'can get 2008-01-07T17:51:55' );
    is( $campaign->status, 'status', 'can get status' );
    is( $campaign->watchON, 'watch on', 'can get watch on' );
    is( $campaign->campaignOptimizationON, 'campaign optimization on', 'can get campaign optimization on' );
    is( $campaign->createTimestamp, '2008-01-08T17:51:55', 'can get 2008-01-08T17:51:55' );
    is( $campaign->deleteTimestamp, '2008-01-09T17:51:55', 'can get 2008-01-09T17:51:55' );
    is( $campaign->lastUpdateTimestamp, '2008-01-10T17:51:55', 'can get 2008-01-10T17:51:55' );

};



1;

