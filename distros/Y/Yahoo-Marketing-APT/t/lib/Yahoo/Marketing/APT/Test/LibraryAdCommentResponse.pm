package Yahoo::Marketing::APT::Test::LibraryAdCommentResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::LibraryAdCommentResponse;

sub test_can_create_library_ad_comment_response_and_set_all_fields : Test(4) {

    my $library_ad_comment_response = Yahoo::Marketing::APT::LibraryAdCommentResponse->new
                                                                                ->errors( 'errors' )
                                                                                ->libraryAdComment( 'library ad comment' )
                                                                                ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $library_ad_comment_response );

    is( $library_ad_comment_response->errors, 'errors', 'can get errors' );
    is( $library_ad_comment_response->libraryAdComment, 'library ad comment', 'can get library ad comment' );
    is( $library_ad_comment_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

