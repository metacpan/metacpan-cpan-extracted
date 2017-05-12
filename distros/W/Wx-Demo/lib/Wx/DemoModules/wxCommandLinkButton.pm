#############################################################################
## Name:        lib/Wx/DemoModules/wxCommandLinkButton.pm
## Purpose:     wxPerl demo helper for Wx::CommandLinkButton
## Author:      Mark Dootson
## Modified by:
## Created:     16 April 2013
## RCS-ID:      $Id: wxCommandLinkButton.pm 3480 2013-04-16 10:48:42Z mdootson $
## Copyright:   (c) 2013 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxCommandLinkButton;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:icon wxTheApp );
use Wx::Event qw(EVT_BUTTON);

__PACKAGE__->mk_accessors( qw( button ) );

sub commands {
    my( $self ) = @_;

    my @actions =
      (
        {
          with_value  => 1,
          label       => 'Set Main Label',
          action      => sub { $self->button->SetMainLabel( $_[0] ) },
        },
        {
          with_value  => 1,
          label       => 'Set Note',
          action      => sub { $self->button->SetNote( $_[0] ) },
        },
        
      );

    return @actions;
}

sub create_control {
    my( $self ) = @_;

    my $button = Wx::CommandLinkButton->new( $self, -1, 'Test Label', 'This is a longer note describing usage of the button' );

    EVT_BUTTON( $self, $button, \&on_click );

    return $self->button( $button );
}

sub on_click {
    my( $self, $event ) = @_;

    Wx::LogMessage( 'Command Link Button clicked' );
}

sub add_to_tags { qw(new controls) }
sub title { 'wxCommandLinkButton' }

1;
