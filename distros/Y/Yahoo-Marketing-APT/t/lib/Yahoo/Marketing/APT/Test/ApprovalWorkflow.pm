package Yahoo::Marketing::APT::Test::ApprovalWorkflow;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ApprovalWorkflow;

sub test_can_create_approval_workflow_and_set_all_fields : Test(13) {

    my $approval_workflow = Yahoo::Marketing::APT::ApprovalWorkflow->new
                                                              ->ID( 'id' )
                                                              ->accountID( 'account id' )
                                                              ->approvalCategory( 'approval category' )
                                                              ->approvalType( 'approval type' )
                                                              ->approvers( 'approvers' )
                                                              ->createTimestamp( '2009-01-06T17:51:55' )
                                                              ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                                              ->name( 'name' )
                                                              ->notificationType( 'notification type' )
                                                              ->status( 'status' )
                                                              ->trigger( 'trigger' )
                                                              ->workflowExecutionType( 'workflow execution type' )
                   ;

    ok( $approval_workflow );

    is( $approval_workflow->ID, 'id', 'can get id' );
    is( $approval_workflow->accountID, 'account id', 'can get account id' );
    is( $approval_workflow->approvalCategory, 'approval category', 'can get approval category' );
    is( $approval_workflow->approvalType, 'approval type', 'can get approval type' );
    is( $approval_workflow->approvers, 'approvers', 'can get approvers' );
    is( $approval_workflow->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $approval_workflow->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $approval_workflow->name, 'name', 'can get name' );
    is( $approval_workflow->notificationType, 'notification type', 'can get notification type' );
    is( $approval_workflow->status, 'status', 'can get status' );
    is( $approval_workflow->trigger, 'trigger', 'can get trigger' );
    is( $approval_workflow->workflowExecutionType, 'workflow execution type', 'can get workflow execution type' );

};



1;

