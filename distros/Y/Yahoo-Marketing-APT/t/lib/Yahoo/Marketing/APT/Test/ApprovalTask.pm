package Yahoo::Marketing::APT::Test::ApprovalTask;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ApprovalTask;

sub test_can_create_approval_task_and_set_all_fields : Test(12) {

    my $approval_task = Yahoo::Marketing::APT::ApprovalTask->new
                                                      ->ID( 'id' )
                                                      ->accountID( 'account id' )
                                                      ->approvalID( 'approval id' )
                                                      ->approvalObject( 'approval object' )
                                                      ->approvalTrigger( 'approval trigger' )
                                                      ->assignedToApprover( 'assigned to approver' )
                                                      ->blockerApprovalTaskID( 'blocker approval task id' )
                                                      ->comment( 'comment' )
                                                      ->createTimestamp( '2009-01-06T17:51:55' )
                                                      ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                                      ->status( 'status' )
                   ;

    ok( $approval_task );

    is( $approval_task->ID, 'id', 'can get id' );
    is( $approval_task->accountID, 'account id', 'can get account id' );
    is( $approval_task->approvalID, 'approval id', 'can get approval id' );
    is( $approval_task->approvalObject, 'approval object', 'can get approval object' );
    is( $approval_task->approvalTrigger, 'approval trigger', 'can get approval trigger' );
    is( $approval_task->assignedToApprover, 'assigned to approver', 'can get assigned to approver' );
    is( $approval_task->blockerApprovalTaskID, 'blocker approval task id', 'can get blocker approval task id' );
    is( $approval_task->comment, 'comment', 'can get comment' );
    is( $approval_task->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $approval_task->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $approval_task->status, 'status', 'can get status' );

};



1;

