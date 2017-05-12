package Yahoo::Marketing::Test::BulkUploadStatusResponse;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::BulkUploadStatusResponse;

sub test_can_create_bulk_upload_status_response_and_set_all_fields : Test(4) {

    my $bulk_upload_status_response = Yahoo::Marketing::BulkUploadStatusResponse->new
                                                                                ->feedbackFileUrl( 'feedback file url' )
                                                                                ->timeRemaining( 'time remaining' )
                                                                                ->uploadStatus( 'upload status' )
                   ;

    ok( $bulk_upload_status_response );

    is( $bulk_upload_status_response->feedbackFileUrl, 'feedback file url', 'can get feedback file url' );
    is( $bulk_upload_status_response->timeRemaining, 'time remaining', 'can get time remaining' );
    is( $bulk_upload_status_response->uploadStatus, 'upload status', 'can get upload status' );

};



1;

