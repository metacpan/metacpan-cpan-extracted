package Yahoo::Marketing::APT::Test::ScheduledReportResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ScheduledReportResponse;

sub test_can_create_scheduled_report_response_and_set_all_fields : Test(4) {

    my $scheduled_report_response = Yahoo::Marketing::APT::ScheduledReportResponse->new
                                                                             ->errors( 'errors' )
                                                                             ->operationSucceeded( 'operation succeeded' )
                                                                             ->scheduledReport( 'scheduled report' )
                   ;

    ok( $scheduled_report_response );

    is( $scheduled_report_response->errors, 'errors', 'can get errors' );
    is( $scheduled_report_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $scheduled_report_response->scheduledReport, 'scheduled report', 'can get scheduled report' );

};



1;

