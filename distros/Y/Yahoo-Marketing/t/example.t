#!perl 
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 


# This example follows the example perl code at
#
# http://searchmarketing.yahoo.com/developer/docs/V7/sample_code/perl.php
#
# only it uses the Yahoo::Marketing modules to perform the same functions.
#
# Hopefully, it serves to illustrate both how to perform some basic functions 
# using Yahoo::Marketing, and also how Yahoo::Marketing is an easier alternative# than using SOAP::Lite directly
#
#

use strict; use warnings;

# uncomment to see soap request / responses
#use SOAP::Lite +trace => [qw/ debug method fault /]; #global debug for SOAP calls

use Module::Build;
use Test::More tests => 20;

# Yahoo::Marketing complex types and services

use Yahoo::Marketing::Ad;
use Yahoo::Marketing::AdGroup;
use Yahoo::Marketing::Keyword;
use Yahoo::Marketing::Campaign;
use Yahoo::Marketing::AdService;
use Yahoo::Marketing::ExcludedWord;
use Yahoo::Marketing::AdGroupService;
use Yahoo::Marketing::KeywordService;
use Yahoo::Marketing::CampaignService;
use Yahoo::Marketing::ExcludedWordsService;

# we will skip running this test unless we're running ./Build posttest
my $build;
eval { $build = Module::Build->current; };
SKIP: { 
    eval {
        # required CPAN modules
        require DateTime;
        require DateTime::Format::W3CDTF;
    };
    skip 'required modules not installed', 20, if $@;
    skip 'not running post tests', 20, unless $build
                                          and $build->notes( 'run_post_tests' ) 
                                          and $build->notes( 'run_post_tests' ) =~ /^y/i
    ;

my $config_section = $build->notes('config_section');

diag("using config section $config_section");

# setup our services
my $campaign_service        = Yahoo::Marketing::CampaignService->new->parse_config(       section => $config_section );
my $ad_group_service        = Yahoo::Marketing::AdGroupService->new->parse_config(        section => $config_section );
my $ad_service              = Yahoo::Marketing::AdService->new->parse_config(             section => $config_section );
my $keyword_service         = Yahoo::Marketing::KeywordService->new->parse_config(        section => $config_section );
my $excluded_words_service  = Yahoo::Marketing::ExcludedWordsService->new->parse_config(  section => $config_section );


# setup start and end dates for our campaign
my $formatter = DateTime::Format::W3CDTF->new;
my $datetime = DateTime->now;
$datetime->set_time_zone( 'America/Chicago' );
$datetime->add( days => 1 );

my $start_datetime = $formatter->format_datetime( $datetime );

$datetime->add( years => 1 );
my $end_datetime   = $formatter->format_datetime( $datetime );


# Create a Campaign
my $campaign_response = $campaign_service->addCampaign( campaign => 
                            Yahoo::Marketing::Campaign->new
                                                      ->name( 'MP3'.$$ )  # use pid to help ensure unique name
                                                      ->description( 'MP3 Player' )
                                                      ->accountID( $campaign_service->account )
                                                      ->status( 'On' )
                                                      ->sponsoredSearchON( 'true' )
                                                      ->advancedMatchON( 'true' )
                                                      ->contentMatchON( 'true' )
                                                      ->campaignOptimizationON( 'false' )
                                                      ->startDate( $start_datetime )
                                                      ->endDate( $end_datetime )
                       );

ok( $campaign_response );
is( $campaign_response->operationSucceeded, 'true', 'operation succeeded' );

my $campaign = $campaign_response->campaign;

ok( $campaign );
diag( "\n" );
diag( "------> Campaign ID: ".$campaign->ID."\n" );


# Create an Ad Group
my $ad_group_response = $ad_group_service->addAdGroup( adGroup => 
                            Yahoo::Marketing::AdGroup->new
                                                     ->accountID(  $campaign_service->account )
                                                     ->name( 'MP3 '.$$ )  # use pid to help ensure unique name
                                                     ->adAutoOptimizationON( 'false' )
                                                     ->advancedMatchON( 'false' )
                                                     ->campaignID( $campaign->ID )
                                                     ->contentMatchON( 'true' )
                                                     ->contentMatchMaxBid( 0.25 )
                                                     ->sponsoredSearchON( 'true' )
                                                     ->sponsoredSearchMaxBid( 0.5 )
                                                     ->status( 'On' )
                                                     ->watchON( 'false' )
                        );

ok( $ad_group_response );
is( $ad_group_response->operationSucceeded, 'true', 'operation succeeded' );

my $ad_group = $ad_group_response->adGroup;
ok( $ad_group );
diag( "\n" );
diag( "------> Ad Group ID: ".$ad_group->ID."\n" );

# Create individual Ads for the Ad Group
my @ad_responses = $ad_service->addAds( ads => [
                       Yahoo::Marketing::Ad->new
                                           ->adGroupID( $ad_group->ID )
                                           ->description( 'Before you buy, compare prices at e-electronics-gear. We have a complete selection of computers, electronics, video games and office products from consumer-rated online stores.' )
                                           ->displayUrl( 'http://www.e-electronics-gear.com' )
                                           ->name( 'IPod1' )
                                           ->shortDescription( 'Compare Prices at e-electronics-gear.' )
                                           ->status( 'On' )
                                           ->title( 'IPod - Cheaper Prices' )
                                           ->url( 'http://www.e-electronics-gear.com?display&ad=ipod' )  # unescaped example
                       ,
                       Yahoo::Marketing::Ad->new
                                           ->adGroupID(  $ad_group->ID )
                                           ->description( 'Before you buy, compare prices on {keyword:e-gear} at e-electronics-gear. We have a complete selection of computers, electronics, video games and office products from consumer-rated online stores.' )
                                           ->displayUrl( 'http://www.e-electronics-gear.com' )
                                           ->name( 'IPod2' )
                                           ->shortDescription( 'Compare Prices on {keyword:E-Gear} at e-electronics-gear.' )
                                           ->status( 'On' )
                                           ->title( '{keyword:Electronics} - Cheaper Prices' )
                                           ->url( 'http://www.e-electronics-gear.com?display&amp;ad=ipod2' ) #escaped example
                       ,
                   ] );

ok( scalar @ad_responses == 2 );
ok( not grep { $_->operationSucceeded ne 'true' } @ad_responses );

my @ads = map { $_->ad } @ad_responses;

ok ( scalar @ads == 2 );

diag( "\n" );
diag( "------> Ad ID: ".$ads[0]->ID."\n" );
diag( "------> Ad ID: ".$ads[1]->ID."\n" );

# Add Keywords
my @keyword_responses = $keyword_service->addKeywords( keywords => [
                            Yahoo::Marketing::Keyword->new
                                                     ->adGroupID( $ad_group->ID ) 
                                                     ->advancedMatchON( 'true' )
                                                     ->status( 'On' )
                                                     ->text( 'ipod' )
                            ,
                            Yahoo::Marketing::Keyword->new
                                                     ->adGroupID( $ad_group->ID ) 
                                                     ->advancedMatchON( 'true' )
                                                     ->status( 'On' )
                                                     ->text( 'iPod Mini' )
                            ,
                            Yahoo::Marketing::Keyword->new
                                                     ->adGroupID( $ad_group->ID ) 
                                                     ->advancedMatchON( 'true' )
                                                     ->status( 'On' )
                                                     ->text( 'iPod U2' )
                            ,
                            Yahoo::Marketing::Keyword->new
                                                     ->adGroupID( $ad_group->ID ) 
                                                     ->advancedMatchON( 'true' )
                                                     ->status( 'On' )
                                                     ->text( 'iPod Shuffle' )
                            ,
                        ] );

ok( scalar @keyword_responses == 4 );
ok( not grep { $_->operationSucceeded ne 'true' } @keyword_responses );

my @keywords = map { $_->keyword } @keyword_responses;

ok ( scalar @keywords == 4 );
diag( "\n" );
diag( "------> Keyword ID: ".$keywords[ $_ ]->ID."\n" ) for ( 0..3 );

# Add Excluded Words for the Ad Group
my @excluded_word_responses = $excluded_words_service->addExcludedWordsToAdGroup( excludedWords => [
                                  Yahoo::Marketing::ExcludedWord->new 
                                                                ->adGroupID( $ad_group->ID ) 
                                                                ->text( 'rio' )
                                  ,
                                  Yahoo::Marketing::ExcludedWord->new 
                                                                ->adGroupID( $ad_group->ID )
                                                                ->text( 'wma' )
                                  ,
                                  Yahoo::Marketing::ExcludedWord->new 
                                                                ->adGroupID( $ad_group->ID )
                                                                ->text( 'plays for sure' )
                                  ,
                              ] );

ok( scalar @excluded_word_responses == 3 );
ok( not grep { $_->operationSucceeded ne 'true' } @excluded_word_responses );

my @excluded_words = map { $_->excludedWord } @excluded_word_responses;

ok ( scalar @excluded_words == 3 );
diag( "\n" );
diag( "------> Excluded Word ID: ".$excluded_words[ $_ ]->ID."\n" ) for ( 0..2 );

diag( "done creating objects, cleaning up...\n" );

ok( my $foo = $excluded_words_service->deleteExcludedWords( excludedWordIDs =>
                                 [ map { $_->ID } @excluded_words ]
                             )
  );

ok( $keyword_service->deleteKeywords( keywordIDs =>
                          [ map { $_->ID } @keywords ]
                      )
  );

ok( $ad_service->deleteAds( adIDs =>
                     [ map { $_->ID } @ads ]
                 )
  );

ok( $ad_group_service->deleteAdGroup( adGroupID  => $ad_group->ID ) );
ok( $campaign_service->deleteCampaign( campaignID => $campaign->ID ) );


diag( "done!\n" );



}  # end SKIP block
