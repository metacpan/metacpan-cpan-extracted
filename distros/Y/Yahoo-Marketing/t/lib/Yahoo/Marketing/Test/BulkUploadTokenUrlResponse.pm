package Yahoo::Marketing::Test::BulkUploadTokenUrlResponse;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::BulkUploadTokenUrlResponse;

sub test_can_create_bulk_upload_token_url_response_and_set_all_fields : Test(3) {

    my $bulk_upload_token_url_response = Yahoo::Marketing::BulkUploadTokenUrlResponse->new
                                                                                     ->jobId( 'job id' )
                                                                                     ->url( 'url' )
                   ;

    ok( $bulk_upload_token_url_response );

    is( $bulk_upload_token_url_response->jobId, 'job id', 'can get job id' );
    is( $bulk_upload_token_url_response->url, 'url', 'can get url' );

};



1;

