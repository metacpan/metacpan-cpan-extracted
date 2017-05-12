package Yahoo::Marketing::Test::GeographicalDictionaryService;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Test::Class Yahoo::Marketing::Test::PostTest /;
use Test::More;

use Yahoo::Marketing::TargetingType;
use Yahoo::Marketing::GeographicalDictionaryService;
use Data::Dumper;

# use SOAP::Lite +trace => [qw/ debug method fault /];

sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}


sub test_geo_dictionary_service : Test(24) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::GeographicalDictionaryService->new->parse_config( section => $self->section );

    # test getGeoLocationsByString
    my @probilities = $ysm_ws->getGeoLocationsByString( geoString => 'california' );
    ok( @probilities, 'can call getGeoLocationsByString' );
    my $calif = $probilities[0];

    ok( $calif->probability, 'can get probability' );
    is( $calif->geoLocation->name, 'California', 'name matches' );
    is( $calif->geoLocation->placeType->value, 'State', 'type matches' );

    my $woeid = $calif->geoLocation->woeid; # 2347563

    # test getGeoLocationsByStrings
    my @probility_sets = $ysm_ws->getGeoLocationsByStrings( geoStrings => ['california'] );
    ok( @probility_sets, 'can call getGeoLocationsByStrings' );
    my $probility = $probility_sets[0];
    is( $probility->geoString, 'california', 'geoString matches' );
    is( $probility->geoLocationProbabilities->[0]->geoLocation->woeid, '2347563', 'ID matches' );

    # test getAncestorGeoLocations
    my @values = $ysm_ws->getAncestorGeoLocations( geoLocationWOEID => $woeid );
    ok( @values, 'can call getAncestorGeoLocations' );
    is( $values[0]->name, 'United States', 'name matches' );
    is( $values[0]->placeType->value, 'Country', 'type matches' );

    my $us_woeid = $values[0]->woeid; # 23424977

    # test getGeoLocation
    my $value = $ysm_ws->getGeoLocation( geoTargetWOEID => $woeid );
    ok( $value, 'can call getGeoLocation' );
    is( $value->woeid, '2347563', 'ID matches' );

    # test getGeoLocations
    @values = $ysm_ws->getGeoLocations( geoTargetWOEIDs => [$woeid] );
    ok( @values, 'can call getGeoLocations' );
    is( $values[0]->woeid, '2347563', 'ID matches' );

    # test getGeoLocationsByStringByCountry
    @probilities = $ysm_ws->getGeoLocationsByStringByCountry( geoString => 'california', countryWOEID => $us_woeid );
    ok( @probilities, 'can call getGeoLocationsByStringByCountry' );
    is( $probilities[0]->geoLocation->name, 'California', 'name matches' );

    # test getTargetableGeoLevels
    my @types = $ysm_ws->getTargetableGeoLevels();
    ok( @types, 'can call getTargetableGeoLevels' );
    like( $types[0]->value, qr/[MarketingArea|Country|State|City|Zip]/, 'type matches' );

    # test getGeoLocationsByParentByLevel
    @values = $ysm_ws->getGeoLocationsByParentByLevel( parentWOEID => $woeid, geoLevel => Yahoo::Marketing::TargetingType->new->value('MarketingArea'), startElement => 0, numElements => 5 );
    ok( @values, 'can call getGeoLocationsByParentByLevel' );
    like( $values[0]->description, qr/DMA/, 'description matches' );

    # test getTopLevelGeoLocations
    @values = $ysm_ws->getTopLevelGeoLocations();
    ok( @values, 'can call getTopLevelGeoLocations');
    is( $values[0]->placeType->value, 'Country', 'type matches' );

    # test getZipGeoLocationsWithinRadius
    @probilities = $ysm_ws->getGeoLocationsByString( geoString => 'burbank' );
    @values = $ysm_ws->getGeoLocationsByParentByLevel( parentWOEID => $probilities[0]->geoLocation->woeid, geoLevel => Yahoo::Marketing::TargetingType->new->value('Zip'), startElement => 0, numElements => 5 );
    @values = $ysm_ws->getZipGeoLocationsWithinRadius( radius => 200, distanceUnits => 'Miles', zipWOEID => $values[0]->woeid, startElement => 0, numElements => 5 );
    ok( @values, 'can call getZipGeoLocationsWithinRadius' );
    is( $values[0]->placeType->value, 'Zip', 'type matches' );

}


1;

