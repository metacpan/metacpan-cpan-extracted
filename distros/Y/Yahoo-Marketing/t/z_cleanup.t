#!perl 
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use Test::More tests => 2;


use Data::Dumper;
use Module::Build;
use Yahoo::Marketing::AdGroup;
use Yahoo::Marketing::Campaign;
use Yahoo::Marketing::AdService;
use Yahoo::Marketing::AdGroupService;
use Yahoo::Marketing::KeywordService;
use Yahoo::Marketing::CampaignService;

#use SOAP::Lite +trace => [qw/ debug method fault /]; #global debug for SOAP calls


# cleanup campaigns

my $build;
eval { $build = Module::Build->current; };

SKIP: { 
    skip 'not running post tests', 2, unless $build
                                         and $build->notes( 'run_post_tests' ) 
                                         and $build->notes( 'run_post_tests' ) =~ /^y/i
    ;

    my $section = $build->notes('config_section');

    my $keyword_service  = Yahoo::Marketing::KeywordService->new->parse_config(  section => $section );
    my $ad_service       = Yahoo::Marketing::AdService->new->parse_config(  section => $section );
    my $ad_group_service = Yahoo::Marketing::AdGroupService->new->parse_config(  section => $section );
    my $campaign_service = Yahoo::Marketing::CampaignService->new->parse_config( section => $section );

    my @keywords = grep { defined $_ and $_ ne '' } 
                       $keyword_service->getKeywordsByAccountID(
                                             accountID      => $keyword_service->account,
                                             includeDeleted => 'false',
                                             startElement   => 0,
                                             numElements    => 1000,
                                         );



    if( @keywords ){
        ok( defined $keyword_service->deleteKeywords( keywordIDs => [ map { $_->ID } @keywords ], ) );
        diag( ( scalar @keywords ) . " keywords have been deleted successfully." );
    }else{
        ok( 1 );
        diag( 'no keywords found.' );
    }


    my @campaigns = grep { defined $_ } 
                        $campaign_service->getCampaignsByAccountID(
                                    accountID     => $campaign_service->account,
                                    includeDeleted => 'false',
                                 );

    if( @campaigns ){

        foreach my $campaign ( @campaigns ){
            my @ad_groups = grep { defined $_ } 
                                $ad_group_service->getAdGroupsByCampaignID(
                                    campaignID     => $campaign->ID,
                                    includeDeleted => 'false',
                                    startElement   => 0,
                                    numElements    => 1000,
                                );

            foreach my $ad_group ( @ad_groups ) {
                my @ads = $ad_service->getAdsByAdGroupID(
                    adGroupID      => $ad_group->ID,
                    includeDeleted => 'false',
                );
                if( @ads ){
                    $ad_service->deleteAds( adIDs => [ map { $_->ID } @ads ], );
                    diag( ( scalar @ads ) . " ads have been deleted successfully." );
                }
            }

            if( @ad_groups ){
                $ad_group_service->deleteAdGroups( adGroupIDs => [ map { $_->ID } @ad_groups ], );
                diag( ( scalar @ad_groups ) . " adGroups have been deleted successfully." );
            }else{
                diag( 'no adGroups found.' );
            }
        }

        ok( $campaign_service->deleteCampaigns( campaignIDs => [ map { $_->ID } @campaigns ], ));
        diag( ( scalar @campaigns ) . " campaigns have been deleted successfully." );
    }else{
        ok( 1 );
        diag( 'no campaigns found.' );
    }
}

