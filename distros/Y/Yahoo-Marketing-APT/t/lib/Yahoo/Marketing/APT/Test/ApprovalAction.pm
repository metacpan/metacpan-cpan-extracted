package Yahoo::Marketing::APT::Test::ApprovalAction;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ApprovalAction;

sub test_can_create_approval_action_and_set_all_fields : Test(3) {

    my $approval_action = Yahoo::Marketing::APT::ApprovalAction->new
                                                          ->approvalTaskID( 'approval task id' )
                                                          ->comments( 'comments' )
                   ;

    ok( $approval_action );

    is( $approval_action->approvalTaskID, 'approval task id', 'can get approval task id' );
    is( $approval_action->comments, 'comments', 'can get comments' );

};



1;

