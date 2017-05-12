#############################################################################
## Name:        lib/Wx/DemoModules/wxBitmapButton.pm
## Purpose:     wxPerl demo helper for Wx::BitmapButton
## Author:      Mattia Barbon
## Modified by:
## Created:     13/08/2006
## RCS-ID:      $Id: wxBitmapButton.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2000, 2003, 2005-2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxBitmapButton;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:icon wxTheApp wxNullBitmap);
use Wx::Event qw(EVT_BUTTON);

__PACKAGE__->mk_accessors( qw(button) );

sub commands {
    my( $self ) = @_;

    my $bmp1 = Wx::Bitmap->new( wxTheApp->GetStdIcon( wxICON_INFORMATION ) );
    my $bmp2 = Wx::Bitmap->new( wxTheApp->GetStdIcon( wxICON_WARNING ) );
    my $bmp3 = Wx::Bitmap->new( wxTheApp->GetStdIcon( wxICON_QUESTION ) );
    my $null = wxNullBitmap;

    return ( { label       => 'Clear bitmap',
               action      => sub { $self->button->SetBitmapLabel( $null ) },
               },
             { label       => 'Set bitmap',
               action      => sub { $self->button->SetBitmapLabel( $bmp1 ) },
               },
             { label       => 'Clear selected bitmap',
               action      => sub { $self->button->SetBitmapSelected( $null ) },
               },
             { label       => 'Set selected bitmap',
               action      => sub { $self->button->SetBitmapSelected( $bmp2 ) },
               },
             { label       => 'Clear focus bitmap',
               action      => sub { $self->button->SetBitmapFocus( $null ) },
               },
             { label       => 'Set focus bitmap',
               action      => sub { $self->button->SetBitmapFocus( $bmp3 ) },
               },
               );
}

sub create_control {
    my( $self ) = @_;

    my $bmp1 = Wx::Bitmap->new( wxTheApp->GetStdIcon( wxICON_INFORMATION ) );
    my $bmp2 = Wx::Bitmap->new( wxTheApp->GetStdIcon( wxICON_WARNING ) );
    my $bmp3 = Wx::Bitmap->new( wxTheApp->GetStdIcon( wxICON_QUESTION ) );

    my $button = Wx::BitmapButton->new( $self, -1, $bmp1, [-1, -1] );
    $button->SetBitmapSelected( $bmp2 );
    $button->SetBitmapFocus( $bmp3 );

    EVT_BUTTON( $self, $button, \&on_click );

    return $self->button( $button );
}

sub on_click {
    my( $self, $event ) = @_;

    Wx::LogMessage( 'Button clicked' );
}

sub add_to_tags { qw(controls) }
sub title { 'wxBitmapButton' }

1;
