#############################################################################
## Name:        lib/Wx/DemoModules/wxMultiChoiceDialog.pm
## Purpose:     wxPerl demo helper for Wx::MultiChoiceDialog
## Author:      Mattia Barbon
## Modified by:
## Created:     11/02/2001
## RCS-ID:      $Id: wxMultiChoiceDialog.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2001, 2003, 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxMultiChoiceDialog;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:id);

sub commands {
    my( $self ) = @_;

    return ( { label       => 'Multiple choice dialog',
               action      => \&multiple_choice_dialog,
               },
             { label       => 'Get multiple choice (string)',
               action      => \&get_multiple_choice_string,
               },
               );
}

my $choices = [ 'Apple', 'Orange', 'Banana', 'Pear', 'Cranberry' ];
my $data = [ '1 - apple', '2 - orange', '3 - banana', '4 - pear',
             '5 - cranberry' ];

sub get_multiple_choice_string {
    my( $self ) = @_;
    my @strings = Wx::GetMultipleChoices( 'Make some choices', 'Choose',
                                          $choices, $self );

    Wx::LogMessage( "The choices are: %s", join ", ", @strings );
}

sub multiple_choice_dialog {
  my( $this ) = @_;
  my $dialog = Wx::MultiChoiceDialog->new
    ( $this, "Make a choice", "Choose", $choices );

  if( $dialog->ShowModal == wxID_CANCEL ) {
    Wx::LogMessage( "User cancelled the dialog" );
  } else {
    my @strings = $dialog->GetSelections;
    Wx::LogMessage( "The choices are: %s", join ", ", @strings );
  }

  $dialog->Destroy;
}

sub add_to_tags { qw(dialogs) }
sub title { 'wxMultiChoiceDialog' }

1;
