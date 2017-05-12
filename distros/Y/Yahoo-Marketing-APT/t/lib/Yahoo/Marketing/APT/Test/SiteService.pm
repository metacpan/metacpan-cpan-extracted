package Yahoo::Marketing::APT::Test::SiteService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::SiteService;
use Yahoo::Marketing::APT::Site;
use Yahoo::Marketing::APT::SiteResponse;
use Yahoo::Marketing::APT::SiteAccess;
use Yahoo::Marketing::APT::SiteAccessResponse;
use Yahoo::Marketing::APT::BasicResponse;
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


sub test_can_add_site : Test(1) {
    my $self = shift;

    ok( $self->common_test_data( 'test_site' ) );
}

sub test_can_add_sites : Test(1) {
     my $self = shift;

    ok( $self->common_test_data( 'test_sites' ) );
}

sub test_can_get_site : Test(3) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::SiteService->new->parse_config( section => $self->section );

    my $site = $self->common_test_data( 'test_site' );
    my $fetched_site = $ysm_ws->getSite( siteID => $site->ID );

    ok( $fetched_site );
    is( $site->ID, $fetched_site->ID, 'ID is right' );
    is( $site->name, $fetched_site->name, 'name is right' );
}

sub test_can_get_sites : Test(3) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::SiteService->new->parse_config( section => $self->section );

    my @sites = @{ $self->common_test_data( 'test_sites' ) };
    my @fetched_sites = $ysm_ws->getSites( siteIDs => [$sites[0]->ID, $sites[1]->ID] );

    is( scalar @fetched_sites, 2, 'got correct number of sites returned' );

    like( $fetched_sites[0]->name, qr/^test site \d+ 1$/, 'name looks right' );
    like( $fetched_sites[0]->ID, qr/^[\d]+$/, 'ID is numeric' );
}

sub test_can_update_site : Test(2) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::SiteService->new->parse_config( section => $self->section );

    my $site = $self->common_test_data( 'test_site' );

    $site->url( $site->url.'/test.html' );

    my $updated_site = $ysm_ws->updateSite( site => $site )->site;

    ok( $updated_site );

    is( $site->url, $updated_site->url, 'site url is updated' );
}


sub test_can_update_sites : Test(2) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::SiteService->new->parse_config( section => $self->section );

    my @sites = @{ $self->common_test_data( 'test_sites' ) };

    foreach (@sites) {
       $_->url( $_->url.'/test.html' );
    }

    my @updated_sites = map { $_->site } ($ysm_ws->updateSites( sites => \@sites ));

    ok( @updated_sites );

    like( $updated_sites[0]->url, qr/test\.html$/, 'sites urls are updated' );
}

sub test_can_get_supported_site_languages : Test(1) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::SiteService->new->parse_config( section => $self->section );
    my @languages = $ysm_ws->getSupportedSiteLanguages ();
    ok( @languages);
}


sub test_can_operate_site_access: Test(12) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::SiteService->new->parse_config( section => $self->section );

    my $site = $self->common_test_data( 'test_site' );

    my $site_access = Yahoo::Marketing::APT::SiteAccess->new
                                                       ->method( 'GET' )
                                                       ->password( 'pswd' )
                                                       ->passwordParameter( 'password' )
                                                       ->siteID( $site->ID )
                                                       ->url( 'http://www.yahoo.com/' )
                                                       ->username( 'user' )
                                                       ->usernameParameter( 'username' )
                                                           ;

    # test addSiteAccess
    my $site_access_response = $ysm_ws->addSiteAccess( siteAccess => $site_access );
    ok( $site_access_response, 'can get site access response' );
    is( $site_access_response->operationSucceeded, 'true', 'can add site access' );

    $site_access = $site_access_response->siteAccess;
    ok( $site_access->ID, 'can get site access ID' );

    # test getSiteAccess
    my $fetched_site_access = $ysm_ws->getSiteAccess( siteAccessID => $site_access->ID );
    ok( $fetched_site_access, 'can get site access' );
    is( $site_access->ID, $fetched_site_access->ID, 'site access IDs match' );

    # test updateSiteAccess
    $site_access_response = $ysm_ws->updateSiteAccess( siteAccess => $fetched_site_access->username( 'username' )->password( 'pswd' )->method( 'GET' ) );
    ok( $site_access_response, 'can get site access response' );
    is( $site_access_response->operationSucceeded, 'true', 'can update site access' );
    my $updated_site_access = $site_access_response->siteAccess;
    is( $updated_site_access->username, 'username', 'username is right' );

    # test getSiteAccessBySiteID
    my $current_site_access = $ysm_ws->getSiteAccessBySiteID( siteID => $site->ID );
    ok( $current_site_access, 'can get site accessby site id' );
    is( $current_site_access->ID, $site_access->ID, 'site access IDs match' );

    # test deleteSiteAccess
    my $response = $ysm_ws->deleteSiteAccess( siteAccessID => $site_access->ID );
    ok( $response, 'can delete site access' );
    is( $response->operationSucceeded, 'true', 'delete site access successfully' );

}


sub test_can_operate_site_accesses: Test(10) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::SiteService->new->parse_config( section => $self->section );

    my @sites = @{ $self->common_test_data( 'test_sites' ) };

    my $site_access1 = Yahoo::Marketing::APT::SiteAccess->new
                                                        ->method( 'GET' )
                                                        ->password( 'pswd' )
                                                        ->passwordParameter( 'password' )
                                                        ->siteID( $sites[0]->ID )
                                                        ->url( $sites[0]->url )
                                                        ->username( 'user' )
                                                        ->usernameParameter( 'username' )
                                                           ;
    my $site_access2 = Yahoo::Marketing::APT::SiteAccess->new
                                                        ->method( 'GET' )
                                                        ->password( 'pswd' )
                                                        ->passwordParameter( 'password' )
                                                        ->siteID( $sites[1]->ID )
                                                        ->url( $sites[1]->url )
                                                        ->username( 'user' )
                                                        ->usernameParameter( 'username' )
                                                           ;
    my $site_access3 = Yahoo::Marketing::APT::SiteAccess->new
                                                        ->method( 'GET' )
                                                        ->password( 'pswd' )
                                                        ->passwordParameter( 'password' )
                                                        ->siteID( $sites[2]->ID )
                                                        ->url( $sites[2]->url )
                                                        ->username( 'user' )
                                                        ->usernameParameter( 'username' )
                                                           ;

    # test addSiteAccesses
    my @site_access_responses = $ysm_ws->addSiteAccesses( siteAccesses => [$site_access1, $site_access2, $site_access3] );
    ok( @site_access_responses, 'can get site access responses' );
    is( $site_access_responses[0]->operationSucceeded, 'true', 'can add site accesses' );

    my $site_access = $site_access_responses[0]->siteAccess;
    ok( $site_access->ID, 'can get site access ID' );

    # test getSiteAccesses
    my @fetched_site_accesses = $ysm_ws->getSiteAccesses( siteAccessIDs => [ map {$_->siteAccess->ID} @site_access_responses ] );
    ok( @fetched_site_accesses, 'can get site accesses' );
    is( $fetched_site_accesses[0]->username, 'user', 'site access username match' );

    # test updateSiteAccesses
    my @new_site_accesses = map { $_->username('username')->password( 'pswd' )->method( 'GET' ) } @fetched_site_accesses;
    @site_access_responses = $ysm_ws->updateSiteAccesses( siteAccesses => \@new_site_accesses );
    ok( @site_access_responses, 'can get site accesses response' );
    is( $site_access_responses[0]->operationSucceeded, 'true', 'can update site accesses' );
    my $updated_site_access = $site_access_responses[0]->siteAccess;
    is( $updated_site_access->username, 'username', 'username is right' );

    # test deleteSiteAccesses
    my @responses = $ysm_ws->deleteSiteAccesses( siteAccessIDs => [ map {$_->siteAccess->ID} @site_access_responses ] );
    ok( @responses, 'can delete site accesses' );
    is( $responses[0]->operationSucceeded, 'true', 'delete site access successfully' );

}


sub test_can_get_sites_by_account_id: Test(2) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::SiteService->new->parse_config( section => $self->section );

    my @sites;
    @sites = $ysm_ws->getSitesByAccountID();

    ok( @sites, 'can get sites by account id' );
	like( $sites[0]->ID, qr/\d+/, 'site ID matches');
};


sub test_can_activate_site: Test(3) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::SiteService->new->parse_config( section => $self->section );

    my $site = $self->common_test_data( 'test_site' );

    my $site_response = $ysm_ws->activateSite( siteID => $site->ID );
    ok( $site_response, 'can activate site' );
    is( $site_response->operationSucceeded, 'true', 'activate site successfully' );
    is( $site_response->site->ID, $site->ID, 'ID matches' );
}

sub test_can_activate_sites: Test(3) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::SiteService->new->parse_config( section => $self->section );

    my @sites = @{ $self->common_test_data( 'test_sites' ) };

    my @site_responses = $ysm_ws->activateSites( siteIDs => [ map {$_->ID} @sites ] );
    ok( @site_responses, 'can activate sites' );
    is( $site_responses[0]->operationSucceeded, 'true', 'activate sites successfully' );
    like( $site_responses[0]->site->name, qr/^test site/, 'name matches' );
}



1;

