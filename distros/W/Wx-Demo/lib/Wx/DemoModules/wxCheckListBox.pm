#############################################################################
## Name:        lib/Wx/DemoModules/wxCheckListBox.pm
## Purpose:     wxPerl demo helper for Wx::CheckListBox
## Author:      Mattia Barbon
## Modified by:
## Created:     13/03/2002
## RCS-ID:      $Id: wxCheckListBox.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2002, 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxCheckListBox;

use strict;
use base qw(Wx::CheckListBox);

use Wx qw(wxDefaultPosition wxDefaultSize);
use Wx::Event qw(EVT_CHECKLISTBOX);

sub new {
  my $class = shift;
  my $this = $class->SUPER::new( $_[0], -1, wxDefaultPosition,
                                 wxDefaultSize,
                                 [ qw(one two three four five size seven
                                      eight nine ten) ] );

  foreach my $i ( 0 .. 9 ) { $this->Check( $i, $i & 1 ) }

  EVT_CHECKLISTBOX( $this, $this, \&OnCheck );

  return $this;
}

sub OnCheck {
  my( $this, $event ) = @_;

  Wx::LogMessage( "Element %d toggled to %s", $event->GetInt(),
                  ( $this->IsChecked( $event->GetInt() ) ? 'checked' : 'unchecked' ) );
}

sub add_to_tags { qw(controls) }
sub title { 'wxCheckListBox' }

1;
