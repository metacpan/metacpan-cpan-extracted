package Yahoo::Marketing::APT::Test::FilterService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::FilterService;
use Yahoo::Marketing::APT::ConditionalFilter;
use Yahoo::Marketing::APT::PublisherSelector;
use Yahoo::Marketing::APT::UniversalFilter;
use Data::Dumper;

# use SOAP::Lite +trace => [qw/ debug method fault /];


sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}


sub test_operate_filter: Test(20) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::FilterService->new->parse_config( section => $self->section );

    my $publisher_selector = Yahoo::Marketing::APT::PublisherSelector->new
                                                                  ->publisherAccountIDs( [$ysm_ws->account] )
                                                                  ->type( 'PublishersIncluded' )
                                                                      ;
    my $filter = Yahoo::Marketing::APT::ConditionalFilter->new
                                                         ->allowReviewedAdsOnly( 'false' )
                                                         ->isActive( 'false' )
                                                         ->name( 'test filter' )
                                                         ->publisherSelector( $publisher_selector )
                                                             ;

    # test addConditionalFilter
    my $response = $ysm_ws->addConditionalFilter( conditionalFilter => $filter );
    ok( $response, 'can call addConditionalFilter' );
    $filter = $response->filter;
    is( $filter->name, 'test filter', 'name matches' );

    # test getConditionalFilter
    $filter = $ysm_ws->getConditionalFilter( conditionalFilterID => $filter->ID );
    ok( $filter, 'can call getConditionalFilter' );
    is( $filter->name, 'test filter', 'name matches' );

    # test updateConditionalFilter
    $filter->name( 'new test filter' );
    $response = $ysm_ws->updateConditionalFilter( conditionalFilter => $filter );
    ok( $response, 'can call updateConditionalFilter' );
    $filter = $response->filter;
    is( $filter->name, 'new test filter', 'filter updated' );

    # test activateConditionalFilter
    $response = $ysm_ws->activateConditionalFilter( conditionalFilterID => $filter->ID );
    ok( $response, 'can call activateConditionalFilter' );
    is( $response->operationSucceeded, 'true', 'filter activated successfully' );

    # test deactivateConditionalFilter
    $response = $ysm_ws->deactivateConditionalFilter( conditionalFilterID => $filter->ID );
    ok( $response, 'can call deactivateConditionalFilter' );
    is( $response->operationSucceeded, 'true', 'filter deactivated successfully' );

    # test getBlockingImpactForConditionalFilter
    my $blocking_impact = $ysm_ws->getBlockingImpactForConditionalFilter( conditionalFilter => $filter );
    ok( $blocking_impact );

    # test getBlockingImpactForExistingConditionalFilter
    $blocking_impact = $ysm_ws->getBlockingImpactForExistingConditionalFilter( conditionalFilterID => $filter->ID );
    ok( $blocking_impact );

    # test setUniversalFilter
    my $u_filter = Yahoo::Marketing::APT::UniversalFilter->new
                                                         ->allowReviewedAdsOnly( 'false' )
                                                             ;
    $response = $ysm_ws->setUniversalFilter( universalFilter => $u_filter );
    ok( $response, 'can call setUniversalFilter' );
    $u_filter = $response->filter;
    is( $u_filter->accountID, $ysm_ws->account, 'accountID matches' );

    # test getBlockingImpactForExistingUniversalFilter
    $blocking_impact = $ysm_ws->getBlockingImpactForExistingUniversalFilter();
    ok( $blocking_impact );

    # test getBlockingImpactForUniversalFilter
    $blocking_impact = $ysm_ws->getBlockingImpactForUniversalFilter( universalFilter => $u_filter );
    ok( $blocking_impact );

    # test getUniversalFilter
    $u_filter = $ysm_ws->getUniversalFilter();
    ok( $u_filter, 'can call getUniversalFilter' );
    is( $u_filter->accountID, $ysm_ws->account, 'accountID matches' );

    # test deleteConditionalFilter
    $response = $ysm_ws->deleteConditionalFilter( conditionalFilterID => $filter->ID );
    ok( $response, 'can call deleteConditionalFilter' );
    is( $response->operationSucceeded, 'true', 'filter deleted successfully' );

}


sub test_operate_filters: Test(15) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::FilterService->new->parse_config( section => $self->section );

    my $publisher_selector = Yahoo::Marketing::APT::PublisherSelector->new
                                                                  ->publisherAccountIDs( [$ysm_ws->account] )
                                                                  ->type( 'PublishersIncluded' )
                                                                      ;
    my $filter = Yahoo::Marketing::APT::ConditionalFilter->new
                                                         ->allowReviewedAdsOnly( 'false' )
                                                         ->isActive( 'false' )
                                                         ->name( 'test filter' )
                                                         ->publisherSelector( $publisher_selector )
                                                             ;

    # test addConditionalFilters
    my @responses = $ysm_ws->addConditionalFilters( conditionalFilters => [$filter] );
    ok( @responses, 'can call addConditionalFilters' );
    $filter = $responses[0]->filter;
    is( $filter->name, 'test filter', 'name matches' );

    # test getConditionalFilters
    my @filters = $ysm_ws->getConditionalFilters( conditionalFilterIDs => [$filter->ID] );
    ok( @filters, 'can call getConditionalFilters' );
    is( $filters[0]->name, 'test filter', 'name matches' );

    # test updateConditionalFilters
    $filter->name( 'new test filter' );
    @responses = $ysm_ws->updateConditionalFilters( conditionalFilters => [$filter] );
    ok( @responses, 'can call updateConditionalFilters' );
    $filter = $responses[0]->filter;
    is( $filter->name, 'new test filter', 'filter updated' );

    # test activateConditionalFilters
    @responses = $ysm_ws->activateConditionalFilters( conditionalFilterIDs => [$filter->ID] );
    ok( @responses, 'can call activateConditionalFilters' );
    is( $responses[0]->operationSucceeded, 'true', 'filters activated successfully' );

    # test deactivateConditionalFilters
    @responses = $ysm_ws->deactivateConditionalFilters( conditionalFilterIDs => [$filter->ID] );
    ok( @responses, 'can call deactivateConditionalFilters' );
    is( $responses[0]->operationSucceeded, 'true', 'filters deactivated successfully' );

    # test getBlockingImpactForConditionalFilters
    my @blocking_impacts = $ysm_ws->getBlockingImpactForConditionalFilters( conditionalFilters => [$filter] );
    ok( @blocking_impacts );

    # test getBlockingImpactForExistingConditionalFilters
    @blocking_impacts = $ysm_ws->getBlockingImpactForExistingConditionalFilters( conditionalFilterIDs => [$filter->ID] );
    ok( @blocking_impacts );


    # test getConditionalFiltersByAccountID
    @filters = $ysm_ws->getConditionalFiltersByAccountID();
    ok( @filters, 'can call getConditionalFiltersByAccountID' );

    # test deleteConditionalFilters
    @responses = $ysm_ws->deleteConditionalFilters( conditionalFilterIDs => [$filter->ID] );
    ok( @responses, 'can call deleteConditionalFilters' );
    is( $responses[0]->operationSucceeded, 'true', 'filters deleted successfully' );

}



1;
