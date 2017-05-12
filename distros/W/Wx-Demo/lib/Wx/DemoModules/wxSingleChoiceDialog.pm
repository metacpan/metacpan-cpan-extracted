#############################################################################
## Name:        lib/Wx/DemoModules/wxSingleChoiceDialog.pm
## Purpose:     wxPerl demo helper for Wx::SingleChoiceDialog
## Author:      Mattia Barbon
## Modified by:
## Created:     11/02/2001
## RCS-ID:      $Id: wxSingleChoiceDialog.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2001, 2003, 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxSingleChoiceDialog;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:id);

sub commands {
    my( $self ) = @_;

    return ( { label       => 'Single choice dialog',
               action      => \&single_choice_dialog,
               },
             { label       => 'Get single choice (index)',
               action      => \&get_single_choice_index,
               },
             { label       => 'Get single choice (string)',
               action      => \&get_single_choice_string,
               },
             { label       => 'Get single choice (data)',
               action      => \&get_single_choice_data,
               },
               );
}

my $choices = [ 'Apple', 'Orange', 'Banana', 'Pear', 'Cranberry' ];
my $data = [ '1 - apple', '2 - orange', '3 - banana', '4 - pear',
             '5 - cranberry' ];

sub get_single_choice_string {
    my( $self ) = @_;
    my $string = Wx::GetSingleChoice( 'Make a choice', 'Choose',
                                      $choices, $self );

    Wx::LogMessage( "The choice is: '%s'", $string );
}

sub get_single_choice_index {
    my( $self ) = @_;
    my $index = Wx::GetSingleChoiceIndex( 'Make a choice', 'Choose',
                                          $choices, $self );

    Wx::LogMessage( "The choice is: %d", $index );
}

sub get_single_choice_data {
    my( $self ) = @_;
    my $clientdata = Wx::GetSingleChoiceData( 'Make a choice', 'Choose',
                                              $choices, $data, $self );

    Wx::LogMessage( "The choice is: '%s'", $clientdata );
}

sub single_choice_dialog {
  my( $this ) = @_;
  my $dialog = Wx::SingleChoiceDialog->new
    ( $this, "Make a choice", "Choose", $choices, $data );

  if( $dialog->ShowModal == wxID_CANCEL ) {
    Wx::LogMessage( "User cancelled the dialog" );
  } else {
    Wx::LogMessage( "Selection: %d", $dialog->GetSelection );
    Wx::LogMessage( "String: %s", $dialog->GetStringSelection );
    Wx::LogMessage( "Client data: %s", $dialog->GetSelectionClientData );
  }

  $dialog->Destroy;
}

sub add_to_tags { qw(dialogs) }
sub title { 'wxSingleChoiceDialog' }

1;
