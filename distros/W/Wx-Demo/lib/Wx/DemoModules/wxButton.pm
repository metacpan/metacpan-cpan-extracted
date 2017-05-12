#############################################################################
## Name:        lib/Wx/DemoModules/wxButton.pm
## Purpose:     wxPerl demo helper for Wx::Button
## Author:      Mattia Barbon
## Modified by:
## Created:     13/03/2011
## RCS-ID:      $Id: wxButton.pm 3031 2011-03-13 09:54:41Z mbarbon $
## Copyright:   (c) 2011 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxButton;

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

    my @actions =
      ( { with_value  => 1,
          label       => 'Set label',
          action      => sub { $self->button->SetLabel( $_[0] ) },
          } );

    if( Wx::wxVERSION >= 2.009001 ) {
        push @actions,
          ( { label       => 'Clear bitmap',
              action      => sub { $self->button->SetBitmapLabel( $null ) },
              },
            { label       => 'Set bitmap',
              action      => sub { $self->button->SetBitmapLabel( $bmp1 ) },
              },
            { label       => 'Clear selected bitmap',
              action      => sub { $self->button->SetBitmapCurrent( $null ) },
              },
            { label       => 'Set selected bitmap',
              action      => sub { $self->button->SetBitmapCurrent( $bmp2 ) },
              },
            { label       => 'Clear focus bitmap',
              action      => sub { $self->button->SetBitmapFocus( $null ) },
              },
            { label       => 'Set focus bitmap',
              action      => sub { $self->button->SetBitmapFocus( $bmp3 ) },
              } );
    }

    return @actions;
}

sub create_control {
    my( $self ) = @_;

    my $button = Wx::Button->new( $self, -1, 'Test' );

    EVT_BUTTON( $self, $button, \&on_click );

    return $self->button( $button );
}

sub on_click {
    my( $self, $event ) = @_;

    Wx::LogMessage( 'Button clicked' );
}

sub add_to_tags { qw(controls) }
sub title { 'wxButton' }

1;
