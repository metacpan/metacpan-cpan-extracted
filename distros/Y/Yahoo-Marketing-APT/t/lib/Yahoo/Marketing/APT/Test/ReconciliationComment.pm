package Yahoo::Marketing::APT::Test::ReconciliationComment;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ReconciliationComment;

sub test_can_create_reconciliation_comment_and_set_all_fields : Test(5) {

    my $reconciliation_comment = Yahoo::Marketing::APT::ReconciliationComment->new
                                                                        ->comment( 'comment' )
                                                                        ->createTimestamp( '2009-01-06T17:51:55' )
                                                                        ->userID( 'user id' )
                                                                        ->userName( 'user name' )
                   ;

    ok( $reconciliation_comment );

    is( $reconciliation_comment->comment, 'comment', 'can get comment' );
    is( $reconciliation_comment->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $reconciliation_comment->userID, 'user id', 'can get user id' );
    is( $reconciliation_comment->userName, 'user name', 'can get user name' );

};



1;

