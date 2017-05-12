#############################################################################
## Name:        lib/Wx/DemoModules/wxSplashScreen.pm
## Purpose:     wxPerl demo helper
## Author:      Mattia Barbon
## Modified by:
## Created:     28/08/2002
## RCS-ID:      $Id: wxSplashScreen.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2002, 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxSplashScreen;

use strict;
use base qw(Wx::Panel);

use Wx qw(:splashscreen wxBITMAP_TYPE_JPEG);
use Wx::Event qw(EVT_BUTTON);

use File::chdir;

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent );

    my $splash = Wx::Button->new( $self, -1, 'Splash Screen', [ 10, 10 ] );
    my $splashfast = Wx::Button->new( $self, -1, 'Splash Fast', [ 150, 10 ] );

    EVT_BUTTON( $self, $splash, \&on_splash );
    EVT_BUTTON( $self, $splashfast, \&on_splash_fast );

    return $self;
}

sub on_splash {
    my( $self, $event ) = @_;
    my $logo_file = Wx::Demo->get_data_file( 'splash/logo.jpg' );

    my $bitmap = Wx::Bitmap->new( $logo_file, wxBITMAP_TYPE_JPEG );

    Wx::SplashScreen->new( $bitmap,
                           wxSPLASH_CENTRE_ON_SCREEN|wxSPLASH_TIMEOUT,
                           5000, undef, -1 );
}

sub on_splash_fast {
    my( $self, $event ) = @_;
    my $splash_pl = Wx::Demo->get_data_file( 'splash/splash.pl' );

    local $CWD = File::Basename::dirname( $splash_pl );
    Wx::ExecuteCommand( "$^X splash.pl", 0 );
}

sub add_to_tags { qw(managed) }
sub title { 'wxSplashScreen' }

1;
