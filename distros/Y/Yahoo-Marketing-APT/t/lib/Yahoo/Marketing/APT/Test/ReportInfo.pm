package Yahoo::Marketing::APT::Test::ReportInfo;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ReportInfo;

sub test_can_create_report_info_and_set_all_fields : Test(5) {

    my $report_info = Yahoo::Marketing::APT::ReportInfo->new
                                                  ->createTimestamp( '2009-01-06T17:51:55' )
                                                  ->reportExecutionStatus( 'report execution status' )
                                                  ->reportID( 'report id' )
                                                  ->reportName( 'report name' )
                   ;

    ok( $report_info );

    is( $report_info->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $report_info->reportExecutionStatus, 'report execution status', 'can get report execution status' );
    is( $report_info->reportID, 'report id', 'can get report id' );
    is( $report_info->reportName, 'report name', 'can get report name' );

};



1;

