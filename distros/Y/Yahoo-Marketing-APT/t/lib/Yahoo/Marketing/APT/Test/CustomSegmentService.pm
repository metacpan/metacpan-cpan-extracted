package Yahoo::Marketing::APT::Test::CustomSegmentService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::CustomSegmentService;
use Yahoo::Marketing::APT::CustomSegment;
use Yahoo::Marketing::APT::Visit;

use Data::Dumper;

# use SOAP::Lite +trace => [qw/ debug method fault /];


sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}


sub test_operate_custom_segment : Test(12) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::CustomSegmentService->new->parse_config( section => $self->section );

    my $visit = Yahoo::Marketing::APT::Visit->new
                                            ->publisherAccountIDs( [$ysm_ws->account] )
                                                ;
    my $segment = Yahoo::Marketing::APT::CustomSegment->new
                                                      ->description( 'test description' )
                                                      ->name( 'test segment' )
                                                      ->visitDefinition( $visit )
                                                      ->visitFrequency( 2 )
                                                          ;
    # test addCustomSegment
    my $response = $ysm_ws->addCustomSegment( customSegment => $segment );
    ok( $response, 'can call addCustomSegment' );
    $segment = $response->customSegment;
    is( $segment->name, 'test segment', 'name matches' );

    # test updateCustomSegment
    $segment->name( 'new segment' );
    $response = $ysm_ws->updateCustomSegment( customSegment => $segment );
    ok( $response, 'can call updateCustomSegment' );
    is( $response->operationSucceeded, 'true', 'custom segment updated' );
    $segment = $response->customSegment;
    is( $segment->name, 'new segment', 'name matches' );

    # test activateCustomSegment
    $response = $ysm_ws->activateCustomSegment( customSegmentID => $segment->ID );
    ok( $response, 'can call activateCustomSegment' );

    # test getCustomSegment
    $segment = $ysm_ws->getCustomSegment( customSegmentID => $segment->ID );
    ok( $segment, 'can call getCustomSegment' );
    is( $segment->description, 'test description', 'description matches' );
    is( $segment->status, 'Active', 'custom segment activated' );

    # test deactivateCustomSegment
    $response = $ysm_ws->deactivateCustomSegment( customSegmentID => $segment->ID );
    ok( $response, 'can call deactivateCustomSegment' );

    # test deleteCustomSegment
    $response = $ysm_ws->deleteCustomSegment( customSegmentID => $segment->ID );
    ok( $response, 'can call deleteCustomSegment' );
    is( $response->operationSucceeded, 'true', 'custom segment deleted' );

}


sub test_operate_custom_segments : Test(13) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::CustomSegmentService->new->parse_config( section => $self->section );

    my $visit = Yahoo::Marketing::APT::Visit->new
                                            ->publisherAccountIDs( [$ysm_ws->account] )
                                                ;
    my $segment = Yahoo::Marketing::APT::CustomSegment->new
                                                      ->description( 'test description' )
                                                      ->name( 'test segment' )
                                                      ->visitDefinition( $visit )
                                                      ->visitFrequency( 2 )
                                                          ;
    # test addCustomSegments
    my @responses = $ysm_ws->addCustomSegments( customSegments => [$segment] );
    ok( @responses, 'can call addCustomSegments' );
    $segment = $responses[0]->customSegment;
    is( $segment->name, 'test segment', 'name matches' );

    # test updateCustomSegments
    $segment->name( 'new segment' );
    @responses = $ysm_ws->updateCustomSegments( customSegments => [$segment] );
    ok( @responses, 'can call updateCustomSegments' );
    is( $responses[0]->operationSucceeded, 'true', 'custom segments updated' );
    $segment = $responses[0]->customSegment;
    is( $segment->name, 'new segment', 'name matches' );

    # test activateCustomSegments
    @responses = $ysm_ws->activateCustomSegments( customSegmentIDs => [$segment->ID] );
    ok( @responses, 'can call activateCustomSegments' );

    # test getCustomSegments
    my @segments = $ysm_ws->getCustomSegments( customSegmentIDs => [$segment->ID] );
    ok( @segments, 'can call getCustomSegments' );
    is( $segments[0]->description, 'test description', 'description matches' );
    is( $segments[0]->status, 'Active', 'custom segment activated' );

    # test deactivateCustomSegments
    @responses = $ysm_ws->deactivateCustomSegments( customSegmentIDs => [$segment->ID] );
    ok( @responses, 'can call deactivateCustomSegments' );

    # test getCustomSegmentsByAccountID
    @segments = $ysm_ws->getCustomSegmentsByAccountID();
    ok( @segments, 'can call getCustomSegmentsByAccountID' );

    # test deleteCustomSegments
    @responses = $ysm_ws->deleteCustomSegments( customSegmentIDs => [$segment->ID] );
    ok( @responses, 'can call deleteCustomSegments' );
    is( $responses[0]->operationSucceeded, 'true', 'custom segments deleted' );

}


1;
