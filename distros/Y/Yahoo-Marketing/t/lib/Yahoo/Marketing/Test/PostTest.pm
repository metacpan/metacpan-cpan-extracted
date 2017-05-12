package Yahoo::Marketing::Test::PostTest;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;

use Carp qw/croak confess/;
use Test::More;
use Module::Build;
use Yahoo::Marketing::Campaign;
use Yahoo::Marketing::AdGroup;
use Yahoo::Marketing::Ad;
use Yahoo::Marketing::Keyword;
use Yahoo::Marketing::AdService;
use Yahoo::Marketing::CampaignService;
use Yahoo::Marketing::AccountService;
use Yahoo::Marketing::AdGroupService;
use Yahoo::Marketing::KeywordService;

use Data::Dumper;

our %common_test_data;

sub section {
    my $build; eval { $build = Module::Build->current; };
    return if $@;   # guess we don't have a $build

    return $build->notes('config_section');
}

sub startup_post_test_diag_settings : Test(startup) {
    my ( $self ) = @_;

    my $build; eval { $build = Module::Build->current; };
    return if $@;   # guess we don't have a $build

    my $debug_level = $build->notes('SOAP_debug_level');

    if( $debug_level ){

        my $service = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

        if( $debug_level ){
            eval "use SOAP::Lite +trace => [qw/ fault /];";

            local $| = 1;
            diag(<<EODIAG);
Running post tests with the following settings:
    config section: @{[ $self->section ]}
    version:        @{[ $service->version ]}
    endpoint:       @{[ $service->endpoint]} 
    username:       @{[ $service->username]} 
    master account: @{[ $service->master_account]} 
    account:        @{[ $service->account]} 
EODIAG
        }


        # add even more SOAP::Lite debugging if debug level > 1
        if( $debug_level > 1 ){
            eval "use SOAP::Lite +trace => [qw/ debug method fault /];";
        }

        # now set it to 0 so we don't print the above diag again
        $build->notes(SOAP_debug_level => 0);
    }
}


sub common_test_data {
    my ( $self, $key, $value ) = @_;

    die "common_test_data_value needs a key" unless defined $key;

    if( @_ > 2 ){  # we have a value
        $common_test_data{ $key } = $value;
        return $self;
    }

    return $common_test_data{ $key };
}


sub cleanup_all {
    my $self = shift;

    $self->cleanup_campaign;
    $self->cleanup_campaigns;
    $self->cleanup_ad_group;
    $self->cleanup_ad_groups;
    $self->cleanup_ad;
    $self->cleanup_keyword;
    $self->cleanup_keywords;
}

sub cleanup_keyword {
    my $self = shift;

    if( my $keyword = $self->common_test_data( 'test_keyword' ) ){
        my $keyword_service = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );
        $keyword_service->deleteKeyword( keywordID => $keyword->ID );
    }
    $self->common_test_data( 'test_keyword', undef );
    return;
}

sub cleanup_keywords {
    my $self = shift;

    if ($self->common_test_data( 'test_keywords' ) ){

        my $keyword_service = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );
        $keyword_service->deleteKeywords( keywordIDs => [ map { $_->ID } @{ $self->common_test_data( 'test_keywords' ) } ] );
    }
    $self->common_test_data( 'test_keywords', undef );
    return;
}

sub cleanup_ad {
    my $self = shift;

    if( my $ad = $self->common_test_data( 'test_ad' ) ){
        my $ad_service = Yahoo::Marketing::AdService->new->parse_config( section => $self->section );
        $ad_service->deleteAd( adID => $ad->ID );
    }
    $self->common_test_data( 'test_ad', undef );
    return;
}

sub cleanup_ads {
    my $self = shift;

    if ($self->common_test_data( 'test_ads' ) ){

        my $ad_service = Yahoo::Marketing::AdService->new->parse_config( section => $self->section );
        $ad_service->deleteAds( adIDs => [ map { $_->ID } @{ $self->common_test_data( 'test_ads' ) } ] );
    }
    $self->common_test_data( 'test_ads', undef );
    return;
}

sub cleanup_ad_group {
    my ( $self, $ad_group ) = @_;

    unless( $ad_group ){
        $ad_group = $self->common_test_data( 'test_ad_group' );
        $self->common_test_data( 'test_ad_group', undef );
    }
    
    if( $ad_group ){
        my $ad_group_service = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );
        $ad_group_service->deleteAdGroup( adGroupID => $ad_group->ID );
    }
    return;
}

sub cleanup_ad_groups {
    my $self = shift;

    if ($self->common_test_data( 'test_ad_groups' ) ){
        my $ad_group_service = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );

        $ad_group_service->deleteAdGroups( adGroupIDs => [ map { $_->ID } @{ $self->common_test_data( 'test_ad_groups' ) } ] );
    }
    $self->common_test_data( 'test_ad_groups', undef );
    return;
}

sub cleanup_all_ad_groups_in_test_campaign {
    my $self = shift;

    if ( my $campaign = $self->common_test_data( 'test_campaign' ) ) {
        my $ad_group_service = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );
        my @ad_groups = $ad_group_service->getAdGroupsByCampaignID(
            campaignID => $campaign->ID,
        );
        $ad_group_service->deleteAdGroups(
            adGroupIDs => [ grep { $_->ID } @ad_groups ],
        ) if @ad_groups;
    }
    $self->common_test_data( 'test_ad_group', undef );
    $self->common_test_data( 'test_ad_groups', undef );
    return;
}

sub cleanup_campaign {
    my $self = shift;

    if( my $campaign = $self->common_test_data( 'test_campaign' ) ){
        my $campaign_service = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

        $campaign_service->deleteCampaign( campaignID => $campaign->ID );
    }
    $self->common_test_data( 'test_campaign', undef );
    return;
}

sub cleanup_campaigns {
    my $self = shift;

    if ( $self->common_test_data( 'test_campaigns' ) ){
        my $campaign_service = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

        $campaign_service->deleteCampaigns( campaignIDs => [ map { $_->ID } @{ $self->common_test_data( 'test_campaigns' ) } ] );
    }
    $self->common_test_data( 'test_campaigns', undef );
    return;
}

sub cleanup_campaigns_in_test_account {
    my $self = shift;

    my $campaign_service = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

    return unless $campaign_service->account;

    my @campaigns = $campaign_service->getCampaignsByAccountIDByCampaignStatus(
        accountID => $campaign_service->account,
        status    => 'On',
    ) || ();
    push @campaigns,
        $campaign_service->getCampaignsByAccountIDByCampaignStatus(
            accountID => $campaign_service->account,
            status    => 'Off',
        ) || ();

#    $campaign_service->deleteCampaigns( campaignIDs => [ map { $_->ID } @campaigns ] );
    for my $campaign (@campaigns) {
        $campaign_service->deleteCampaign( campaignID => $campaign->ID );
    }
    $self->common_test_data( 'test_campaign', undef );
    $self->common_test_data( 'test_campaigns', undef );
    return;
}

our $run_post_tests;
sub run_post_tests {
    my $self = shift;

    return $run_post_tests if defined $run_post_tests;

    my $build;

    eval {
        $build = Module::Build->current;
    };

    $run_post_tests = ( $build 
                        and $build->notes( 'run_post_tests' )
                        and $build->notes( 'run_post_tests' ) =~ /^y/i
                      )
                    ? 1
                    : 0;
}


# helper methods........
our $campaign_count = 0;
sub create_campaign {
    my ( $self, %args ) = @_;

    my $formatter = DateTime::Format::W3CDTF->new;
    my $datetime = DateTime->now;
    $datetime->set_time_zone( 'America/Chicago' );
    $datetime->add( days => 1 );

    my $start_datetime = $formatter->format_datetime( $datetime );

    $datetime->add( years => 1 );
    my $end_datetime   = $formatter->format_datetime( $datetime );

    my $ysm_ws = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

    my $campaign = Yahoo::Marketing::Campaign->new
                                             ->startDate( $start_datetime )
                                             ->endDate(   $end_datetime )
                                             ->name( 'test campaign '.($$ + $campaign_count++) )
                                             ->status( 'On' )
                                             ->accountID( $ysm_ws->account )
                                             ->contentMatchON( 'true' )
                   ;

    my $response = $ysm_ws->addCampaign( campaign => $campaign );

    if ( $response->operationSucceeded ne 'true' ) {
        croak( 'addCampaign failed' );
    }

    return $response->campaign;
}

sub create_campaigns {
    my ( $self, %args ) = @_;

    my $formatter = DateTime::Format::W3CDTF->new;
    my $datetime = DateTime->now;
    $datetime->set_time_zone( 'America/Chicago' );
    $datetime->add( days => 1 );

    my $start_datetime = $formatter->format_datetime( $datetime );

    $datetime->add( years => 1 );
    my $end_datetime   = $formatter->format_datetime( $datetime );

    my $ysm_ws = Yahoo::Marketing::CampaignService->new->parse_config( section => $self->section );

    my $campaign1 = Yahoo::Marketing::Campaign->new
                                              ->startDate( $start_datetime )
                                              ->endDate(   $end_datetime )
                                              ->name( 'test campaign '.($$ + $campaign_count++).' 1' )
                                              ->status( 'On' )
                                              ->accountID( $ysm_ws->account )
                                              ->contentMatchON( 'true' )
                    ;
    my $campaign2 = Yahoo::Marketing::Campaign->new
                                              ->startDate( $start_datetime )
                                              ->endDate(   $end_datetime )
                                              ->name( 'test campaign '.($$ + $campaign_count++).' 2' )
                                              ->status( 'On' )
                                              ->accountID( $ysm_ws->account )
                                              ->contentMatchON( 'true' )
                    ;
    my $campaign3 = Yahoo::Marketing::Campaign->new
                                              ->startDate( $start_datetime )
                                              ->endDate(   $end_datetime )
                                              ->name( 'test campaign '.($$ + $campaign_count++).' 3' )
                                              ->status( 'On' )
                                              ->accountID( $ysm_ws->account )
                                              ->contentMatchON( 'true' )
                    ;

    my @responses = $ysm_ws->addCampaigns( campaigns => [ $campaign1, $campaign2, $campaign3 ] );

    if ( grep { $_->operationSucceeded ne 'true' } @responses ) {
        croak( 'addCampaigns failed' );
    }

    return map { $_->campaign } @responses;
}

our $ad_group_count = 0;
sub create_ad_group {
    my ( $self, %args ) = @_;
    my $campaign = $self->common_test_data( 'test_campaign' );

    my $ad_group = Yahoo::Marketing::AdGroup->new
                                            ->campaignID( $campaign->ID )
                                            ->name( 'test ad group '.($$ + $ad_group_count++) )
                                            ->status( 'On' )
                                            ->contentMatchON( 'true' )
                                            ->contentMatchMaxBid( '90' )
                                            ->sponsoredSearchON( 'true' )
                                            ->sponsoredSearchMaxBid( '90' )
                                            ->adAutoOptimizationON( 'false' )
                   ;

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );

    my $response = $ysm_ws->addAdGroup( adGroup => $ad_group );

    if ( $response->operationSucceeded ne 'true' ) {
        croak( 'addAdGroup failed' );
    }

    return $response->adGroup;
}

sub create_ad_groups {
    my ( $self ) = @_;

    my $campaign = $self->common_test_data( 'test_campaign' );
    # contentMatchMaxBid and sponsoredSearchMaxBid should NOT be required,
    # but for the bug in java code, they have to present for now.
    my $ad_group1 = Yahoo::Marketing::AdGroup->new
                                             ->campaignID( $campaign->ID )
                                             ->name( 'test ad group '.($$ + $ad_group_count++).' 1' )
                                             ->status( 'On' )
                                             ->contentMatchON( 'true' )
                                             ->contentMatchMaxBid( '90' )
                                             ->sponsoredSearchON( 'true' )
                                             ->sponsoredSearchMaxBid( '90' )
                                             ->adAutoOptimizationON( 'false' )
                    ;

    my $ad_group2 = Yahoo::Marketing::AdGroup->new
                                             ->campaignID( $campaign->ID )
                                             ->name( 'test ad group '.($$ + $ad_group_count++).' 2' )
                                             ->status( 'On' )
                                             ->contentMatchON( 'true' )
                                             ->contentMatchMaxBid( '90' )
                                             ->sponsoredSearchON( 'true' )
                                             ->sponsoredSearchMaxBid( '90' )
                                             ->adAutoOptimizationON( 'false' )
                    ;

    my $ad_group3 = Yahoo::Marketing::AdGroup->new
                                             ->campaignID( $campaign->ID )
                                             ->name( 'test ad group '.($$ + $ad_group_count++).' 3' )
                                             ->status( 'On' )
                                             ->contentMatchON( 'true' )
                                             ->contentMatchMaxBid( '90' )
                                             ->sponsoredSearchON( 'true' )
                                             ->sponsoredSearchMaxBid( '90' )
                                             ->adAutoOptimizationON( 'false' )
                    ;

    my $ysm_ws = Yahoo::Marketing::AdGroupService->new->parse_config( section => $self->section );

    my @responses = $ysm_ws->addAdGroups( adGroups => [ $ad_group1, $ad_group2, $ad_group3 ] );

    if ( grep { $_->operationSucceeded ne 'true' } @responses ) {
        croak( 'addAdGroups failed' );
    }

    return map { $_->adGroup } @responses;
}

our $ad_count = 0;
sub create_ad {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::AdService->new->parse_config( section => $self->section );

    my $ad = Yahoo::Marketing::Ad->new
                                 ->accountID( $ysm_ws->account )
                                 ->adGroupID( $self->common_test_data( 'test_ad_group' )->ID )
                                 ->name( 'test ad '.($$ + $ad_count++) )
                                 ->status( 'On' )
                                 ->title( 'An Example Title' )
                                 ->displayUrl( 'http://www.perl.com/' )
                                 ->url( 'http://www.perl.com/' )
                                 ->description( 'Here\'s some long description.  Not overly long though.' )
                                 ->shortDescription( 'Here\'s some short description' )
             ;

    my $response = $ysm_ws->addAd( ad => $ad );

    if ( $response->operationSucceeded ne 'true' ) {
        croak( 'addAd failed' );
    }

    #if( $response->ad->editorialStatus eq 'Pending' ){
    #    my $count = 0;
    #    while(  my $status = $ysm_ws->getAd( adID => $response->ad->ID )->editorialStatus eq 'Pending'
    #        and ++$count < 10 ){
    #        use Test::More;
    #        diag( "warning, Ad ". $response->ad->ID . " still Pending ");
    #        sleep 2;
    #    }

    #    #confess( "Oops, our newly added ad is pending: ". (Dumper $response->ad) )
    #        #if $count >= 10;
    #}

    return $response->ad;
}

sub create_ads {
    my ( $self ) = @_;

    my $campaign = $self->common_test_data( 'test_campaign' );

    my $ysm_ws = Yahoo::Marketing::AdService->new->parse_config( section => $self->section );

    my $ad1 = Yahoo::Marketing::Ad->new
                                  ->accountID( $ysm_ws->account )
                                  ->adGroupID( $self->common_test_data( 'test_ad_group' )->ID )
                                  ->name( 'test ad '.($$ + $ad_count++) )
                                  ->status( 'On' )
                                  ->title( 'lamest title in the world' )
                                  ->displayUrl( 'http://www.perl.com/' )
                                  ->url( 'http://www.perl.com/' )
                                  ->description( 'here\'s some great long description.  Not too long though.' )
                                  ->shortDescription( 'here\'s some great short description' )
              ;
    my $ad2 = Yahoo::Marketing::Ad->new
                                  ->accountID( $ysm_ws->account )
                                  ->adGroupID( $self->common_test_data( 'test_ad_group' )->ID )
                                  ->name( 'test ad '.($$ + $ad_count++) )
                                  ->status( 'On' )
                                  ->title( 'lamest title in the world' )
                                  ->displayUrl( 'http://www.perl.com/' )
                                  ->url( 'http://www.perl.com/' )
                                  ->description( 'here\'s some great long description.  Not too long though.' )
                                  ->shortDescription( 'here\'s some great short description' )
              ;
    my $ad3 = Yahoo::Marketing::Ad->new
                                  ->accountID( $ysm_ws->account )
                                  ->adGroupID( $self->common_test_data( 'test_ad_group' )->ID )
                                  ->name( 'test ad '.($$ + $ad_count++) )
                                  ->status( 'On' )
                                  ->title( 'lamest title in the world' )
                                  ->displayUrl( 'http://www.perl.com/' )
                                  ->url( 'http://www.perl.com/' )
                                  ->description( 'here\'s some great long description.  Not too long though.' )
                                  ->shortDescription( 'here\'s some great short description' )
              ;


    my @responses = $ysm_ws->addAds( ads => [ $ad1, $ad2, $ad3 ] );

    if ( grep { $_->operationSucceeded ne 'true' } @responses ) {
        croak( 'addAds failed' );
    }

    return map { $_->ad } @responses;
}


our $keyword_count = 0;
sub create_keyword {
    my ( $self, %args ) = @_;

    my $text = $args{text} || ('test keyword text '.( $$ + $keyword_count ));

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );

    my $keyword = Yahoo::Marketing::Keyword->new
                                           ->adGroupID( $self->common_test_data( 'test_ad_group' )->ID )
                                           ->text( $text )
                                           ->alternateText( 'test keyword alternate text '.( $$ + $keyword_count ) )
                                           ->sponsoredSearchMaxBid( 100 )
                                           ->status( 'On' )
                                           ->watchON( 'true' )
                                           ->advancedMatchON( 'true' )
                                           ->url( 'http://www.yahoo.com/testkeyword?id='.( $$ + $keyword_count ) )
                  ;

    $keyword_count++;
    my $response = $ysm_ws->addKeyword( keyword => $keyword );

    if ( $response->operationSucceeded ne 'true' ) {
        croak( 'addKeyword failed' );
    }

    return $response->keyword;
}

sub create_keywords {
    my ( $self, %args ) = @_;

    my $ysm_ws = Yahoo::Marketing::KeywordService->new->parse_config( section => $self->section );

    my $keyword1 = Yahoo::Marketing::Keyword->new
                                            ->adGroupID( $self->common_test_data( 'test_ad_group' )->ID )
                                            ->text( 'test keyword text '.( $$ + $keyword_count ) )
                                            ->alternateText( 'test keyword alternate text '.( $$ + $keyword_count ) )
                                            ->sponsoredSearchMaxBid( 100 )
                                            ->status( 'On' )
                                            ->watchON( 'true' )
                                            ->advancedMatchON( 'true' )
                                            ->url( 'http://www.yahoo.com/testkeyword?id='.( $$ + $keyword_count++ ) )
                    ;
    my $keyword2 = Yahoo::Marketing::Keyword->new
                                            ->adGroupID( $self->common_test_data( 'test_ad_group' )->ID )
                                            ->text( 'test keyword text '.( $$ + $keyword_count ) )
                                            ->alternateText( 'test keyword alternate text '.( $$ + $keyword_count ) )
                                            ->sponsoredSearchMaxBid( 100 )
                                            ->status( 'On' )
                                            ->watchON( 'true' )
                                            ->advancedMatchON( 'true' )
                                            ->url( 'http://www.yahoo.com/testkeyword?id='.( $$ + $keyword_count++ ) )
                    ;
    my $keyword3 = Yahoo::Marketing::Keyword->new
                                            ->adGroupID( $self->common_test_data( 'test_ad_group' )->ID )
                                            ->text( 'test keyword text '.( $$ + $keyword_count ) )
                                            ->alternateText( 'test keyword alternate text '.( $$ + $keyword_count ) )
                                            ->sponsoredSearchMaxBid( 100 )
                                            ->status( 'On' )
                                            ->watchON( 'true' )
                                            ->advancedMatchON( 'true' )
                                            ->url( 'http://www.yahoo.com/testkeyword?id='.( $$ + $keyword_count++ ) )
                    ;

    my @responses = $ysm_ws->addKeywords( keywords => [ $keyword1, $keyword2, $keyword3 ] );

    if ( grep { $_->operationSucceeded ne 'true' } @responses ) {
        croak( 'addKeywords failed' );
    }

    return map { $_->keyword } @responses;
}

BEGIN {
    if( __PACKAGE__->run_post_tests ){

        eval { require YAML;
               require DateTime;
               require DateTime::Format::W3CDTF;
             };
        die "running post tests requires the following CPAN modules:
    YAML
    DateTime
    DateTime::Format::W3CDTF

Please make sure they're properly installed on your system.  
" if $@;
    }
}


1;
