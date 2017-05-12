package Yahoo::Marketing::APT::Test::GeographicalTargetingService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::GeographicalTargetingService;
use Yahoo::Marketing::APT::Region;
use Yahoo::Marketing::APT::RegionLevel;
use Yahoo::Marketing::APT::RegionProbability;
use Data::Dumper;

# use SOAP::Lite +trace => [qw/ debug method fault /];


sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}


sub test_can_get_countries : Test(2) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::GeographicalTargetingService->new->parse_config( section => $self->section );

    my @regions = $ysm_ws->getCountries();

    ok( @regions );
    ok( $regions[0]->name );
}


sub test_can_get_region : Test(2) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::GeographicalTargetingService->new->parse_config( section => $self->section );

    my $region = $ysm_ws->getRegion(
        WOEID => '24700957',
    );

    ok( $region );
    is( $region->name, 'DMA Anchorage', 'can get region' );
}

sub test_can_get_region_levels_country : Test(4) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::GeographicalTargetingService->new->parse_config( section => $self->section );

    my @regions = $ysm_ws->getRegionLevelsForCountry(
        countryWOEID => '23424977',
    );

    ok( @regions );
    ok( $regions[0]->name, 'can get region level 0' );
    ok( $regions[1]->name, 'can get region level 1' );
    ok( $regions[2]->name, 'can get region level 2' );

}

sub test_can_get_regions : Test(3) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::GeographicalTargetingService->new->parse_config( section => $self->section );

    my @regions = $ysm_ws->getRegions(
        WOEIDs => ['24700957', '23424977'],
    );

    ok( @regions );
    is( $regions[0]->WOEID, '24700957', 'can get region 1' );
    is( $regions[1]->WOEID, '23424977', 'can get region 2' );

}


sub test_can_get_regions_by_level_within_radius : Test(2) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::GeographicalTargetingService->new->parse_config( section => $self->section );

    my @regions = $ysm_ws->getRegionsByLevelWithinRadius(
        radius => 200,
        distanceUnits => 'Miles',
        regionWOEID => '24700957',
        level => 2,
        startElement => 0,
        numElements => 5,
    );

    ok( @regions );
    is( $regions[0]->WOEID, '2347560', 'can get region 1' );

}

sub test_can_get_regions_by_parent_by_level : Test(2) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::GeographicalTargetingService->new->parse_config( section => $self->section );

    my @regions = $ysm_ws->getRegionsByParentByLevel(
        parentWOEIDs => ['23424977'],
        level => 2,
        startElement => 0,
        numElements => 5,
    );

    ok( @regions );
    is( $regions[0]->level, '2', 'can get region 1' );

}

sub test_can_get_regions_by_string : Test(2) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::GeographicalTargetingService->new->parse_config( section => $self->section );

    my @region_probabilities = $ysm_ws->getRegionsByString(
        regionName => 'United States',
    );

    ok( @region_probabilities );
    is( $region_probabilities[0]->region->name, 'United States', 'can get region probabilities' );
}


sub test_can_get_regions_by_string_by_country : Test(2) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::GeographicalTargetingService->new->parse_config( section => $self->section );

    my @region_probabilities = $ysm_ws->getRegionsByStringByCountry(
        regionName => 'DMA Anchorage',
        countryWOEID => '23424977',
    );

    ok( @region_probabilities );
    is( $region_probabilities[0]->region->name, 'DMA Anchorage', 'can get region probabilities' );
}


1;


