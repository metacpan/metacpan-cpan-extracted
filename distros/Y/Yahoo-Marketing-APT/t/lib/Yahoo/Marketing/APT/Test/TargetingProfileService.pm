package Yahoo::Marketing::APT::Test::TargetingProfileService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::TargetingProfileService;
use Yahoo::Marketing::APT::TargetingProfile;
use Yahoo::Marketing::APT::TargetingProfileResponse;
use Yahoo::Marketing::APT::BasicResponse;
use Yahoo::Marketing::APT::DayPartingTargeting;
use Yahoo::Marketing::APT::TargetingAttribute;
use Yahoo::Marketing::APT::TimeRange;
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
    return $self->SUPER::section().'_managed_advertiser';
}

sub test_operate_targeting_profile : Test(5) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::TargetingProfileService->new->parse_config( section => $self->section );

    # test getSupportedTargetingAttributeTypes
    my @types = $ysm_ws->getSupportedTargetingAttributeTypes();
    ok( @types, 'can call getSupportedTargetingAttributeTypes');

    # test addTargetingProfile
    my $day_parting_targeting = Yahoo::Marketing::APT::DayPartingTargeting->new
                                                                          ->dayOfTheWeek( 'Friday' )
                                                                          ->timeRange( Yahoo::Marketing::APT::TimeRange->new->endTime( 20 )->startTime( 18 ) );
    my $targeting_profile = Yahoo::Marketing::APT::TargetingProfile->new
                                                                   ->targetingAttributes( [ Yahoo::Marketing::APT::TargetingAttribute->new->dayPartingTargeting( $day_parting_targeting ) ] );
    my $response = $ysm_ws->addTargetingProfile( targetingProfile => $targeting_profile );
    ok( $response );
    is( $response->operationSucceeded, 'true' );
    $targeting_profile = $response->targetingProfile;

    # test getTargetingProfile
    my $got_targeting_profile = $ysm_ws->getTargetingProfile( targetingProfileID => $targeting_profile->ID );
    ok($got_targeting_profile);
    is( $got_targeting_profile->ID, $targeting_profile->ID );


}




1;
