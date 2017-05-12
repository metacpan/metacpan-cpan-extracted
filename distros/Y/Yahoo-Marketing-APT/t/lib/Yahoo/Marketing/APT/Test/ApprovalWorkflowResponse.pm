package Yahoo::Marketing::APT::Test::ApprovalWorkflowResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ApprovalWorkflowResponse;

sub test_can_create_approval_workflow_response_and_set_all_fields : Test(4) {

    my $approval_workflow_response = Yahoo::Marketing::APT::ApprovalWorkflowResponse->new
                                                                               ->approvalWorkflow( 'approval workflow' )
                                                                               ->errors( 'errors' )
                                                                               ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $approval_workflow_response );

    is( $approval_workflow_response->approvalWorkflow, 'approval workflow', 'can get approval workflow' );
    is( $approval_workflow_response->errors, 'errors', 'can get errors' );
    is( $approval_workflow_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

