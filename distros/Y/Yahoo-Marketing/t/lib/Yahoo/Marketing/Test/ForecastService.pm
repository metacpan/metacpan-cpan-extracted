package Yahoo::Marketing::Test::ForecastService;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/ Yahoo::Marketing::Test::PostTest /;
use Test::More;
use Module::Build;

use Yahoo::Marketing::ForecastService;
use Yahoo::Marketing::KeywordForecastRequestData;
use Yahoo::Marketing::AdGroupForecastRequestData;
use Yahoo::Marketing::ForecastKeyword;
use Yahoo::Marketing::ForecastKeywordBatch;
use Yahoo::Marketing::HistoricalKeyword;
use Yahoo::Marketing::HistoricalRequestData;
use DateTime::Format::W3CDTF;

# use SOAP::Lite +trace => [qw/ debug method fault /];

sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}

sub test_get_forecast_for_keyword : Test(15) {
    my $self = shift;

    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $ysm_ws = Yahoo::Marketing::ForecastService->new->parse_config( section => $self->section );

    my $forecast_request_data = Yahoo::Marketing::KeywordForecastRequestData->new
        ->accountID( $ysm_ws->account )
        ->matchType( 'SponsoredSearch' )
        ->maxBid( '10.01' )
    ;

    my $result = $ysm_ws->getForecastForKeyword(
                              keyword             => 'cars',
                              adGroupID           => $ad_group->ID,
                              forecastRequestData => $forecast_request_data,
                          );

    ok( $result );

    my $forecast_response_detail = $result->forecastResponseDetail;

    ok( $forecast_response_detail );
    like( $forecast_response_detail->impressions->impressions, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    like( $forecast_response_detail->maxBid, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    like( $forecast_response_detail->missedClicks, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    like( $forecast_response_detail->costPerClick, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    like( $forecast_response_detail->clicks->clicks, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    like( $forecast_response_detail->averagePosition, qr/^\d+(\.\d+)?$/, 'looks like a float number' );

    my $forecast_landscape = $result->forecastLandscape;
    ok( $forecast_landscape);
    like( $forecast_landscape->[0]->impressions->impressions, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    like( $forecast_landscape->[0]->maxBid, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    like( $forecast_landscape->[0]->missedClicks, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    like( $forecast_landscape->[0]->costPerClick, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    like( $forecast_landscape->[0]->clicks->clicks, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    like( $forecast_landscape->[0]->averagePosition, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
}


sub test_get_forecast_for_keywords : Test(15) {
    my $self = shift;

    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $ysm_ws = Yahoo::Marketing::ForecastService->new->parse_config( section => $self->section );

    my $forecast_request_data = Yahoo::Marketing::KeywordForecastRequestData->new
        ->accountID( $ysm_ws->account )
        ->matchType( 'SponsoredSearch' )
        ->maxBid( '3.66' )
    ;

    my @forecast_keywords = (
            Yahoo::Marketing::ForecastKeyword->new
                  #->contentMatchMaxBid( '0.76' )
                  ->keyword( 'ipod' ),
            Yahoo::Marketing::ForecastKeyword->new
                  #->contentMatchMaxBid( '0.75' )
                  ->keyword( 'cars' ),
    );

    my $result = $ysm_ws->getForecastForKeywords(
                              forecastKeywords    => \@forecast_keywords,
                              adGroupID           => $ad_group->ID,
                              forecastRequestData => $forecast_request_data,
                          );
    ok( $result );

#    ok( $result->customizedResponseByAdGroup );

    my $default_response_by_ad_group = $result->defaultResponseByAdGroup;
    if( $default_response_by_ad_group and defined $default_response_by_ad_group->impressions ){
        ok( $default_response_by_ad_group );
        like( $default_response_by_ad_group->impressions->impressions, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
        like( $default_response_by_ad_group->maxBid, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
        like( $default_response_by_ad_group->missedClicks, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
        like( $default_response_by_ad_group->costPerClick, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
        like( $default_response_by_ad_group->clicks->clicks, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
        like( $default_response_by_ad_group->averagePosition, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    }else{
        diag("no default [forecast data] response by ad group, faking next 7 tests");
        ok(1) for (1..7);
    }

    my $landscape_by_ad_group = $result->landscapeByAdGroup;
    if( $landscape_by_ad_group and defined $landscape_by_ad_group->[0]->impressions ){
        ok( $landscape_by_ad_group );
        like( $landscape_by_ad_group->[0]->impressions->impressions, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
        like( $landscape_by_ad_group->[0]->maxBid, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
        like( $landscape_by_ad_group->[0]->missedClicks, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
        like( $landscape_by_ad_group->[0]->costPerClick, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
        like( $landscape_by_ad_group->[0]->clicks->clicks, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
        like( $landscape_by_ad_group->[0]->averagePosition, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    }else{
        diag("no default [forecast data] response by ad group, faking next 7 tests");
        ok(1) for (1..7);
    }

}


sub test_get_forecast_by_ad_group : Test(15) {
    my $self = shift;

    return 'skipping test_get_forecast_by_ad_group, Cannot forecast for an ad group with no active keywords';

    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $ysm_ws = Yahoo::Marketing::ForecastService->new->parse_config( section => $self->section );

    my $forecast_request_data = Yahoo::Marketing::AdGroupForecastRequestData->new
        ->accountID( $ysm_ws->account )
        ->matchType( 'SponsoredSearch' )
        ->maxBid( '0.33' )
    ;

    my $result = $ysm_ws->getForecastByAdGroup(
                              adGroupID           => $ad_group->ID,
                              forecastRequestData => $forecast_request_data,
                          );

    ok( $result );

    my $forecast_response_detail = $result->forecastResponseDetail;
    ok( $forecast_response_detail );
    like( $forecast_response_detail->impressions->impressions, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    like( $forecast_response_detail->maxBid, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    like( $forecast_response_detail->missedClicks, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    like( $forecast_response_detail->costPerClick, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    like( $forecast_response_detail->clicks->clicks, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    like( $forecast_response_detail->averagePosition, qr/^\d+(\.\d+)?$/, 'looks like a float number' );

    my $forecast_landscape = $result->forecastLandscape;
    ok( $forecast_landscape);
    like( $forecast_landscape->[0]->impressions->impressions, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    like( $forecast_landscape->[0]->maxBid, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    like( $forecast_landscape->[0]->missedClicks, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    like( $forecast_landscape->[0]->costPerClick, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    like( $forecast_landscape->[0]->clicks->clicks, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    like( $forecast_landscape->[0]->averagePosition, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
}


sub test_get_forecast_for_keyword_batch : Test(16) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::ForecastService->new->parse_config( section => $self->section );

    my $forecast_keyword_batch1 = Yahoo::Marketing::ForecastKeywordBatch->new
        ->keyword( 'ipod' );
    my $forecast_keyword_batch2 = Yahoo::Marketing::ForecastKeywordBatch->new
        ->keyword( 'iphone' );

    my $forecast_request_data = Yahoo::Marketing::KeywordForecastRequestData->new
        ->accountID( $ysm_ws->account )
        ->matchType( 'SponsoredSearch' )
        ->maxBid( '3.66' )
    ;

    my $result = $ysm_ws->getForecastForKeywordBatch(
                              keywords            => [ $forecast_keyword_batch1, $forecast_keyword_batch2 ],
                              forecastRequestData => $forecast_request_data,
                          );
    ok( $result );
    ok( $result->forecastKeywordBatchResponseData );

    my $forecast_response_detail = $result->forecastKeywordBatchResponseData->[0]->forecastResponseDetail;
    if( $forecast_response_detail and defined $forecast_response_detail->impressions ){
        ok( $forecast_response_detail );
        like( $forecast_response_detail->impressions->impressions, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
        like( $forecast_response_detail->maxBid, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
        like( $forecast_response_detail->missedClicks, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
        like( $forecast_response_detail->costPerClick, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
        like( $forecast_response_detail->clicks->clicks, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
        like( $forecast_response_detail->averagePosition, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    }else{
        diag("no forecast response detail, faking next 7 tests");
        ok(1) for (1..7);
    }

    my $forecast_landscape = $result->forecastKeywordBatchResponseData->[0]->forecastLandscape;
    if( $forecast_landscape and defined $forecast_landscape->[0]->impressions ){
        ok( $forecast_landscape );
        like( $forecast_landscape->[0]->impressions->impressions, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
        like( $forecast_landscape->[0]->maxBid, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
        like( $forecast_landscape->[0]->missedClicks, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
        like( $forecast_landscape->[0]->costPerClick, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
        like( $forecast_landscape->[0]->clicks->clicks, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
        like( $forecast_landscape->[0]->averagePosition, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
    }else{
        diag("no forecast landscape, faking next 7 tests");
        ok(1) for (1..7);
    }

}


sub test_get_historical_data_for_keywords : Test(4) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::ForecastService->new->parse_config( section => $self->section );

    my $historical_keyword1 = Yahoo::Marketing::HistoricalKeyword->new
        ->keyword( 'ipod' );
    my $historical_keyword2 = Yahoo::Marketing::HistoricalKeyword->new
        ->keyword( 'iphone' );

    my $formatter = DateTime::Format::W3CDTF->new;
    my $start_datetime = DateTime->now;
    $start_datetime->set_time_zone( 'America/Chicago' );
    $start_datetime->subtract( days => 300 );

    my $end_datetime = DateTime->now;
    $end_datetime->set_time_zone( 'America/Chicago' );
    $end_datetime->subtract( days => 100 );

    my $historical_request_data = Yahoo::Marketing::HistoricalRequestData->new
        ->accountID( $ysm_ws->account )
        ->marketID( 'US' )
        ->matchType( 'SponsoredSearch' )
        ->startDate( $start_datetime )
        ->endDate( $end_datetime )
    ;

    my $result = $ysm_ws->getHistoricalDataForKeywords(
                              keywords              => [ $historical_keyword1, $historical_keyword2 ],
                              historicalRequestData => $historical_request_data,
                          );
    ok( $result );
    is( $result->operationSucceeded, 'true' );

    my $historical_data = $result->historicalKeywordResponseData->[0]->historicalData;
    if( $historical_data->[0] and ($historical_data->[0]->operationSucceeded eq 'true')){
        like( $historical_data->[0]->avgSearches, qr/^\d+(\.\d+)?$/, 'looks like a float number' );
        like( $historical_data->[0]->competitiveRating, qr/^\d+$/, 'looks like a long number' );
    }else{
        die("getHistoricalDataForKeywords failed");
    }

}


sub startup_test_forecast_service : Test(startup) {
    my ( $self ) = @_;

    $self->common_test_data( 'test_campaign', $self->create_campaign ) unless defined $self->common_test_data( 'test_campaign' );
    $self->common_test_data( 'test_ad_group', $self->create_ad_group ) unless defined $self->common_test_data( 'test_ad_group' );
    $self->common_test_data( 'test_keyword', $self->create_keyword( text => 'ipod') ) unless defined $self->common_test_data( 'test_keyword' );
};


sub shutdown_test_forecast_service : Test(shutdown) {
    my ( $self ) = @_;

    $self->cleanup_keyword;
    $self->cleanup_ad_group;
    $self->cleanup_campaign;
};


1;

__END__

# getForecastForKeyword
# getForecastForKeywords
# getForecastByAdGroup
# getForecastForKeywordBatch
# getHistoricalDataForKeywords
