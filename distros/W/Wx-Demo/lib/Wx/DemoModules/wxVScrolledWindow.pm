#############################################################################
## Name:        lib/Wx/DemoModules/wxVScrolledWindow.pm
## Purpose:     wxPerl demo helper for Wx::VScrolledWindow
## Author:      Mattia Barbon
## Modified by:
## Created:     21/08/2007
## RCS-ID:      $Id: wxVScrolledWindow.pm 2812 2010-02-20 10:53:40Z mbarbon $
## Copyright:   (c) 2007 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxVScrolledWindow;

use strict;
use base qw(Wx::PlVScrolledWindow);
use Wx qw(wxWHITE wxHORIZONTAL wxVERTICAL);

sub log_scroll_event {
  my( $event, $type ) = @_;

  Wx::LogMessage( 'Scroll %s event: orientation = %s, position = %d', $type,
                  ( ( $event->GetOrientation == wxHORIZONTAL ) ? 'horizontal' : 'vertical' ),
                  $event->GetPosition );

  # important! skip event for default processing to happen
  $event->Skip;
}

use Wx::Event qw(/EVT_SCROLLWIN_*/ EVT_PAINT);

sub new {
  my( $class, $parent ) = @_;
  my $this = $class->SUPER::new( $parent, -1 );

  $this->SetRowCount( 100 );

  $this->SetBackgroundColour( wxWHITE );

  EVT_PAINT( $this, \&OnPaint );
  EVT_SCROLLWIN_TOP( $this,
                     sub { log_scroll_event( $_[1], 'to top' ) } );
  EVT_SCROLLWIN_BOTTOM( $this,
                        sub { log_scroll_event( $_[1], 'to bottom' ) } );
  EVT_SCROLLWIN_LINEUP( $this,
                        sub { log_scroll_event( $_[1], 'a line up' ) } );
  EVT_SCROLLWIN_LINEDOWN( $this,
                          sub { log_scroll_event( $_[1], 'a line down' ) } );
  EVT_SCROLLWIN_PAGEUP( $this,
                        sub { log_scroll_event( $_[1], 'a page up' ) } );
  EVT_SCROLLWIN_PAGEDOWN( $this,
                          sub { log_scroll_event( $_[1], 'a page down' ) } );
#  EVT_SCROLLWIN_THUMBTRACK( $this,
#                            sub { log_scroll_event( $_[1], 'thumbtrack' ) } );
  EVT_SCROLLWIN_THUMBRELEASE( $this,
                              sub { log_scroll_event( $_[1], 'thumbrelease' ) } );

  return $this;
}

sub _h { int( ( ( $_[0] % 3 ) / 2 + 1.5 ) * 25 ) }

*OnGetLineHeight = \&OnGetRowHeight; # for wxWidgets < 2.9
sub OnGetRowHeight {
    my( $this, $item ) = @_;

    return _h( $item );
}

use Wx qw(wxSOLID wxTRANSPARENT_PEN wxBLACK_PEN);

sub OnPaint {
  my( $this, $event ) = @_;
  my $dc = Wx::PaintDC->new( $this );

  $dc->SetPen( wxBLACK_PEN );

  my( $first, $last ) = ( $this->GetVisibleBegin, $this->GetVisibleEnd );
  my $w = $this->GetClientSize->x;

  my $y = 0;
  for my $i ( $first .. $last - 1 ) {
    my $c = 255 - ( $i % 3 ) * 60 * 255 / 100;
    my $h = _h( $i );
    $dc->SetBrush( Wx::Brush->new( Wx::Colour->new( $c, $c, $c ),
                                   wxSOLID ) );
    $dc->DrawRectangle( 0, $y, $w, $h + 1 );
    $y += $h;
  }
}

sub add_to_tags  { qw(windows) }
sub title { 'wxVScrolledWindow' }

1;
