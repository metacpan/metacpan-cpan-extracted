package Yahoo::Marketing::Test::BulkDownloadStatusInfo;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::BulkDownloadStatusInfo;

sub test_can_create_bulk_download_status_info_and_set_all_fields : Test(5) {

    my $bulk_download_status_info = Yahoo::Marketing::BulkDownloadStatusInfo->new
                                                                            ->downloadUrl( 'download url' )
                                                                            ->locale( 'locale' )
                                                                            ->status( 'status' )
                                                                            ->timeRemaining( 'time remaining' )
                   ;

    ok( $bulk_download_status_info );

    is( $bulk_download_status_info->downloadUrl, 'download url', 'can get download url' );
    is( $bulk_download_status_info->locale, 'locale', 'can get locale' );
    is( $bulk_download_status_info->status, 'status', 'can get status' );
    is( $bulk_download_status_info->timeRemaining, 'time remaining', 'can get time remaining' );

};



1;

