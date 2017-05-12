package Yahoo::Marketing::APT::Test::ApprovalTaskComment;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ApprovalTaskComment;

sub test_can_create_approval_task_comment_and_set_all_fields : Test(5) {

    my $approval_task_comment = Yahoo::Marketing::APT::ApprovalTaskComment->new
                                                                     ->comment( 'comment' )
                                                                     ->lastUpdateTimestamp( '2009-01-06T17:51:55' )
                                                                     ->status( 'status' )
                                                                     ->username( 'username' )
                   ;

    ok( $approval_task_comment );

    is( $approval_task_comment->comment, 'comment', 'can get comment' );
    is( $approval_task_comment->lastUpdateTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $approval_task_comment->status, 'status', 'can get status' );
    is( $approval_task_comment->username, 'username', 'can get username' );

};



1;

