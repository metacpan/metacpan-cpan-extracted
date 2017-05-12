#############################################################################
## Name:        lib/Wx/DemoModules/wxFileDialog.pm
## Purpose:     wxPerl demo helper for Wx::FileDialog
## Author:      Mattia Barbon
## Modified by:
## Created:     11/02/2001
## RCS-ID:      $Id: wxFileDialog.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2001, 2003, 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxFileDialog;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:id :filedialog);

__PACKAGE__->mk_accessors( qw(previous_directory previous_file) );

sub commands {
    my( $self ) = @_;

    return ( { label       => 'File dialog',
               action      => \&file_dialog,
               },
               );
}

sub file_dialog {
    my( $self ) = @_;
    my $dialog = Wx::FileDialog->new
      ( $self, "Select a file", $self->previous_directory || '',
        $self->previous_file || '',
        ( join '|', 'BMP files (*.bmp)|*.bmp', 'Text files (*.txt)|*.txt',
                    'Foo files (*.foo)|*.foo', 'All files (*.*)|*.*' ),
        wxFD_OPEN|wxFD_MULTIPLE );

    if( $dialog->ShowModal == wxID_CANCEL ) {
        Wx::LogMessage( "User cancelled the dialog" );
    } else {
        Wx::LogMessage( "Wildcard: %s", $dialog->GetWildcard);
        my @paths = $dialog->GetPaths;

        if( @paths > 0 ) {
            Wx::LogMessage( "File: $_" ) foreach @paths;
        } else {
            Wx::LogMessage( "No files" );
        }

        $self->previous_directory( $dialog->GetDirectory );
    }

    $dialog->Destroy;
}

sub add_to_tags { qw(dialogs) }
sub title { 'wxFileDialog' }

1;
