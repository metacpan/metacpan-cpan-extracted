package Yahoo::Marketing::APT::Test::LibraryAdComment;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::LibraryAdComment;

sub test_can_create_library_ad_comment_and_set_all_fields : Test(8) {

    my $library_ad_comment = Yahoo::Marketing::APT::LibraryAdComment->new
                                                               ->ID( 'id' )
                                                               ->accountID( 'account id' )
                                                               ->comment( 'comment' )
                                                               ->createTimestamp( '2009-01-06T17:51:55' )
                                                               ->createdByUserID( 'created by user id' )
                                                               ->createdByUserName( 'created by user name' )
                                                               ->libraryAdID( 'library ad id' )
                   ;

    ok( $library_ad_comment );

    is( $library_ad_comment->ID, 'id', 'can get id' );
    is( $library_ad_comment->accountID, 'account id', 'can get account id' );
    is( $library_ad_comment->comment, 'comment', 'can get comment' );
    is( $library_ad_comment->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $library_ad_comment->createdByUserID, 'created by user id', 'can get created by user id' );
    is( $library_ad_comment->createdByUserName, 'created by user name', 'can get created by user name' );
    is( $library_ad_comment->libraryAdID, 'library ad id', 'can get library ad id' );

};



1;

