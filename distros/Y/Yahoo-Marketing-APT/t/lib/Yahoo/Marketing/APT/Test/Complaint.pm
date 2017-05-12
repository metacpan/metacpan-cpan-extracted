package Yahoo::Marketing::APT::Test::Complaint;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::Complaint;

sub test_can_create_complaint_and_set_all_fields : Test(13) {

    my $complaint = Yahoo::Marketing::APT::Complaint->new
                                               ->ID( 'id' )
                                               ->accountID( 'account id' )
                                               ->createTimestamp( '2009-01-06T17:51:55' )
                                               ->createdByUserID( 'created by user id' )
                                               ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                               ->reason( 'reason' )
                                               ->reasonID( 'reason id' )
                                               ->resolutionID( 'resolution id' )
                                               ->responseTimestamp( '2009-01-08T17:51:55' )
                                               ->status( 'status' )
                                               ->tagID( 'tag id' )
                                               ->tagType( 'tag type' )
                   ;

    ok( $complaint );

    is( $complaint->ID, 'id', 'can get id' );
    is( $complaint->accountID, 'account id', 'can get account id' );
    is( $complaint->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $complaint->createdByUserID, 'created by user id', 'can get created by user id' );
    is( $complaint->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $complaint->reason, 'reason', 'can get reason' );
    is( $complaint->reasonID, 'reason id', 'can get reason id' );
    is( $complaint->resolutionID, 'resolution id', 'can get resolution id' );
    is( $complaint->responseTimestamp, '2009-01-08T17:51:55', 'can get 2009-01-08T17:51:55' );
    is( $complaint->status, 'status', 'can get status' );
    is( $complaint->tagID, 'tag id', 'can get tag id' );
    is( $complaint->tagType, 'tag type', 'can get tag type' );

};



1;

