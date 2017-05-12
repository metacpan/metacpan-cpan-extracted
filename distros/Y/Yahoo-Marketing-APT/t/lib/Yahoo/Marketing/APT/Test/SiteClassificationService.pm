package Yahoo::Marketing::APT::Test::SiteClassificationService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::SiteClassificationService;
use Yahoo::Marketing::APT::Site;
use Yahoo::Marketing::APT::CustomContentCategory;
use Yahoo::Marketing::APT::CustomSection;

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
    return $self->SUPER::section().'_managed_publisher';
}

sub startup_test_site_service : Test(startup) {
    my ( $self ) = @_;

    $self->common_test_data( 'test_site', $self->create_site ) unless defined $self->common_test_data( 'test_site' );
    $self->common_test_data( 'test_sites', [$self->create_sites] ) unless defined $self->common_test_data( 'test_sites' );
}

sub shutdown_test_site_service : Test(shutdown) {
    my ( $self ) = @_;

    $self->cleanup_site;
    $self->cleanup_sites;
}


sub test_can_operate_custom_content_category : Test(10) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::SiteClassificationService->new->parse_config( section => $self->section );

    my $site = $self->common_test_data( 'test_site' );

    my $custom_content_category = Yahoo::Marketing::APT::CustomContentCategory->new
                                                                              ->name( 'test cat' )
                                                                              ->siteID( $site->ID )
                                                                                  ;
    # test addCustomContentCategory
    my $response = $ysm_ws->addCustomContentCategory(
        customContentCategory => $custom_content_category,
    );

    ok( $response, 'can call addCustomContentCategory' );
    is( $response->operationSucceeded, 'true', 'add custom content category successfully' );
    is( $response->category->name, 'test cat', 'name matches' );

    $custom_content_category = $response->category;

    # test getCustomContentCategory
    my $fetched_category = $ysm_ws->getCustomContentCategory( customContentCategoryID => $custom_content_category->ID );

    ok( $fetched_category, 'can call getCustomContentCategory' );
    is( $fetched_category->siteID, $custom_content_category->siteID, 'siteID matches' );

    # test updateCustomContentCategory
    $response = $ysm_ws->updateCustomContentCategory( customContentCategory => $fetched_category->name( 'new cat' ) );
    ok($response, 'can call updateCustomContentCategory' );
    is( $response->operationSucceeded, 'true', 'update custom content category successfully' );
    is( $response->category->name, 'new cat', 'name updated' );

    # test deleteCustomContentCategory
    $response = $ysm_ws->deleteCustomContentCategory( customContentCategoryID => $fetched_category->ID );
    ok( $response, 'can call deleteCustomContentCategory' );
    is( $response->operationSucceeded, 'true', 'delete custom content category successfully' );

}


sub test_can_operate_custom_content_categories : Test(12) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::SiteClassificationService->new->parse_config( section => $self->section );

    my @sites = @{ $self->common_test_data( 'test_sites' ) };

    my @categories;
    foreach my $site (@sites) {
        my $custom_content_category = Yahoo::Marketing::APT::CustomContentCategory->new
                                                                                  ->name( "test cat ".$$ )
                                                                                  ->siteID( $site->ID )
                                                                                      ;
        push @categories, $custom_content_category;
    }

    # test addCustomContentCategories
    my @responses = $ysm_ws->addCustomContentCategories(
        customContentCategories => \@categories,
    );

    ok( @responses, 'can call addCustomContentCategories' );
    is( $responses[0]->operationSucceeded, 'true', 'add custom content category successfully' );
    like( $responses[0]->category->name, qr/^test cat/, 'name matches' );

    @categories = map { $_->category } @responses;

    # test getCustomContentCategories
    my @fetched_categories = $ysm_ws->getCustomContentCategories( customContentCategoryIDs => [map {$_->ID} @categories] );

    ok( @fetched_categories, 'can call getCustomContentCategories' );
    like( $fetched_categories[0]->name, qr/^test cat/, 'name matches' );

    # test updateCustomContentCategories
    @fetched_categories = map { $_->description( 'test desc' ) } @fetched_categories;
    @responses = $ysm_ws->updateCustomContentCategories( customContentCategories => \@fetched_categories );

    ok( @responses, 'can call updateCustomContentCategories' );
    is( $responses[0]->operationSucceeded, 'true', 'update custom content categories successfully' );
    is( $responses[0]->category->description, 'test desc', 'description updated' );

    # test getCustomContentCategoriesBySiteID
    my @current_categories = $ysm_ws->getCustomContentCategoriesBySiteID( siteID => $sites[0]->ID );
    ok( @current_categories, 'can call getCustomContentCategoriesBySiteID' );
    is( $current_categories[0]->siteID, $sites[0]->ID, 'site id matches' );

    # test deleteCustomContentCategories
    @responses = $ysm_ws->deleteCustomContentCategories( customContentCategoryIDs => [map {$_->ID} @fetched_categories] );
    ok( @responses, 'can call deleteCustomContentCategories' );
    is( $responses[0]->operationSucceeded, 'true', 'delete custom content categories successfully' );

}


sub test_can_operate_custom_section : Test(10) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::SiteClassificationService->new->parse_config( section => $self->section );

    my $site = $self->common_test_data( 'test_site' );

    my $custom_section = Yahoo::Marketing::APT::CustomSection->new
                                                             ->name( 'test section' )
                                                             ->siteID( $site->ID )
                                                                 ;
    # test addCustomSection
    my $response = $ysm_ws->addCustomSection(
        customSection => $custom_section,
    );

    ok( $response, 'can call addCustomSection' );
    is( $response->operationSucceeded, 'true', 'add custom section successfully' );
    is( $response->customSection->name, 'test section', 'name matches' );

    $custom_section = $response->customSection;

    # test getCustomSection
    my $fetched_section = $ysm_ws->getCustomSection( customSectionID => $custom_section->ID );

    ok( $fetched_section, 'can call getCustomSection' );
    is( $fetched_section->siteID, $custom_section->siteID, 'siteID matches' );

    # test updateCustomSection
    $response = $ysm_ws->updateCustomSection( customSection => $fetched_section->name( 'new section' ) );
    ok($response, 'can call updateCustomSection' );
    is( $response->operationSucceeded, 'true', 'update custom section successfully' );
    is( $response->customSection->name, 'new section', 'name updated' );

    # test deleteCustomSection
    $response = $ysm_ws->deleteCustomSection( customSectionID => $fetched_section->ID );
    ok( $response, 'can call deleteCustomSection' );
    is( $response->operationSucceeded, 'true', 'delete custom section successfully' );

}


sub test_can_operate_custom_sections : Test(12) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::SiteClassificationService->new->parse_config( section => $self->section );

    my @sites = @{ $self->common_test_data( 'test_sites' ) };

    my @sections;
    foreach my $site (@sites) {
        my $custom_section = Yahoo::Marketing::APT::CustomSection->new
                                                                 ->name( "test section ".$$ )
                                                                 ->siteID( $site->ID )
                                                                     ;
        push @sections, $custom_section;
    }

    # test addCustomSections
    my @responses = $ysm_ws->addCustomSections(
        customSections => \@sections,
    );

    ok( @responses, 'can call addCustomSections' );
    is( $responses[0]->operationSucceeded, 'true', 'add custom sections successfully' );
    like( $responses[0]->customSection->name, qr/^test section/, 'name matches' );

    @sections = map { $_->customSection } @responses;

    # test getCustomSections
    my @fetched_sections = $ysm_ws->getCustomSections( customSectionIDs => [map {$_->ID} @sections] );

    ok( @fetched_sections, 'can call getCustomSections' );
    like( $fetched_sections[0]->name, qr/^test section/, 'name matches' );

    # test updateCustomSections
    @fetched_sections = map { $_->description( 'test desc' ) } @fetched_sections;
    @responses = $ysm_ws->updateCustomSections( customSections => \@fetched_sections );

    ok( @responses, 'can call updateCustomSections' );
    is( $responses[0]->operationSucceeded, 'true', 'update custom sections successfully' );
    is( $responses[0]->customSection->description, 'test desc', 'description updated' );

    # test getCustomSectionsBySiteID
    my @current_sections = $ysm_ws->getCustomSectionsBySiteID( siteID => $sites[0]->ID );
    ok( @current_sections, 'can call getCustomSectionsBySiteID' );
    is( $current_sections[0]->siteID, $sites[0]->ID, 'site id matches' );

    # test deleteCustomSections
    @responses = $ysm_ws->deleteCustomSections( customSectionIDs => [map {$_->ID} @fetched_sections] );
    ok( @responses, 'can call deleteCustomSections' );
    is( $responses[0]->operationSucceeded, 'true', 'delete custom sections successfully' );

}


1;

