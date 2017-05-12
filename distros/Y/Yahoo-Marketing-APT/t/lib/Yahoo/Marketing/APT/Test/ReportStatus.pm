package Yahoo::Marketing::APT::Test::ReportStatus;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ReportStatus;

sub test_can_create_report_status_and_set_all_fields : Test(3) {

    my $report_status = Yahoo::Marketing::APT::ReportStatus->new
                                                      ->reportExecutionStatus( 'report execution status' )
                                                      ->url( 'url' )
                   ;

    ok( $report_status );

    is( $report_status->reportExecutionStatus, 'report execution status', 'can get report execution status' );
    is( $report_status->url, 'url', 'can get url' );

};



1;

