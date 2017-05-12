package Yahoo::Marketing::Test::BidInformationService;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/ Yahoo::Marketing::Test::PostTest /;
use Test::More;

use Yahoo::Marketing::BidInformation;
use Yahoo::Marketing::MasterAccountService;
use Yahoo::Marketing::BidInformationService;

#use SOAP::Lite +trace => [qw/ debug method fault /];

sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}

sub test_get_bids_for_best_rank : Test(3) {
    my ( $self ) = @_;

    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $ysm_ws = Yahoo::Marketing::BidInformationService->new->parse_config( section => $self->section );

    my $bid_information = $ysm_ws->getBidsForBestRank(
        adGroupID => $ad_group->ID,
        keyword   => 'porsche',
    );

    ok( $bid_information );
    like( $bid_information->bid, qr/^\d+(\.\d+)?$/, 'bid looks like float' );
    like( $bid_information->cutOffBid, qr/^\d+(\.\d+)?$/, 'cutOffBid looks like float' );
}

sub test_get_market_bids_for_best_rank : Test(3) {
    my ( $self ) = @_;

    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $ms_ws = Yahoo::Marketing::MasterAccountService->new->parse_config( section => $self->section );

    my $master_account = $ms_ws->getMasterAccount( masterAccountID => $ms_ws->master_account );

    my $ysm_ws = Yahoo::Marketing::BidInformationService->new->parse_config( section => $self->section );

    my $bid_information = $ysm_ws->getMarketBidsForBestRank(
        adGroupID => $ad_group->ID,
        keyword   => 'porsche',
        marketID  => $master_account->marketID,
    );

    ok( $bid_information );
    like( $bid_information->bid, qr/^\d+(\.\d+)?$/, 'bid looks like float' );
    like( $bid_information->cutOffBid, qr/^\d+(\.\d+)?$/, 'cutOffBid looks like float' );
}

sub test_get_min_bids_for_keyword_string : Test(2) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::BidInformationService->new->parse_config( section => $self->section );

    SKIP: {
        skip "getMinBidForKeywordString not available after V3", 2 unless $ysm_ws->version eq 'V3';

        my $bid = $ysm_ws->getMinBidForKeywordString( keyword => 'porsche' );

        ok( $bid );
        like( $bid, qr/^\d+(\.\d+)?$/, 'bid looks like float' );
    };
}

sub startup_test_bid_information_service : Test(startup) {
    my ( $self ) = @_;

    $self->common_test_data( 'test_campaign', $self->create_campaign ) unless defined $self->common_test_data( 'test_campaign' );
    $self->common_test_data( 'test_ad_group', $self->create_ad_group ) unless defined $self->common_test_data( 'test_ad_group' );
}


sub shutdown_test_bid_information_service : Test(shutdown) {
    my ( $self ) = @_;

    $self->cleanup_ad_group;
    $self->cleanup_campaign;
}

1;

__END__

# getBidsForBestRank
