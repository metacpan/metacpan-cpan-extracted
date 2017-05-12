package Yahoo::Marketing::APT::Test::ScheduledReport;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ScheduledReport;

sub test_can_create_scheduled_report_and_set_all_fields : Test(8) {

    my $scheduled_report = Yahoo::Marketing::APT::ScheduledReport->new
                                                            ->ID( 'id' )
                                                            ->additionalRecipients( 'additional recipients' )
                                                            ->deliveryMethod( 'delivery method' )
                                                            ->fileType( 'file type' )
                                                            ->frequency( 'frequency' )
                                                            ->name( 'name' )
                                                            ->reportRequest( 'report request' )
                   ;

    ok( $scheduled_report );

    is( $scheduled_report->ID, 'id', 'can get id' );
    is( $scheduled_report->additionalRecipients, 'additional recipients', 'can get additional recipients' );
    is( $scheduled_report->deliveryMethod, 'delivery method', 'can get delivery method' );
    is( $scheduled_report->fileType, 'file type', 'can get file type' );
    is( $scheduled_report->frequency, 'frequency', 'can get frequency' );
    is( $scheduled_report->name, 'name', 'can get name' );
    is( $scheduled_report->reportRequest, 'report request', 'can get report request' );

};



1;

