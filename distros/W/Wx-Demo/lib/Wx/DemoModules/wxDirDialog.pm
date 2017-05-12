#############################################################################
## Name:        lib/Wx/DemoModules/wxDirDialog.pm
## Purpose:     wxPerl demo helper for Wx::DirDialog
## Author:      Mattia Barbon
## Modified by:
## Created:     11/02/2001
## RCS-ID:      $Id: wxDirDialog.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2001, 2003, 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxDirDialog;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:id);

sub commands {
    my( $self ) = @_;

    return ( { label       => 'Directory dialog',
               action      => \&dir_dialog,
               },
               );
}

sub dir_dialog {
  my( $this ) = @_;

  my $dialog = Wx::DirDialog->new( $this );

  if( $dialog->ShowModal == wxID_CANCEL ) {
    Wx::LogMessage( "User cancelled the dialog" );
  } else {
    Wx::LogMessage( "Directory: %s", $dialog->GetPath );
  }

  $dialog->Destroy;
}

sub add_to_tags { qw(dialogs) }
sub title { 'wxDirDialog' }

1;
