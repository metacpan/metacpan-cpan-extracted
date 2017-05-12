#############################################################################
## Name:        lib/Wx/DemoModules/wxColourDialog.pm
## Purpose:     wxPerl demo helper for Wx::ColourDialog
## Author:      Mattia Barbon
## Modified by:
## Created:     11/02/2001
## RCS-ID:      $Id: wxColourDialog.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2001, 2003, 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxColourDialog;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:id);

sub commands {
    my( $self ) = @_;

    return ( { label       => 'Colour dialog',
               action      => \&colour_dialog,
               },
               );
}

sub colour_dialog {
  my( $this ) = @_;

  my $data = Wx::ColourData->new;
  $data->SetChooseFull( 1 );

  my $dialog = Wx::ColourDialog->new( $this, $data );

  if( $dialog->ShowModal == wxID_CANCEL ) {
    Wx::LogMessage( "User cancelled the dialog" );
  } else {
    my $data = $dialog->GetColourData;
    my $colour = $data->GetColour;

    Wx::LogMessage( "Colour: (%d, %d, %d)", $colour->Red,
                    $colour->Green, $colour->Blue );
  }

  $dialog->Destroy;
}

sub add_to_tags { qw(dialogs) }
sub title { 'wxColourDialog' }

1;
