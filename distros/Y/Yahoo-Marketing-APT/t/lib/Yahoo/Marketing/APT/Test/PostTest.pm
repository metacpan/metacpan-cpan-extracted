package Yahoo::Marketing::APT::Test::PostTest;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/Test::Class/;

use Carp qw/croak confess/;
use Test::More;
use Module::Build;
use Yahoo::Marketing::APT::Site;
use Yahoo::Marketing::APT::Folder;
use Yahoo::Marketing::APT::Pixel;
use Yahoo::Marketing::APT::PixelFrequency;
use Yahoo::Marketing::APT::Contact;
use Yahoo::Marketing::APT::LocationService;
use Yahoo::Marketing::APT::SiteService;
use Yahoo::Marketing::APT::FolderService;
use Yahoo::Marketing::APT::PixelService;
use Yahoo::Marketing::APT::ContactService;

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

        my $service = Yahoo::Marketing::APT::LocationService->new->parse_config( section => $self->section );

        if( $debug_level ){
            eval "use SOAP::Lite +trace => [qw/ fault /];";

            local $| = 1;
            diag(<<EODIAG);
Running post tests with the following settings:
    config section: @{[ $self->section ]}
    version:        @{[ $service->version ]}
    endpoint:       @{[ $service->endpoint]}
    username:       @{[ $service->username]}
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

    $self->cleanup_site;
    $self->cleanup_sites;
    $self->cleanup_creative_folder;
    $self->cleanup_ad_folder;
}


sub cleanup_site {
    my $self = shift;

    if( my $site = $self->common_test_data( 'test_site' ) ){
        my $site_service = Yahoo::Marketing::APT::SiteService->new->parse_config( section => $self->section );
        $site_service->deleteSite( siteID => $site->ID );
    }
    $self->common_test_data( 'test_site', undef );
    return;
}

sub cleanup_sites {
    my $self = shift;

    if ($self->common_test_data( 'test_sites' ) ){
        my $site_service = Yahoo::Marketing::APT::SiteService->new->parse_config( section => $self->section );
        $site_service->deleteSites( siteIDs => [ map { $_->ID } @{ $self->common_test_data( 'test_sites' ) } ] );
    }
    $self->common_test_data( 'test_sites', undef );
    return;
}

sub cleanup_creative_folder {
    my $self = shift;

    if( my $folder = $self->common_test_data( 'test_creative_folder' ) ){
        my $folder_service = Yahoo::Marketing::APT::FolderService->new->parse_config( section => $self->section );
        $folder_service->deleteFolder( folderID => $folder->ID );
    }
    $self->common_test_data( 'test_creative_folder', undef );
    return;
}

sub cleanup_ad_folder {
    my $self = shift;

    if( my $folder = $self->common_test_data( 'test_ad_folder' ) ){
        my $folder_service = Yahoo::Marketing::APT::FolderService->new->parse_config( section => $self->section );
        $folder_service->deleteFolder( folderID => $folder->ID );
    }
    $self->common_test_data( 'test_ad_folder', undef );
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
our $site_count = 0;
sub create_site {
    my ( $self, %args ) = @_;

    my $ysm_ws = Yahoo::Marketing::APT::SiteService->new->parse_config( section => $self->section );

    my $num = $$ + $site_count++;
    my $site = Yahoo::Marketing::APT::Site->new
                                     ->language( 'en-US' )
                                     ->name( 'test site '.$num )
                                     ->url( 'http://www.'.$num.'.com' )
                                             ;

    my $response = $ysm_ws->addSite( site => $site );

    if ( $response->operationSucceeded ne 'true' ) {
        croak( 'addSite failed' );
    }

    return $response->site;
}

sub create_sites {
    my ( $self, %args ) = @_;

    my $ysm_ws = Yahoo::Marketing::APT::SiteService->new->parse_config( section => $self->section );

    my $site1 = Yahoo::Marketing::APT::Site->new
                                           ->language( 'en-US' )
                                           ->name( 'test site '.($$ + $site_count++).' 1' )
                                           ->url( 'http://www.'.$$.'1.com' )
                                             ;
    my $site2 = Yahoo::Marketing::APT::Site->new
                                           ->language( 'en-US' )
                                           ->name( 'test site '.($$ + $site_count++).' 2' )
                                           ->url( 'http://www.'.$$.'2.com' )
                                             ;
    my $site3 = Yahoo::Marketing::APT::Site->new
                                           ->language( 'en-US' )
                                           ->name( 'test site '.($$ + $site_count++).' 3' )
                                           ->url( 'http://www.'.$$.'3.com' )
                                             ;

    my @responses = $ysm_ws->addSites( sites => [ $site1, $site2, $site3 ] );

    if ( grep { $_->operationSucceeded ne 'true' } @responses ) {
        croak( 'addSites failed' );
    }

    return map { $_->site } @responses;
}

our $folder_count = 0;
sub create_folder {
    my ( $self, %args ) = @_;

    my $ysm_ws = Yahoo::Marketing::APT::FolderService->new->parse_config( section => $self->section );

    my $num = $$ + $folder_count++;

    my $root_folder = $ysm_ws->getRootFolder( folderType => $args{type} );

    my $folder = Yahoo::Marketing::APT::Folder->new
                                              ->name( 'test folder '.$num )
                                              ->parentFolderID( $root_folder->ID )
                                                ;

    my $response = $ysm_ws->addFolder( folder => $folder );

    if ( $response->operationResult ne 'Success' ) {
        croak( 'addFolder failed' );
    }

    return $response->folder;
}

sub create_pixel {
    my ( $self, %args ) = @_;

    my $ysm_ws = Yahoo::Marketing::APT::PixelService->new->parse_config( section => $self->section );

    my @pixels = $ysm_ws->getPixelsByAccountID( startElement => 0, numElements => 10 );
    foreach ( @pixels ) {
        next unless $_->name eq 'sdk test pixel';
        return $_;
    }

    my $pixel = Yahoo::Marketing::APT::Pixel->new
                                            ->isActive( 'true' )
                                            ->name( 'sdk test pixel' )
                                            ->pixelFrequency( Yahoo::Marketing::APT::PixelFrequency->new
                                                                                                   ->type( 'Every' ) )
                                                                                                       ;

    my $response = $ysm_ws->addPixel( pixel => $pixel );

    if ( $response->operationSucceeded ne 'true' ) {
        croak( 'addPixel failed' );
    }

    return $response->pixel;
}


sub create_contact {
    my ( $self, %args ) = @_;

    my $ysm_ws = Yahoo::Marketing::APT::ContactService->new->parse_config( section => $self->section );

    my @contacts = $ysm_ws->getContactsByAccountID( startElement => 0, numElements => 1000 );
    foreach ( @contacts ) {
        next unless $_->firstName eq 'sdkTestFirstName' and $_->lastName eq 'sdkTestLastName';
        return $_;
    }

    my $contact = Yahoo::Marketing::APT::Contact->new
                                                ->email( 'test@yahoo-inc.com' )
                                                ->firstName( 'sdkTestFirstName' )
                                                ->isPrimary( 'true' )
                                                ->lastName( 'sdkTestLastName' )
                                                ->locale( 'en_US' )
                                                    ;

    my $response = $ysm_ws->addContactToManagedAccount( contact => $contact );

    if ( $response->operationSucceeded ne 'true' ) {
        croak( 'addContact failed' );
    }

    return $response->contact;
}


1;

