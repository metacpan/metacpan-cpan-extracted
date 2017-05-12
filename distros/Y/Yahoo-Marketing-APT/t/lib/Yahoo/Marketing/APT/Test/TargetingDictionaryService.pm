package Yahoo::Marketing::APT::Test::TargetingDictionaryService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::TargetingDictionaryService;
use Yahoo::Marketing::APT::ContentTopic;
use Yahoo::Marketing::APT::TargetingAttributeDescriptor;
use Data::Dumper;

# use SOAP::Lite +trace => [qw/ debug method fault /];


sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}


sub test_can_get_content_topics_by_account_id : Test(1) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::TargetingDictionaryService->new->parse_config( section => $self->section );

    my @content_topics = $ysm_ws->getStandardContentTopics(
        startElement => 0,
        numElements  => 1000,
    );
    if ( @content_topics ) {
        ok( $content_topics[0]->ID, 'can get content topic ok');
    } else {
        ok(1); # not all accounts have content topcis
    }
}

sub test_can_get_supported_targeting_attribute_types : Test(1) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::TargetingDictionaryService->new->parse_config( section => $self->section );

    my @types = $ysm_ws->getSupportedTargetingAttributeTypes();
    ok(@types, 'can get supported targeting attribute types' );
}


sub test_can_get_targeting_attributes : Test(1) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::TargetingDictionaryService->new->parse_config( section => $self->section );

    my @targeting_attributes = $ysm_ws->getTargetingAttributes(
        targetingAttributeType => 'Browser',
        startElement => 0,
        numElements  => 1000,
    );
    ok( $targeting_attributes[0]->ID, 'can get targeting attribute ok');
}

sub test_can_get_targeting_attributes_by_value : Test(2) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::TargetingDictionaryService->new->parse_config( section => $self->section );

    my @values = $ysm_ws->getTargetingAttributesByValue(
        targetingAttributeType => 'Browser',
        value                  => 'Microsoft Internet Explorer 6.0',
    );

    ok(@values, 'can get targeting attributes by value' );
    is($values[0]->description, 'Microsoft Internet Explorer 6.0', 'value is correct' );
}


sub test_can_get_targeting_attributes_by_descriptors : Test(2) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::TargetingDictionaryService->new->parse_config( section => $self->section );

    my @targeting_attributes = $ysm_ws->getTargetingAttributes(
        targetingAttributeType => 'Browser',
        startElement => 0,
        numElements  => 1000,
    );

    my @values = $ysm_ws->getTargetingAttributesByDescriptors( descriptors => [Yahoo::Marketing::APT::TargetingAttributeDescriptor->new->targetingAttributeID( $targeting_attributes[0]->ID )->targetingAttributeType( 'Browser' )] );
    ok( @values );
    is( $values[0]->ID, $targeting_attributes[0]->ID );
}

1;
