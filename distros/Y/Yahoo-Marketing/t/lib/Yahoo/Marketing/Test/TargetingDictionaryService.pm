package Yahoo::Marketing::Test::TargetingDictionaryService;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Test::Class Yahoo::Marketing::Test::PostTest /;
use Test::More;

use Yahoo::Marketing::TargetingDictionaryService;
use Data::Dumper;

# use SOAP::Lite +trace => [qw/ debug method fault /];

sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}


sub test_targeting_dictionary_service : Test(6) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::TargetingDictionaryService->new->parse_config( section => $self->section );
    my $find = 0;

    # test getAdGroupSupportedTargetingTypesByTacticType
    my @types = $ysm_ws->getAdGroupSupportedTargetingTypesByTacticType(
        tacticType => 'SponsoredSearch',
    );
    ok( @types, 'can call getAdGroupSupportedTargetingTypesByTacticType' );
    foreach my $type (@types) {
        $find = 1 if $type->value eq 'MarketingArea';
    }
    is( $find, 1, 'can get targeting type' );

    # test getAgeRanges
    my @ranges = $ysm_ws->getAgeRanges();
    ok( @ranges, 'can call getAgeRanges' );
    $find = 0;
    foreach my $range (@ranges) {
        $find = 1 if ($range->minAge == 18 and $range->maxAge == 20);
    }
    is( $find, 1, 'can get age ranges' );

    # test getCampaignSupportedTargetingTypesByTacticType
    @types = $ysm_ws->getCampaignSupportedTargetingTypesByTacticType(
        tacticType => 'SponsoredSearch',
    );
    ok( @types, 'can call getCampaignSupportedTargetingTypesByTacticType' );
    $find = 0;
    foreach my $type (@types) {
        $find = 1 if $type->value eq 'MarketingArea';
    }
    is( $find, 1, 'can get targeting type' );

}




1;

