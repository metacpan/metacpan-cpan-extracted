#############################################################################
## Name:        lib/Wx/DemoModules/wxTimePickerCtrl.pm
## Purpose:     wxPerl demo helper for Wx::TimePickerCtrl
## Author:      Mark Dootson
## Modified by:
## Created:     18/03/2012
## RCS-ID:      $Id: wxTimePickerCtrl.pm 3227 2012-03-18 05:22:05Z mdootson $
## Copyright:   (c) 2012 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use Wx::Calendar;

package Wx::DemoModules::wxTimePickerCtrl;

use strict;
use base qw(Wx::Panel);

use Wx qw(:sizer :timepicker :misc);
use Wx::Event qw(EVT_TIME_CHANGED);

sub new {
  my $class = shift;
  my $this = $class->SUPER::new( $_[0], -1 );

  my $sizer = Wx::BoxSizer->new( wxVERTICAL );
  
  my $date = Wx::DateTime->new();
    
  my $timepicker = Wx::TimePickerCtrl->new( $this, -1, $date, wxDefaultPosition, wxDefaultSize, wxTP_DEFAULT  );
  
  $timepicker->SetValue($date);


  my $textctrl = Wx::TextCtrl->new( $this, -1, $date->FormatTime );

  $sizer->Add( $timepicker, 0, wxALL, 10 );
  $sizer->Add( $textctrl, 0, wxGROW|wxALL, 10 );

  EVT_TIME_CHANGED( $this, $timepicker,
     sub {
           $textctrl->SetValue( 
				( $_[1]->GetDate->IsValid ) ? $_[1]->GetDate->FormatTime : 'INVALID TIME'
			);
		 }
  );

  $this->SetSizer( $sizer );

  return $this;
}

sub add_to_tags { qw(controls/picker) }
sub title { 'wxTimePickerCtrl' }

return defined(&Wx::TimePickerCtrl::new);
