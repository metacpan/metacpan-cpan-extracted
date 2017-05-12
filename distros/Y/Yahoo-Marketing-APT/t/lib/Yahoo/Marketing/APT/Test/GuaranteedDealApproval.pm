package Yahoo::Marketing::APT::Test::GuaranteedDealApproval;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::GuaranteedDealApproval;

sub test_can_create_guaranteed_deal_approval_and_set_all_fields : Test(8) {

    my $guaranteed_deal_approval = Yahoo::Marketing::APT::GuaranteedDealApproval->new
                                                                           ->approvalStatus( 'approval status' )
                                                                           ->comments( 'comments' )
                                                                           ->proposedAudienceSharingRuleID( 'proposed audience sharing rule id' )
                                                                           ->proposedEndDate( '2009-01-06T17:51:55' )
                                                                           ->proposedRevenueShare( 'proposed revenue share' )
                                                                           ->proposedSellingRuleID( 'proposed selling rule id' )
                                                                           ->proposedStartDate( '2009-01-07T17:51:55' )
                   ;

    ok( $guaranteed_deal_approval );

    is( $guaranteed_deal_approval->approvalStatus, 'approval status', 'can get approval status' );
    is( $guaranteed_deal_approval->comments, 'comments', 'can get comments' );
    is( $guaranteed_deal_approval->proposedAudienceSharingRuleID, 'proposed audience sharing rule id', 'can get proposed audience sharing rule id' );
    is( $guaranteed_deal_approval->proposedEndDate, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $guaranteed_deal_approval->proposedRevenueShare, 'proposed revenue share', 'can get proposed revenue share' );
    is( $guaranteed_deal_approval->proposedSellingRuleID, 'proposed selling rule id', 'can get proposed selling rule id' );
    is( $guaranteed_deal_approval->proposedStartDate, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );

};



1;

