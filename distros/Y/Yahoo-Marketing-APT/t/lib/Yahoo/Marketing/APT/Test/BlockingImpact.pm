package Yahoo::Marketing::APT::Test::BlockingImpact;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::BlockingImpact;

sub test_can_create_blocking_impact_and_set_all_fields : Test(6) {

    my $blocking_impact = Yahoo::Marketing::APT::BlockingImpact->new
                                                          ->percentageBlockedByAdBehaviorsFilter( 'percentage blocked by ad behaviors filter' )
                                                          ->percentageBlockedByAdContentTopicsFilter( 'percentage blocked by ad content topics filter' )
                                                          ->percentageBlockedByAdThemesFilter( 'percentage blocked by ad themes filter' )
                                                          ->percentageBlockedByAdvertiserAndNetworksFilter( 'percentage blocked by advertiser and networks filter' )
                                                          ->percentageBlockedByReviewedAdsOnlyFilter( 'percentage blocked by reviewed ads only filter' )
                   ;

    ok( $blocking_impact );

    is( $blocking_impact->percentageBlockedByAdBehaviorsFilter, 'percentage blocked by ad behaviors filter', 'can get percentage blocked by ad behaviors filter' );
    is( $blocking_impact->percentageBlockedByAdContentTopicsFilter, 'percentage blocked by ad content topics filter', 'can get percentage blocked by ad content topics filter' );
    is( $blocking_impact->percentageBlockedByAdThemesFilter, 'percentage blocked by ad themes filter', 'can get percentage blocked by ad themes filter' );
    is( $blocking_impact->percentageBlockedByAdvertiserAndNetworksFilter, 'percentage blocked by advertiser and networks filter', 'can get percentage blocked by advertiser and networks filter' );
    is( $blocking_impact->percentageBlockedByReviewedAdsOnlyFilter, 'percentage blocked by reviewed ads only filter', 'can get percentage blocked by reviewed ads only filter' );

};



1;

