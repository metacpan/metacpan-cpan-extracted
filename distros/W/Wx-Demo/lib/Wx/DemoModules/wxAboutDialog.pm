#############################################################################
## Name:        lib/Wx/DemoModules/wxAboutDialog.pm
## Purpose:     wxPerl demo helper for Wx::AboutDialog
## Author:      Mattia Barbon
## Modified by:
## Created:     23/08/2007
## RCS-ID:      $Id: wxAboutDialog.pm 2812 2010-02-20 10:53:40Z mbarbon $
## Copyright:   (c) 2007 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxAboutDialog;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:id);

sub commands {
    my( $self ) = @_;

    return ( { label       => 'Simple about dialog',
               action      => \&simple_about_dialog,
               },
             { label       => 'Complex about dialog',
               action      => \&complex_about_dialog,
               },
               );
}

sub simple_about_dialog {
    my( $self ) = @_;
    my $info = Wx::AboutDialogInfo->new;

    $info->SetName( 'The wxPerl demo' );
    $info->SetVersion( '0.01 alpha 12' );
    $info->SetDescription( 'The cool and pluggable wxPerl demo' );
    $info->SetCopyright( '(c) 2001-today Me <me@test.com>' );

    Wx::AboutBox( $info );
}

sub complex_about_dialog {
    my( $self ) = @_;
    my $info = Wx::AboutDialogInfo->new;

    $info->SetName( 'The wxPerl demo' );
    $info->SetVersion( '0.01 alpha 12' );
    $info->SetDescription( 'The cool and pluggable wxPerl demo' );
    $info->SetCopyright( '(c) 2001-today Me <me@test.com>' );
    $info->SetWebSite( 'http://wxperl.eu/', 'The wxPerl demo web site' );
    $info->AddDeveloper( 'Mattia Barbon <mbarbon@cpan.org>' );
    $info->AddDeveloper( 'I wish there was somebody else...' );

    $info->SetArtists( [ 'Unluckily', 'none', 'so', 'the',
                         'graphic', 'is', 'bad' ] );

    Wx::AboutBox( $info );
}

sub add_to_tags { qw(dialogs) }
sub title { 'wxAboutDialog' }

defined &Wx::AboutBox ? 1 : 0;

