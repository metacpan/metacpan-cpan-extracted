package Yahoo::Marketing::Test::KeywordService;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/ Test::Class Yahoo::Marketing::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::Keyword;
use Yahoo::Marketing::KeywordService;
use Yahoo::Marketing::KeywordOptimizationGuidelines;

# use SOAP::Lite +trace => [qw/ debug method fault /];

sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}

sub startup_test_keyword_service : Test(startup) {
    my ( $self ) = @_;

    $self->common_test_data( 'test_campaign', $self->create_campaign ) unless defined $self->common_test_data( 'test_campaign' );
    $self->common_test_data( 'test_ad_group', $self->create_ad_group ) unless defined $self->common_test_data( 'test_ad_group' );
    $self->common_test_data( 'test_ad_group2', $self->create_ad_group ) unless defined $self->common_test_data( 'test_ad_group2' );
    $self->common_test_data( 'test_keyword',  $self->create_keyword  ) unless defined $self->common_test_data( 'test_keyword'  );
    $self->common_test_data( 'test_keywords', [ $self->create_keywords ] ) unless defined $self->common_test_data( 'test_keywords' );
}


sub shutdown_test_keyword_service : Test(shutdown) {
    my ( $self ) = @_;

    $self->cleanup_keywords;
    $self->cleanup_keyword;
    $self->cleanup_ad_group;
    $self->cleanup_ad_group( $self->common_test_data( 'test_ad_group2' ) );
    $self->cleanup_campaign;
}

sub test_can_copy_keyword : Test(4) {
    my ( $self ) = @_;

    # create a keyword in ag_group.
    my $added_keyword = $self->create_keyword;

    # now copy the keyword to ad_group2
    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );
    my $new_ss_bid = 99.99;
    ok( $ysm_ws->copyKeyword(
        keywordID => $added_keyword->ID,
        destinationAdGroupID => $self->common_test_data( 'test_ad_group2' )->ID,
        newSponsoredSearchMaxBid => $new_ss_bid,
    ), 'copyKeyword result returned' );

    # now verify it's copied to that adgrp
    my @fetched_keywords = $ysm_ws->getKeywordsByAdGroupID(
        adGroupID      => $self->common_test_data( 'test_ad_group2' )->ID,
        includeDeleted => 'false',
        startElement   => 0,
        numElements    => 1000,
    );

    my $found = 0;
    foreach my $fetched_keyword ( @fetched_keywords ){
        $found = $fetched_keyword->ID if $fetched_keyword->text eq $added_keyword->text and
                                         $fetched_keyword->sponsoredSearchMaxBid == $new_ss_bid;
    }
    ok($found, 'found copied keyword');

    # clean up
    ok( $ysm_ws->deleteKeyword( keywordID => $added_keyword->ID ), 'delete original keyword' );
    ok( $ysm_ws->deleteKeyword( keywordID => $found ), 'delete copied keyword' );
}


sub test_can_move_keyword : Test(4) {
    my ( $self ) = @_;

    # create a keyword in ag_group.
    my $added_keyword = $self->create_keyword;

    # now copy the keyword to ad_group2
    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );
    my $new_ss_bid = 99.99;
    ok( $ysm_ws->moveKeyword(
        keywordID => $added_keyword->ID,
        destinationAdGroupID => $self->common_test_data( 'test_ad_group2' )->ID,
        newSponsoredSearchMaxBid => $new_ss_bid,
    ), 'copyKeyword result returned' );

    # now verify it's not in original adgrp any more
    my @fetched_keywords = $ysm_ws->getKeywordsByAdGroupID(
        adGroupID      => $self->common_test_data( 'test_ad_group' )->ID,
        includeDeleted => 'false',
        startElement   => 0,
        numElements    => 1000,
    );
    my $found = 0;
    foreach my $fetched_keyword ( @fetched_keywords ){
        $found = $fetched_keyword->ID if $fetched_keyword->ID eq $added_keyword->ID;
    }
    ok(!$found, 'not found original keyword');


    # now verify it's copied to that adgrp
    @fetched_keywords = $ysm_ws->getKeywordsByAdGroupID(
        adGroupID      => $self->common_test_data( 'test_ad_group2' )->ID,
        includeDeleted => 'false',
        startElement   => 0,
        numElements    => 1000,
    );

    $found = 0;
    foreach my $fetched_keyword ( @fetched_keywords ){
        $found = $fetched_keyword->ID if $fetched_keyword->text eq $added_keyword->text and
                                         $fetched_keyword->sponsoredSearchMaxBid == $new_ss_bid;
    }
    ok($found, 'found copied keyword');

    # clean up
    ok( $ysm_ws->deleteKeyword( keywordID => $found ), 'delete copied keyword' );
}

sub test_can_add_keyword : Test(8) {
    my ( $self ) = @_;

    my $added_keyword = $self->create_keyword;

    ok(   $added_keyword, 'something was returned' );
    like( $added_keyword->text, qr/^test keyword text \d+$/, 'text looks right' );
    like( $added_keyword->ID, qr/^[\d]+$/, 'ID is numeric' );
    is(   $added_keyword->watchON, 'true', 'watchON is true' );
    is(   $added_keyword->advancedMatchON, 'true', 'advancedMatchON is true' );
    is(   $added_keyword->sponsoredSearchMaxBid, '100.0', 'sponsoredSearchMaxBid is set correctly' );
    like( $added_keyword->editorialStatus, qr/^Pending|Approved|Rejected|Suspended$/, 'editorialStatus seems right' );

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );
    ok( $ysm_ws->deleteKeyword( keywordID => $added_keyword->ID ), 'delete new keyword' );
}

sub test_can_add_utf8_keyword : Test(10) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );
    my $word = 'ゲーム プレステ';

    my $utf8_keyword = Yahoo::Marketing::Keyword->new
                                                ->adGroupID( $self->common_test_data( 'test_ad_group' )->ID )
                                                ->text( $word.$$ )
                                                ->alternateText( "$word alternate text ".$$ )
                                                ->sponsoredSearchMaxBid( 1 )
                                                ->status( 'On' )
                                                ->watchON( 'true' )
                                                ->advancedMatchON( 'true' )
                                                ->url( 'http://www.yahoo.com/utf8keyword?id='.$$ )
                       ;

    my $keyword = $ysm_ws->addKeyword( keyword => $utf8_keyword )->keyword;

    ok(   $keyword, 'something was returned' );
    like( $keyword->text, qr/$word\d+$/, 'text looks right' );
    like( $keyword->alternateText, qr/$word alternate text \d+$/, 'alternate text looks right' );
    is(   $keyword->url, 'http://www.yahoo.com/utf8keyword?id='.$$, 'url is right' );
    like( $keyword->ID, qr/^[\d]+$/, 'ID is numeric' );
    is(   $keyword->watchON, 'true', 'watchON is true' );
    is(   $keyword->advancedMatchON, 'true', 'advancedMatchON is true' );
    is(   $keyword->sponsoredSearchMaxBid, '1.0', 'sponsoredSearchMaxBid is set correctly' );
    like( $keyword->editorialStatus, qr/^Pending|Approved|Rejected|Suspended$/, 'editorialStatus seems right' );

    ok( $ysm_ws->deleteKeyword( keywordID => $keyword->ID ), 'delete new keyword' );
}


sub test_can_add_keywords : Test(22) {
    my ( $self ) = @_;

    my @added_keywords = $self->create_keywords;

    foreach my $added_keyword ( @added_keywords ){

        ok(   $added_keyword, 'something was returned' );
        like( $added_keyword->text, qr/^test keyword text \d+$/, 'text looks right' );
        like( $added_keyword->ID, qr/^[\d]+$/, 'ID is numeric' );
        is(   $added_keyword->watchON, 'true', 'watchON is true' );
        is(   $added_keyword->advancedMatchON, 'true', 'advancedMatchON is true' );
        is(   $added_keyword->sponsoredSearchMaxBid, '100.0', 'sponsoredSearchMaxBid is set correctly' );
        like( $added_keyword->editorialStatus, qr/^Pending|Approved|Rejected|Suspended$/, 'editorialStatus seems right' );
    }

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );
    ok( $ysm_ws->deleteKeywords( keywordIDs => [ map { $_->ID } @added_keywords ] ), 'delete new keywords' );
}


sub test_can_delete_keyword : Test(3) {
    my ( $self ) = @_;

    my $added_keyword = $self->create_keyword;

    ok( $added_keyword, 'something was returned' );

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );
    my $response = $ysm_ws->deleteKeyword( keywordID => $added_keyword->ID );

    is( $response->operationSucceeded, 'true' );

    is( $ysm_ws->getKeyword( keywordID => $added_keyword->ID )->status, 'Deleted', 'status is Deleted');
}


sub test_can_delete_keywords : Test(10) {
    my ( $self ) = @_;

    my @added_keywords = $self->create_keywords;

    ok( @added_keywords );

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );
    my @responses = $ysm_ws->deleteKeywords( keywordIDs => [ map { $_->ID } @added_keywords ] );

    foreach my $response ( @responses ){
        is( $response->operationSucceeded, 'true' );
    }

    for my $keyword ( $ysm_ws->getKeywords( keywordIDs => [ map { $_->ID } @added_keywords ] ) ) {
        ok( $keyword );
        is( $keyword->status, 'Deleted', 'status is Deleted' );
    }
}


sub test_can_get_keyword : Test(7) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );

    my $fetched_keyword = $ysm_ws->getKeyword( keywordID => $self->common_test_data( 'test_keyword' )->ID );

    ok(   $fetched_keyword, 'something was returned' );
    like( $fetched_keyword->text, qr/^test keyword text \d+$/, 'text looks right' );
    like( $fetched_keyword->ID, qr/^[\d]+$/, 'ID is numeric' );
    is(   $fetched_keyword->watchON, 'true', 'watchON is true' );
    is(   $fetched_keyword->advancedMatchON, 'true', 'advancedMatchON is true' );
    is(   $fetched_keyword->sponsoredSearchMaxBid, '100.0', 'sponsoredSearchMaxBid is set correctly' );
    like( $fetched_keyword->editorialStatus, qr/^Pending|Approved|Rejected|Suspended$/, 'editorialStatus seems right' );
}

sub test_can_get_keywords : Test(21) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );

    my @fetched_keywords = $ysm_ws->getKeywords( keywordIDs => [ map { $_->ID } @{ $self->common_test_data( 'test_keywords' ) } ] );

    foreach my $fetched_keyword ( @fetched_keywords ){

        ok(   $fetched_keyword, 'something was returned' );
        like( $fetched_keyword->text, qr/^test keyword text \d+$/, 'text looks right' );
        like( $fetched_keyword->ID, qr/^[\d]+$/, 'ID is numeric' );
        is(   $fetched_keyword->watchON, 'true', 'watchON is true' );
        is(   $fetched_keyword->advancedMatchON, 'true', 'advancedMatchON is true' );
        is(   $fetched_keyword->sponsoredSearchMaxBid, '100.0', 'sponsoredSearchMaxBid is set correctly' );
        like( $fetched_keyword->editorialStatus, qr/^Pending|Approved|Rejected|Suspended$/, 'editorialStatus seems right' );
    }
}

sub test_can_get_keywords_by_account_id : Test(35) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );

    my @fetched_keywords = $ysm_ws->getKeywordsByAccountID(
                                        accountID      => $ysm_ws->account,
                                        includeDeleted => 'false',
                                        startElement   => 0,
                                        numElements    => 1000,
                                    );

    foreach my $fetched_keyword ( @fetched_keywords ){
        next unless $fetched_keyword->status eq 'On' and $fetched_keyword->editorialStatus eq 'Approved';
        ok(   $fetched_keyword, 'something was returned' );
        like( $fetched_keyword->text, qr/^test keyword text \d+$/, 'text looks right' );
        like( $fetched_keyword->ID, qr/^[\d]+$/, 'ID is numeric' );
        is(   $fetched_keyword->watchON, 'true', 'watchON is true' );
        is(   $fetched_keyword->advancedMatchON, 'true', 'advancedMatchON is true' );
        is(   $fetched_keyword->sponsoredSearchMaxBid, '100.0', 'sponsoredSearchMaxBid is set correctly' );
        is(   $fetched_keyword->editorialStatus, 'Approved', 'editorialStatus is approved' );
    }
}


sub test_can_get_keywords_by_ad_group_id : Test(35) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );

    my @fetched_keywords = $ysm_ws->getKeywordsByAdGroupID(
                                        adGroupID      => $self->common_test_data( 'test_ad_group' )->ID,
                                        includeDeleted => 'false',
                                        startElement   => 0,
                                        numElements    => 1000,
                                    );

    foreach my $fetched_keyword ( @fetched_keywords ){

        next unless $fetched_keyword->status eq 'On';
        ok(   $fetched_keyword, 'something was returned' );
        like( $fetched_keyword->text, qr/^test keyword text \d+$/, 'text looks right' );
        like( $fetched_keyword->ID, qr/^[\d]+$/, 'ID is numeric' );
        is(   $fetched_keyword->watchON, 'true', 'watchON is true' );
        is(   $fetched_keyword->advancedMatchON, 'true', 'advancedMatchON is true' );
        is(   $fetched_keyword->sponsoredSearchMaxBid, '100.0', 'sponsoredSearchMaxBid is set correctly' );
        like( $fetched_keyword->editorialStatus, qr/^Pending|Approved|Rejected|Suspended$/, 'editorialStatus seems right' );
    }
}


sub test_can_get_keywords_by_ad_group_id_by_editorial_status : Test(35) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );

    my @fetched_keywords = $ysm_ws->getKeywordsByAdGroupIDByEditorialStatus(
                                        adGroupID       => $self->common_test_data( 'test_ad_group' )->ID,
                                        update          => 'false',
                                        status          => 'Approved',
                                        includeDeleted  => 'false',
                                    );
    push @fetched_keywords, $ysm_ws->getKeywordsByAdGroupIDByEditorialStatus(
                                         adGroupID       => $self->common_test_data( 'test_ad_group' )->ID,
                                         update          => 'false',
                                         status          => 'Pending',
                                         includeDeleted  => 'false',
                                    );

    foreach my $fetched_keyword ( @fetched_keywords ){
        next unless $fetched_keyword->status eq 'On';
        ok(   $fetched_keyword, 'something was returned' );
        like( $fetched_keyword->text, qr/^test keyword text \d+$/, 'text looks right' );
        like( $fetched_keyword->ID, qr/^[\d]+$/, 'ID is numeric' );
        is(   $fetched_keyword->watchON, 'true', 'watchON is true' );
        is(   $fetched_keyword->advancedMatchON, 'true', 'advancedMatchON is true' );
        is(   $fetched_keyword->sponsoredSearchMaxBid, '100.0', 'sponsoredSearchMaxBid is set correctly' );
        like( $fetched_keyword->editorialStatus, qr/^Pending|Approved$/, 'editorialStatus seems right' );
    }
}


sub test_can_get_keywords_by_ad_group_id_by_status : Test(35) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );

    my @fetched_keywords = $ysm_ws->getKeywordsByAdGroupIDByStatus(
                                        adGroupID       => $self->common_test_data( 'test_ad_group' )->ID,
                                        status          => 'On',
                                        startElement    => 0,
                                        numElements     => 1000,
                                    );

    foreach my $fetched_keyword ( @fetched_keywords ){

        ok(   $fetched_keyword, 'something was returned' );
        like( $fetched_keyword->text, qr/^test keyword text \d+$/, 'text looks right' );
        like( $fetched_keyword->ID, qr/^[\d]+$/, 'ID is numeric' );
        is(   $fetched_keyword->watchON, 'true', 'watchON is true' );
        is(   $fetched_keyword->advancedMatchON, 'true', 'advancedMatchON is true' );
        is(   $fetched_keyword->sponsoredSearchMaxBid, '100.0', 'sponsoredSearchMaxBid is set correctly' );
        like( $fetched_keyword->editorialStatus, qr/^Pending|Approved|Rejected|Suspended$/, 'editorialStatus seems right' );
    }
}

sub test_can_get_keyword_sponsored_search_max_bid : Test(1) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );
    is( $ysm_ws->getKeywordSponsoredSearchMaxBid( keywordID => $self->common_test_data( 'test_keyword' )->ID ), '100.0' );
}


sub test_can_get_and_set_optimization_guidelines_for_keyword : Test(2) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );

    my $keyword_optimization_guidelines = Yahoo::Marketing::KeywordOptimizationGuidelines->new
                                              ->accountID( $ysm_ws->account )
                                              ->adGroupID( $self->common_test_data( 'test_ad_group' )->ID )
                                              ->keywordID( $self->common_test_data( 'test_keyword' )->ID )
                                              ->sponsoredSearchMaxBid( 9.99 )
    ;

    my $response = $ysm_ws->setOptimizationGuidelinesForKeyword( 
                       optimizationGuidelines => $keyword_optimization_guidelines 
                   );

    is( $response->operationSucceeded, 'true' );

    is( $response->keywordOptimizationGuidelines->sponsoredSearchMaxBid, '9.99' );
}


sub test_can_get_update_for_keyword : Test(3) {
    my ( $self ) = @_;

    my $added_keyword = $self->create_keyword;

    ok( $added_keyword, 'something was returned' );

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );

    $ysm_ws->updateKeyword( keyword   => $added_keyword->alternateText('sex'),
                            updateAll => 'true',
                          );

    my $update_keyword = $ysm_ws->getUpdateForKeyword( keywordID => $added_keyword->ID );

    is( $update_keyword->alternateText, 'sex', 'getting pending alternateText right' );

    ok( $ysm_ws->deleteKeyword( keywordID => $added_keyword->ID ), 'delete new keyword' );
}

sub test_can_get_editorial_reasons_for_keyword : Test(7) {
    my ( $self ) = @_;

    my $added_keyword = $self->create_keyword;

    ok( $added_keyword, 'something was returned' );

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );

    my $new_keyword = $added_keyword->alternateText('drug oxycodone');

    my $response = $ysm_ws->updateKeyword(
        keyword => $new_keyword,
        updateAll => 'false',
    );
    ok( $response );

    return "update was not rejected" unless $response->errors;

    ok( $response->errors );
    like( $response->errors->[0]->message, qr/rejected/ );

    ok( $response->editorialReasons );

    my $editorial_reason = $ysm_ws->getEditorialReasonText(
        editorialReasonCode => $response->editorialReasons->alternateTextEditorialReasons->[0], # 39
        locale              => 'en_US',
    );
    ok( $editorial_reason );
    ok( $ysm_ws->deleteKeyword( keywordID => $added_keyword->ID ), 'delete new keyword' );
}

sub test_can_get_status_for_keyword : Test(2) {
    my ( $self ) = @_;

    my $added_keyword = $self->common_test_data( 'test_keyword' );

    ok( $added_keyword, 'something was returned' );

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );
    is( $ysm_ws->getStatusForKeyword( keywordID => $added_keyword->ID ), 'On' );
}

sub test_can_update_sponsored_search_max_bid_for_keyword : Test(2) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );

    $ysm_ws->updateSponsoredSearchMaxBidForKeyword(
        keywordID => $self->common_test_data( 'test_keyword' )->ID,
        maxBid    => 8.88,
    );
    is( $ysm_ws->getKeywordSponsoredSearchMaxBid( keywordID => $self->common_test_data( 'test_keyword' )->ID ), '8.88' );

    $ysm_ws->updateSponsoredSearchMaxBidForKeyword(
        keywordID => $self->common_test_data( 'test_keyword' )->ID,
        maxBid    => 1,
    );
    is( $ysm_ws->getKeywordSponsoredSearchMaxBid( keywordID => $self->common_test_data( 'test_keyword' )->ID ), '1.0' );
}

sub test_can_update_sponsored_search_max_bid_for_keywords : Test(6) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );

    $ysm_ws->updateSponsoredSearchMaxBidForKeywords(
        keywordIDs => [ map { $_->ID } @{$self->common_test_data( 'test_keywords' )} ],
        maxBids    => [ (8.88) x 3 ],
    );

    foreach my $id ( map { $_->ID } @{$self->common_test_data( 'test_keywords' )} ) {
        is( $ysm_ws->getKeywordSponsoredSearchMaxBid( keywordID => $id ), '8.88' );
    }

    $ysm_ws->updateSponsoredSearchMaxBidForKeywords(
        keywordIDs => [ map { $_->ID } @{$self->common_test_data( 'test_keywords' )} ],
        maxBids    => [(1) x 3],
    );
    foreach my $id ( map { $_->ID } @{$self->common_test_data( 'test_keywords' )} ) {
        is( $ysm_ws->getKeywordSponsoredSearchMaxBid( keywordID => $id ), '1.0' );
    }
}

sub test_can_update_keyword : Test(5) {
    my ( $self ) = @_;

    my $added_keyword = $self->create_keyword;
    my $old_alternate_text = $added_keyword->alternateText;
    my $old_url = $added_keyword->url;

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );
    my $response = $ysm_ws->updateKeyword( keyword   => $added_keyword->alternateText( 'apple' )
                                                                      ->url( 'http://www.somedomain.net' ),
                                           updateAll => 'true',
                                         );
    ok( $response );
    is( $response->operationSucceeded, 'true' );

    my $updated_keyword = $ysm_ws->getKeyword( keywordID => $added_keyword->ID );
    is( $updated_keyword->alternateText, 'apple' );
    is( $updated_keyword->url, 'http://www.somedomain.net' );

    ok( $ysm_ws->deleteKeyword( keywordID => $added_keyword->ID ), 'delete new keyword' );
}


sub test_can_update_keywords : Test(7) {
    my ( $self ) = @_;

    my @added_keywords = $self->create_keywords;
    foreach my $keyword ( @added_keywords ) {
        $keyword->alternateText( 'some new alternate text' );
        $keyword->url( 'http://www.somenewurl.net' );
    }

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );
    $ysm_ws->updateKeywords( keywords  => \@added_keywords,
                             updateAll => 'true',
                           );

    my @updated_keywords = $ysm_ws->getKeywords( keywordIDs => [ map { $_->ID } @added_keywords ] );
    foreach my $keyword ( @updated_keywords ) {
        is( $keyword->alternateText,  'some new alternate text' );
        is( $keyword->url, 'http://www.somenewurl.net' );
    }
    ok( $ysm_ws->deleteKeywords( keywordIDs => [ map { $_->ID } @added_keywords ] ) );
}

sub test_can_set_and_get_optimization_guidelines_for_keyword : Test(5) {
    my ( $self ) = @_;

    my $keyword  = $self->common_test_data( 'test_keyword' );
    my $ad_group = $self->common_test_data( 'test_ad_group' );

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );

    $ysm_ws->setOptimizationGuidelinesForKeyword( 
                 optimizationGuidelines 
                     => Yahoo::Marketing::KeywordOptimizationGuidelines->new
                                                                       ->keywordID( $keyword->ID )
                                                                       ->sponsoredSearchMaxBid( 2.23 )
             );

    my $optimization_guidelines = $ysm_ws->getOptimizationGuidelinesForKeyword( keywordID => $keyword->ID );

    ok( $optimization_guidelines, 'something was returned' );
    is( $optimization_guidelines->keywordID,              $keyword->ID,     'keyword ID is correct' );
    is( $optimization_guidelines->adGroupID,              $ad_group->ID,    'ad group ID is correct' );
    is( $optimization_guidelines->accountID,              $ysm_ws->account, 'account ID is correct' );
    is( $optimization_guidelines->sponsoredSearchMaxBid , 2.23,             'bid is correct' );

}

sub test_can_update_status_for_keyword : Test(2) {
    my ( $self ) = @_;

    my $added_keyword = $self->common_test_data( 'test_keyword' );
    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );

    $ysm_ws->updateStatusForKeyword(
        keywordID => $added_keyword->ID,
        status    => 'Off',
    );
    is( $ysm_ws->getKeyword( keywordID => $added_keyword->ID )->status, 'Off' );

    $ysm_ws->updateStatusForKeyword(
        keywordID => $added_keyword->ID,
        status    => 'On',
    );
    is( $ysm_ws->getKeyword( keywordID => $added_keyword->ID )->status, 'On' );
}


sub test_can_update_status_for_keywords : Test(6) {
    my ( $self ) = @_;

    my @added_keywords = @{$self->common_test_data( 'test_keywords' )};
    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );

    $ysm_ws->updateStatusForKeywords(
        keywordIDs => [ map { $_->ID } @added_keywords ],
        status     => 'Off',
    );
    for my $keyword ( $ysm_ws->getKeywords( keywordIDs => [ map { $_->ID } @added_keywords ] ) ) {
        is( $keyword->status, 'Off' );
    }
    $ysm_ws->updateStatusForKeywords(
        keywordIDs => [ map { $_->ID } @added_keywords ],
        status     => 'On',
    );
    for my $keyword ( $ysm_ws->getKeywords( keywordIDs => [ map { $_->ID } @added_keywords ] ) ) {
        is( $keyword->status, 'On' );
    }
}

1;


__END__

* getKeywordsByAdGroupByParticipatesInMarketplace
* getKeywordsByAdGroupBySponsoredSearchBidStatus
* getReasonsForKeywordNotParticipatingInMarketplace
* getSponsoredSearchMinBidForKeywordOptimizationGuidelines
* getSponsoredSearchMinBidForKeywordString
* getSponsoredSearchMinBidForKeywordStrings

