package Yahoo::Marketing::APT::Test::AdTagService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::AdTagService;
use Yahoo::Marketing::APT::AdTagParameters;
use Yahoo::Marketing::APT::TargetingDictionaryService;
use Yahoo::Marketing::APT::TargetingAttributeDescriptor;
use Data::Dumper;

# use SOAP::Lite +trace => [qw/ debug method fault /];


sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}

sub startup_test_ad_tag_service : Test(startup) {
    my ( $self ) = @_;

    $self->common_test_data( 'test_site', $self->create_site ) unless defined $self->common_test_data( 'test_site' );
}

sub shutdown_test_ad_tag_service : Test(shutdown) {
    my ( $self ) = @_;

    $self->cleanup_site;
}


sub test_get_ad_tag : Test(1) {
    my $self = shift;

    my $dic_ws = Yahoo::Marketing::APT::TargetingDictionaryService->new->parse_config( section => $self->section );
    my @ct_values = $dic_ws->getTargetingAttributes(
        targetingAttributeType => 'ContentTopic',
        startElement           => 0,
        numElements            => 10,
    );
    my @as_values = $dic_ws->getTargetingAttributes(
        targetingAttributeType => 'AdSize',
        startElement           => 0,
        numElements            => 10,
    );

    my $ysm_ws = Yahoo::Marketing::APT::AdTagService->new->parse_config( section => $self->section );

    my $site_id = $self->common_test_data( 'test_site' )->ID;

    my $ad_tag = $ysm_ws->getAdTag(
        adTagParameters => Yahoo::Marketing::APT::AdTagParameters->new
                                                                 ->siteID( $site_id )
                                                                 ->targetingAttributeDescriptors( [Yahoo::Marketing::APT::TargetingAttributeDescriptor->new->targetingAttributeID($ct_values[0]->ID)->targetingAttributeType('ContentTopic'), Yahoo::Marketing::APT::TargetingAttributeDescriptor->new->targetingAttributeID($as_values[0]->ID)->targetingAttributeType('AdSize')] ) );

    ok( $ad_tag, 'can get ad tag' );
}



sub test_get_supported_targeting_attribute_types : Test(1) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::AdTagService->new->parse_config( section => $self->section );

    my @types = $ysm_ws->getSupportedTargetingAttributeTypes();

    ok( @types, 'can get supported targeting attribute types' );
}


1;
