package Yahoo::Marketing::Test::ReportDownloadInfo;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::ReportDownloadInfo;

sub test_can_create_report_download_info_and_set_all_fields : Test(5) {

    my $report_download_info = Yahoo::Marketing::ReportDownloadInfo->new
                                                                   ->downloadUrl( 'download url' )
                                                                   ->fileOutputFormat( 'file output format' )
                                                                   ->reportID( 'report id' )
                                                                   ->reportStatus( 'report status' )
                   ;

    ok( $report_download_info );

    is( $report_download_info->downloadUrl, 'download url', 'can get download url' );
    is( $report_download_info->fileOutputFormat, 'file output format', 'can get file output format' );
    is( $report_download_info->reportID, 'report id', 'can get report id' );
    is( $report_download_info->reportStatus, 'report status', 'can get report status' );

};



1;

