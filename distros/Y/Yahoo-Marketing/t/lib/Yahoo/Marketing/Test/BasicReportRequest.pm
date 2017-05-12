package Yahoo::Marketing::Test::BasicReportRequest;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::BasicReportRequest;

sub test_can_create_basic_report_request_and_set_all_fields : Test(7) {

    my $basic_report_request = Yahoo::Marketing::BasicReportRequest->new
                                                                   ->campaignIDs( 'campaign ids' )
                                                                   ->dateRange( 'date range' )
                                                                   ->endDate( '2008-01-06T17:51:55' )
                                                                   ->reportName( 'report name' )
                                                                   ->reportType( 'report type' )
                                                                   ->startDate( '2008-01-07T17:51:55' )
                   ;

    ok( $basic_report_request );

    is( $basic_report_request->campaignIDs, 'campaign ids', 'can get campaign ids' );
    is( $basic_report_request->dateRange, 'date range', 'can get date range' );
    is( $basic_report_request->endDate, '2008-01-06T17:51:55', 'can get 2008-01-06T17:51:55' );
    is( $basic_report_request->reportName, 'report name', 'can get report name' );
    is( $basic_report_request->reportType, 'report type', 'can get report type' );
    is( $basic_report_request->startDate, '2008-01-07T17:51:55', 'can get 2008-01-07T17:51:55' );

};



1;

