package Yahoo::Marketing::APT::Test::ReportService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::ReportService;
use Yahoo::Marketing::APT::Report;
use Yahoo::Marketing::APT::ReportRequest;
use Yahoo::Marketing::APT::DeliveryFormat;
use Yahoo::Marketing::APT::ScheduledReport;

use Data::Dumper;

# use SOAP::Lite +trace => [qw/ debug method fault /];


sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}


sub test_can_get_operate_saved_report : Test(11) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::ReportService->new->parse_config( section => $self->section );

    # test getAvailableReports
    my @reports = $ysm_ws->getAvailableReports();
    ok(@reports, 'can call getAvailableReports');
    ok($reports[0]->columns->[0]->ID, 'can get column id');
    ok($reports[0]->context, 'can get context');
    ok($reports[0]->name, 'can get name' );

    my $report_name;
    # get first available report name of Account context.
    foreach (@reports) {
        if ($_->context eq 'Account') {
            $report_name = $_->name;
            last;
        }
    }
    my $report_request = Yahoo::Marketing::APT::ReportRequest->new
                                                             ->contextID( $ysm_ws->account )
                                                             ->reportName( $report_name )
                                                             ->dateRange( 'Yesterday' )
                                                                 ;
    # test booksClosed
    my $book_closed = $ysm_ws->booksClosed( reportRequest => $report_request );
    ok($book_closed, 'can call booksClosed' );

    # test addSavedReportRequest
    my $report_id = $ysm_ws->addSavedReportRequest(
        reportRequest => $report_request,
    );
    ok( $report_id, 'can call addSavedReportRequest' );

    # test getSavedReportList
    my @report_info = $ysm_ws->getSavedReportList( onlyReady => 'false' );
    ok( @report_info, 'can call getSavedReportList');

    my $find;
    foreach (@report_info) {
        $find = 1 if $_->reportID eq $report_id;
    }
    ok( $find, 'can find saved report' );

    # we will give the server 30 sec to generate the report.
    # test getSavedReportStatus
    my $report_url;
    foreach (0..5) {
        my $report_status = $ysm_ws->getSavedReportStatus(
            reportID => $report_id,
            deliveryFormat => Yahoo::Marketing::APT::DeliveryFormat->new->fileType( 'TSV' )->zipped( 'true' ),
        );

        if ($report_status->reportExecutionStatus eq 'Ready' ) {
            $report_url = $report_status->url;
            last;
        }
        sleep 5;
    }

    if ($report_url) {
        ok( $report_url, 'can get report url' );
    } else {
        # report takes too long to generate.. skip
        ok(1, 'skip waiting report');
    }

    # test deleteSavedReport
    my $response = $ysm_ws->deleteSavedReport( reportID => $report_id );
    ok( $response, 'can call deleteSavedReport' );
    is( $response->operationSucceeded, 'true', 'can delete report' );
}


sub test_can_operate_scheduled_reports : Test(17) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::ReportService->new->parse_config( section => $self->section );

    my @reports = $ysm_ws->getAvailableReports();
    my $report_name;
    # get first available report name of Account context.
    foreach (@reports) {
        if ($_->context eq 'Account') {
            $report_name = $_->name;
            last;
        }
    }
    my $report_request = Yahoo::Marketing::APT::ReportRequest->new
                                                             ->contextID( $ysm_ws->account )
                                                             ->reportName( $report_name )
                                                             ->dateRange( 'Yesterday' )
                                                                 ;

    my $scheduled_report = Yahoo::Marketing::APT::ScheduledReport->new
                                                                 ->additionalRecipients( [qw(test@yahoo-inc.com)] )
                                                                 ->deliveryMethod( 'SavedReports')
                                                                 ->fileType( 'TSV' )
                                                                 ->frequency( 'Daily' )
                                                                 ->name( 'test scheduled report' )
                                                                 ->reportRequest( $report_request )
                                                                     ;
    # test addScheduledReport
    my $response = $ysm_ws->addScheduledReport( scheduledReport => $scheduled_report );
    ok( $response, 'can call scheduledReport' );
    $scheduled_report = $response->scheduledReport;
    is( $scheduled_report->name, 'test scheduled report', 'can add scheduled report' );

    # test updateScheduledReport
    $scheduled_report->name( 'new scheduled report' );
    $response = $ysm_ws->updateScheduledReport( scheduledReport => $scheduled_report );
    ok( $response, 'can call updateScheduledReport' );
    is( $response->operationSucceeded, 'true', 'can update scheduled report' );
    $scheduled_report = $response->scheduledReport;
    is( $scheduled_report->name, 'new scheduled report', 'name matches' );

    # test updateScheduledReports
    $scheduled_report->name( 'second scheduled report' );
    my @responses = $ysm_ws->updateScheduledReports( scheduledReports => [$scheduled_report] );
    ok( @responses, 'can call updateScheduledReports' );
    is( $responses[0]->operationSucceeded, 'true', 'can update scheduled reports' );
    $scheduled_report = $responses[0]->scheduledReport;
    is( $scheduled_report->name, 'second scheduled report', 'name matches' );

    # test getScheduledReport
    $scheduled_report = $ysm_ws->getScheduledReport( scheduledReportID => $scheduled_report->ID );
    ok( $scheduled_report, 'can call getScheduledReport' );
    is( $scheduled_report->name, 'second scheduled report', 'can get scheduled report' );

    # test getScheduledReports
    my @scheduled_reports = $ysm_ws->getScheduledReports( scheduledReportIDs => [$scheduled_report->ID] );
    ok( @scheduled_reports, 'can call getScheduledReports' );
    is( $scheduled_reports[0]->name, 'second scheduled report', 'can get scheduled reports' );

    # test getScheduledReportsForUser
    @scheduled_reports = $ysm_ws->getScheduledReportsForUser();
    ok( @scheduled_reports, 'can call getScheduledReports' );
    is( $scheduled_reports[0]->name, 'second scheduled report', 'can get scheduled reports' );

    # test addScheduledReportRequest
    my $scheduled_report_request_id = $ysm_ws->addScheduledReportRequest( scheduledReportID => $scheduled_report->ID );
    ok( $scheduled_report_request_id, 'can call addScheduledReportRequest' );
    $ysm_ws->deleteSavedReport( reportID => $scheduled_report_request_id );

    # test deleteScheduledReport
    $response = $ysm_ws->deleteScheduledReport( scheduledReportID => $scheduled_report->ID );
    ok( $response, 'can call deleteScheduledReport' );
    is( $response->operationSucceeded, 'true', 'delete scheduled report successfully' );


}



1;
