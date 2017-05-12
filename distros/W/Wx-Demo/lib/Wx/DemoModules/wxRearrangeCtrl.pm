#############################################################################
## Name:        lib/Wx/DemoModules/wxRearrangeCtrl.pm
## Purpose:     wxPerl demo helper for Wx::RearrangeCtrl
## Author:      Mark Dootson
## Modified by:
## Created:     20/09/2012
## RCS-ID:      $Id: wxRearrangeCtrl.pm 3398 2012-09-30 02:27:48Z mdootson $
## Copyright:   (c) 2012 Mark Dootson
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxRearrangeCtrl;
use Wx;
use strict;
use base qw(Wx::Panel);
use Wx qw(:sizer :misc :id wxID_CANCEL );
use Wx::Event qw( EVT_BUTTON );

sub new {
  my $class = shift;
  my $self = $class->SUPER::new( $_[0], -1 );
  
  
  $self->{listctrl} = Wx::DemoModules::wxRearrangeCtrl::Control->new($self);
  $self->{dbutton} = Wx::Button->new($self, wxID_ANY, qq(Use WX::RearrangeDialog));
  
  EVT_BUTTON($self, $self->{dbutton}, 'OnDialogButton');
  
  my $sizer = Wx::BoxSizer->new( wxVERTICAL );
  $sizer->Add($self->{listctrl}, 1, wxEXPAND|wxALL, 0);
  my $buttonsizer = Wx::BoxSizer->new( wxHORIZONTAL );
  $buttonsizer->Add($self->{dbutton}, 0, wxALL,0);
  $sizer->Add(Wx::StaticLine->new($self, wxID_ANY), 0, wxEXPAND|wxTOP|wxBOTTOM, 5);
  $sizer->Add($buttonsizer, 0, wxALIGN_LEFT, 10);
  $self->SetSizerAndFit( $sizer );
  return $self;
}

sub add_to_tags { qw(controls dialogs new) }
sub title { 'wxRearrangeCtrl' }

sub OnDialogButton {
  my ($self, $event) = @_;
  my @choices = @{ $self->{listctrl}->get_choices };
  my @order = $self->{listctrl}->GetList->GetCurrentOrder;
  my $dlg = Wx::RearrangeDialog->new($self, 'Rearrange and Check / Uncheck the items',
	'Wx::RearrangeDialog', \@order, \@choices);
  my $result = $dlg->ShowModal();
  my @neworder = $dlg->GetOrder;
  $dlg->Destroy;
  Wx::LogMessage( "Dialog Order" );
  unless($result == wxID_CANCEL) {
	for my $indicator ( @neworder ) {
	  my $index = ( $indicator < 0 ) ? -1 * ( $indicator + 1 ) : $indicator;
	  my $checked = ( $indicator < 0 ) ? 'Unchecked' : 'Checked';
	  Wx::LogMessage( "Item : %s is %s", $choices[$index], $checked);
	}
  }
}

package Wx::DemoModules::wxRearrangeCtrl::Control;
use Wx qw( :id :misc );
use strict;
use base qw(Wx::RearrangeCtrl);

sub new {
  my ($class, $parent ) = @_;
  
  my @choices = qw( First Second Third Fourth Fifth Sixth Seventh Eighth Ninth Tenth);
  my @ordercheck = ( 0, 1, 2, -4, 4, 5, -7, -8, 8, 9);
  my $self = $class->SUPER::new($parent, wxID_ANY,
	  wxDefaultPosition, wxDefaultSize, \@ordercheck, \@choices);
  
  $self->{choices} = \@choices;
  
  return $self;
}

sub get_choices { $_[0]->{choices}; }

return defined(&Wx::RearrangeCtrl::new);
