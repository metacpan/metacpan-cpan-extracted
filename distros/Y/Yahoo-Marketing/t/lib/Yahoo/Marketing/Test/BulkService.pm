package Yahoo::Marketing::Test::BulkService;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Test::Class Yahoo::Marketing::Test::PostTest /;
use Test::More;

use Yahoo::Marketing::BulkService;
use Data::Dumper;

# use SOAP::Lite +trace => [qw/ debug method fault /];

sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}

sub startup_test_bulk_service : Test(startup) {
    my ( $self ) = @_;

    $self->common_test_data( 'test_campaign', $self->create_campaign ) unless defined $self->common_test_data( 'test_campaign' );
}

sub shutdown_test_campaign_service : Test(shutdown) {
    my ( $self ) = @_;

    $self->cleanup_campaign;
}


sub test_bulk_service : Test(1) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::BulkService->new->parse_config( section => $self->section );

    my $id = $ysm_ws->downloadBulkTemplate( fileType => 'TSV' );
    ok( $id, 'can call downloadBulkTemplate' );

}

sub test_download_account : Test(4) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::BulkService->new->parse_config( section => $self->section );

    my $id = $ysm_ws->downloadAccount(
        fileType => 'TSV',
    );

    ok( $id );

    my $response;
    my $status;
    for my $try (1..5) {
        $response = $ysm_ws->getBulkDownloadStatus(
            bulkDownloadID => $id,
        );

        $status = $response->status;
        last if $status eq 'Successful';
        sleep 5;
    }

    is( $status, 'Successful');
    ok( $response->downloadUrl );
    ok( $response->locale );

}

sub test_download_campaign : Test(4) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::BulkService->new->parse_config( section => $self->section );

    my $id = $ysm_ws->downloadCampaigns(
        campaignIDs => [$self->common_test_data( 'test_campaign' )->ID],
        fileType => 'TSV',
    );

    ok( $id );

    my $response;
    my $status;
    for my $try (1..5) {
        $response = $ysm_ws->getBulkDownloadStatus(
            bulkDownloadID => $id,
        );

        $status = $response->status;
        last if $status eq 'Successful';
        sleep 5;
    }

    is( $status, 'Successful');
    ok( $response->downloadUrl );
    ok( $response->locale );

}

1;
