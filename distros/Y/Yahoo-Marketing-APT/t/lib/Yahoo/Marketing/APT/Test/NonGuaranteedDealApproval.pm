package Yahoo::Marketing::APT::Test::NonGuaranteedDealApproval;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::NonGuaranteedDealApproval;

sub test_can_create_non_guaranteed_deal_approval_and_set_all_fields : Test(6) {

    my $non_guaranteed_deal_approval = Yahoo::Marketing::APT::NonGuaranteedDealApproval->new
                                                                                  ->approvalStatus( 'approval status' )
                                                                                  ->comments( 'comments' )
                                                                                  ->proposedEndDate( '2009-01-06T17:51:55' )
                                                                                  ->proposedRevenueShare( 'proposed revenue share' )
                                                                                  ->proposedStartDate( '2009-01-07T17:51:55' )
                   ;

    ok( $non_guaranteed_deal_approval );

    is( $non_guaranteed_deal_approval->approvalStatus, 'approval status', 'can get approval status' );
    is( $non_guaranteed_deal_approval->comments, 'comments', 'can get comments' );
    is( $non_guaranteed_deal_approval->proposedEndDate, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $non_guaranteed_deal_approval->proposedRevenueShare, 'proposed revenue share', 'can get proposed revenue share' );
    is( $non_guaranteed_deal_approval->proposedStartDate, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );

};



1;

