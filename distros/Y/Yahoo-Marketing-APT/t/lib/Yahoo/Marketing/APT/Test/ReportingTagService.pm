package Yahoo::Marketing::APT::Test::ReportingTagService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::ReportingTagService;
use Yahoo::Marketing::APT::ReportingTag;
use Yahoo::Marketing::APT::ReportingTagResponse;
use Yahoo::Marketing::APT::BasicResponse;
use Data::Dumper;

# use SOAP::Lite +trace => [qw/ debug method fault /];


sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}

sub section {
    my ( $self ) = @_;
    return $self->SUPER::section().'_managed_publisher';
}

sub test_can_operate_reporting_tag : Test(9) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::ReportingTagService->new->parse_config( section => $self->section );

    # test addReportingTag
    my $reporting_tag = Yahoo::Marketing::APT::ReportingTag->new
                                                           ->name( "test_reporting_tag" )
                                                               ;
    my $response = $ysm_ws->addReportingTag( reportingTag => $reporting_tag );
    ok( $response, 'can call addReportingTag' );
    is( $response->operationSucceeded, 'true', 'add reporting tag successfully' );
    $reporting_tag = $response->reportingTag;

    # test getReportingTag
    my $fetched_reporting_tag = $ysm_ws->getReportingTag( reportingTagID => $reporting_tag->ID );
    ok( $fetched_reporting_tag, 'can call getReportingTag' );
    is( $fetched_reporting_tag->name, $reporting_tag->name, 'name matches' );

    # test updateReportingTag
    $reporting_tag->name( 'new_test_reporting_tag' );
    $response = $ysm_ws->updateReportingTag( reportingTag => $reporting_tag );
    ok( $response, 'can call updateReportingTag' );
    is( $response->operationSucceeded, 'true', 'update reporting tag successfully' );
    $reporting_tag = $response->reportingTag;
    is( $reporting_tag->name, 'new_test_reporting_tag', 'name matches' );

    # test deleteReportingTag
    $response = $ysm_ws->deleteReportingTag( reportingTagID => $reporting_tag->ID );
    ok( $response, 'can call deleteReportingTag' );
    is( $response->operationSucceeded, 'true', 'delete reporting tag successfully' );
}


sub test_can_operate_reporting_tags : Test(11) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::ReportingTagService->new->parse_config( section => $self->section );

    # test addReportingTags
    my $reporting_tags = [ Yahoo::Marketing::APT::ReportingTag->new
                                                              ->name( "test_reporting_tag" ) ];

    my @responses = $ysm_ws->addReportingTags( reportingTags => $reporting_tags );
    ok( @responses, 'can call addReportingTags' );
    is( $responses[0]->operationSucceeded, 'true', 'add reporting tags successfully' );
    $reporting_tags = [ map { $_->reportingTag } @responses ];

    # test getReportingTags
    my @fetched_reporting_tags = $ysm_ws->getReportingTags( reportingTagIDs => [ map { $_->ID } @$reporting_tags ] );
    ok( @fetched_reporting_tags, 'can call getReportingTags' );
    is( $fetched_reporting_tags[0]->name, $reporting_tags->[0]->name, 'name matches' );

    # test updateReportingTags
    $reporting_tags->[0]->name( 'new_test_reporting_tag' );
    @responses = $ysm_ws->updateReportingTags( reportingTags => $reporting_tags );
    ok( @responses, 'can call updateReportingTags' );
    is( $responses[0]->operationSucceeded, 'true', 'update reporting tags successfully' );
    $reporting_tags = [ map { $_->reportingTag } @responses ];
    is( $reporting_tags->[0]->name, 'new_test_reporting_tag', 'name matches' );

    # test getReportingTagsByAccountID
    @fetched_reporting_tags = $ysm_ws->getReportingTagsByAccountID();
    ok( @fetched_reporting_tags, 'can call getReportingTagsByAccountID' );
    ok( $fetched_reporting_tags[0]->ID, 'can get ID from results' );

    # test deleteReportingTags
    @responses = $ysm_ws->deleteReportingTags( reportingTagIDs => [ map { $_->ID } @$reporting_tags ] );
    ok( @responses, 'can call deleteReportingTags' );
    is( $responses[0]->operationSucceeded, 'true', 'delete reporting tags successfully' );
}



1;

