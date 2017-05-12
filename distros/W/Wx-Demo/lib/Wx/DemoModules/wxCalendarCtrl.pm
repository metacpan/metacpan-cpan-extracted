#############################################################################
## Name:        lib/Wx/DemoModules/wxCalendarCtrl.pm
## Purpose:     wxPerl demo helper for Wx::CalendarCtrl
## Author:      Mattia Barbon
## Modified by:
## Created:     11/10/2002
## RCS-ID:      $Id: wxCalendarCtrl.pm 3118 2011-11-18 09:58:12Z mdootson $
## Copyright:   (c) 2002-2003, 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use Wx::Calendar;

package Wx::DemoModules::wxCalendarCtrl;

use strict;
use base qw(Wx::Panel);

use Wx qw(:sizer :calendar wxDefaultPosition wxDefaultSize wxRED wxBLUE);
use Wx::Event qw(EVT_CALENDAR_SEL_CHANGED);

sub new {
  my $class = shift;
  my $this = $class->SUPER::new( $_[0], -1 );

  my $sizer = Wx::BoxSizer->new( wxVERTICAL );

  #                                    8 Jan 1979
  my $date = Wx::DateTime->newFromDMY( 8, 0, 1979 );

  my $calendar = Wx::CalendarCtrl->new( $this, -1, $date );

  my $textctrl = Wx::TextCtrl->new( $this, -1, $date->FormatDate );

  $sizer->Add( $calendar, 0, wxALL, 10 );
  $sizer->Add( $textctrl, 0, wxGROW|wxALL, 10 );
  
  # EnableYearChange not available on native controls
  $calendar->EnableYearChange if $calendar->can('EnableYearChange');
  $calendar->EnableMonthChange;

  # test attributes
  my $attr = Wx::CalendarDateAttr->new;
  $attr->SetTextColour( wxRED );
  $attr->SetBorderColour( wxBLUE );
  $attr->SetBorder( wxCAL_BORDER_ROUND );

  $calendar->SetAttr( 2, $attr );
  $calendar->SetAttr( 3, $attr );
  $calendar->SetAttr( 4, $attr );

  EVT_CALENDAR_SEL_CHANGED( $this, $calendar,
                            sub {
                              my( $self, $event ) = @_;

                              $textctrl->SetValue
                                ( $event->GetDate->FormatDate );
                            } );

  $this->SetSizer( $sizer );

  return $this;
}

sub add_to_tags { qw(controls) }
sub title { 'wxCalendarCtrl' }

1;
