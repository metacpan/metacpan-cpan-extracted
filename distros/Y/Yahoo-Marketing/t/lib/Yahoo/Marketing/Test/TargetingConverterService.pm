package Yahoo::Marketing::Test::TargetingConverterService;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Test::Class Yahoo::Marketing::Test::PostTest /;
use Test::More;

use Yahoo::Marketing::AgeRange;
use Yahoo::Marketing::DayPartingTargeting;
use Yahoo::Marketing::DayPartingTarget;
use Yahoo::Marketing::DayPart;
use Yahoo::Marketing::GeoLocation;
use Yahoo::Marketing::TargetingConverterService;
use Data::Dumper;

# use SOAP::Lite +trace => [qw/ debug method fault /];

sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}


sub test_targeting_converter_service : Test(22) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::TargetingConverterService->new->parse_config( section => $self->section );

    # test getTargetingAttributeDescriptorByAgeRange
    my $descriptor = $ysm_ws->getTargetingAttributeDescriptorByAgeRange(
        ageRange => Yahoo::Marketing::AgeRange->new->minAge(18)->maxAge(20),
    );
    ok( $descriptor, 'can call getTargetingAttributeDescriptorByAgeRange' );
    is( $descriptor->targetingType->value, 'Age', 'targeting type matches' );

    # test getAgeRangeByTargetingAttributeDescriptor
    my $age_range = $ysm_ws->getAgeRangeByTargetingAttributeDescriptor(
        targetingAttributeDescriptor => $descriptor,
    );
    ok( $age_range, 'can call getAgeRangeByTargetingAttributeDescriptor' );
    is( $age_range->minAge, 18, 'min age matches' );
    is( $age_range->maxAge, 20, 'max age matches' );

    # test getTargetingAttributeDescriptorByDayPartingTargeting
    $descriptor = $ysm_ws->getTargetingAttributeDescriptorByDayPartingTargeting(
        dayPartingTargeting => Yahoo::Marketing::DayPartingTargeting->new->dayPartingTargets([Yahoo::Marketing::DayPartingTarget->new->dayPart(Yahoo::Marketing::DayPart->new->dayOfTheWeek('Monday')->endHourOfDay(17)->startHourOfDay(10))])->userTimeZone('true'),
    );
    ok( $descriptor, 'can call getTargetingAttributeDescriptorByDayPartingTargeting' );
    is( $descriptor->targetingType->value, 'DayParting', 'targeting type matches' );

    # test getDayPartingTargetingByTargetingAttributeDescriptor
    my $day_part = $ysm_ws->getDayPartingTargetingByTargetingAttributeDescriptor(
         targetingAttributeDescriptor => $descriptor,
     );
    ok( $day_part, 'can call getDayPartingTargetingByTargetingAttributeDescriptor' );
    is( $day_part->dayPartingTargets->[0]->dayPart->dayOfTheWeek, 'Monday', 'day of the week matches' );
    is( $day_part->userTimeZone, 'true', 'use time zone matches' );

    # test getTargetingAttributeDescriptorByGender
    $descriptor = $ysm_ws->getTargetingAttributeDescriptorByGender(
        gender => 'Female',
    );
    ok( $descriptor, 'can call getTargetingAttributeDescriptorByGender' );
    is( $descriptor->targetingType->value, 'Gender', 'targeting type matches' );

    # test getGenderByTargetingAttributeDescriptor
    my $gender = $ysm_ws->getGenderByTargetingAttributeDescriptor(
        targetingAttributeDescriptor => $descriptor,
    );
    ok( $gender, 'can call getGenderByTargetingAttributeDescriptor' );
    is( $gender, 'Female', 'gender matches' );

    # test getTargetingAttributeDescriptorByGeoLocation
    $descriptor = $ysm_ws->getTargetingAttributeDescriptorByGeoLocation(
        geoLocation => Yahoo::Marketing::GeoLocation->new->woeid(2347563),  # California
    );
    ok( $descriptor, 'can call getTargetingAttributeDescriptorByGeoLocation' );
    is( $descriptor->targetingType->value, 'State', 'targeting type matches' );

    # test getGeoLocationByTargetingAttributeDescriptor
    my $geo = $ysm_ws->getGeoLocationByTargetingAttributeDescriptor(
        targetingAttributeDescriptor => $descriptor,
    );
    ok( $geo, 'can call getGeoLocationByTargetingAttributeDescriptor' );
    is( $geo->woeid, '2347563', 'woeid matches' );

    # test getTargetingAttributeDescriptorByUnderAgeFilter
    $descriptor = $ysm_ws->getTargetingAttributeDescriptorByUnderAgeFilter(
        underAgeFilter => 'Enable',
    );
    ok( $descriptor, 'can call getTargetingAttributeDescriptorByUnderAgeFilter' );
    is( $descriptor->targetingType->value, 'UnderAgeFilter', 'targeting type matches' );

    # test getUnderAgeFilterByTargetingAttributeDescriptor
    my $under_age = $ysm_ws->getUnderAgeFilterByTargetingAttributeDescriptor(
        targetingAttributeDescriptor => $descriptor,
    );
    ok( $under_age, 'can call getUnderAgeFilterByTargetingAttributeDescriptor' );
    is( $under_age, 'Enable' );

}

1;


