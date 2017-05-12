#############################################################################
## Name:        lib/Wx/DemoModules/wxPasswordEntryDialog.pm
## Purpose:     wxPerl demo helper for Wx::PasswordEntryDialog
## Author:      Mattia Barbon
## Modified by:
## Created:     26/08/2007
## RCS-ID:      $Id: wxPasswordEntryDialog.pm 2812 2010-02-20 10:53:40Z mbarbon $
## Copyright:   (c) 2007 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxPasswordEntryDialog;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:id);

sub commands {
    my( $self ) = @_;

    return ( { label       => 'Password entry dialog',
               action      => \&text_entry_dialog,
               },
               );
}

sub text_entry_dialog {
  my( $this ) = @_;
  my $dialog = Wx::PasswordEntryDialog->new
    ( $this, "Enter some text", "Wx::PasswordEntryDialog sample",
      "s3cr3t" );

  if( $dialog->ShowModal == wxID_CANCEL ) {
    Wx::LogMessage( "User cancelled the dialog" );
  } else {
    Wx::LogMessage( "Password: %s", $dialog->GetValue );
  }

  $dialog->Destroy;
}

sub add_to_tags { qw(dialogs) }
sub title { 'wxPasswordEntryDialog' }

defined &Wx::PasswordEntryDialog::new;
