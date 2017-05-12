#############################################################################
## Name:        lib/Wx/DemoModules/wxInfobar.pm
## Purpose:     wxPerl demo helper for Wx::InfoBar
## Author:      Mark Dootson
## Modified by:
## Created:     18/03/2012
## RCS-ID:      $Id: wxInfoBar.pm 3231 2012-03-19 05:32:11Z mdootson $
## Copyright:   (c) 2012 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxInfoBar;
use Wx;
use strict;
use base qw(Wx::Panel);
use Wx qw(:sizer :misc :id wxICON_INFORMATION );
use Wx::Event qw( EVT_BUTTON );

sub new {
  my $class = shift;
  my $self = $class->SUPER::new( $_[0], -1 );
  
  my $db = Wx::Button->new($self, wxID_ANY, 'Show InfoBar');
  
  EVT_BUTTON($self, $db, sub { shift->OnDefaultButtons( @_ ); });
  
  $self->{infobar} = Wx::DemoModules::wxInfoBar::InfoBar->new($self);
  
  my $sizer = Wx::BoxSizer->new( wxVERTICAL );
  my $buttonsizer = Wx::BoxSizer->new( wxHORIZONTAL );
  
  $buttonsizer->Add( $db, 0, wxALL, 3 );
  
  $sizer->Add($buttonsizer, 0, wxEXPAND|wxALL, 0);
  $sizer->Add(Wx::StaticText->new($self,wxID_ANY,'Something to fill the space'), 1, wxEXPAND|wxALL, 20);
  $sizer->Add($self->{infobar}, 0, wxEXPAND|wxALL, 0);
  $self->SetSizerAndFit( $sizer );
  return $self;
}

sub OnDefaultButtons {
  my( $self, $event ) = @_;
  $self->{infobar}->ShowMessage(
"This is an information message that you want the user to
act on without interrupting program flow with a modal dialog.",
	wxICON_INFORMATION);
}

sub add_to_tags { qw(controls new) }
sub title { 'wxInfoBar' }


package Wx::DemoModules::wxInfoBar::InfoBar;
use Wx qw( :id );
use strict;
use base qw(Wx::InfoBar);
use Wx::Event qw( EVT_BUTTON );

sub new {
  my $class = shift;
  my $self = $class->SUPER::new( @_ );
  
  EVT_BUTTON($self, wxID_ANY, sub { shift->OnButtonClicked( @_ ); });
  
  return $self;
}

sub OnButtonClicked {
  my ($self, $event) = @_;
  
  Wx::LogMessage('Default Close Button Clicked' );
 
  $self->Dismiss;
  $self->GetParent->Refresh;
}

return defined(&Wx::InfoBar::new);
