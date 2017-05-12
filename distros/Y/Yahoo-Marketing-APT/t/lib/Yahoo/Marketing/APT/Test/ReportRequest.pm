package Yahoo::Marketing::APT::Test::ReportRequest;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ReportRequest;

sub test_can_create_report_request_and_set_all_fields : Test(8) {

    my $report_request = Yahoo::Marketing::APT::ReportRequest->new
                                                        ->contextID( 'context id' )
                                                        ->dataGrouping( 'data grouping' )
                                                        ->dateRange( 'date range' )
                                                        ->endDate( '2009-01-06T17:51:55' )
                                                        ->reportCurrency( 'report currency' )
                                                        ->reportName( 'report name' )
                                                        ->startDate( '2009-01-07T17:51:55' )
                   ;

    ok( $report_request );

    is( $report_request->contextID, 'context id', 'can get context id' );
    is( $report_request->dataGrouping, 'data grouping', 'can get data grouping' );
    is( $report_request->dateRange, 'date range', 'can get date range' );
    is( $report_request->endDate, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $report_request->reportCurrency, 'report currency', 'can get report currency' );
    is( $report_request->reportName, 'report name', 'can get report name' );
    is( $report_request->startDate, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );

};



1;

