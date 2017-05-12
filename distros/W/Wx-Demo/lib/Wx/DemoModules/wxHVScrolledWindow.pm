#############################################################################
## Name:        lib/Wx/DemoModules/wxHVScrolledWindow.pm
## Purpose:     wxPerl demo helper for Wx::HVScrolledWindow
## Author:      Mattia Barbon
## Modified by:
## Created:     21/08/2007
## RCS-ID:      $Id: wxHVScrolledWindow.pm 2920 2010-04-29 21:11:27Z mbarbon $
## Copyright:   (c) 2007 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxHVScrolledWindow;

use strict;
use Wx qw(wxWHITE wxHORIZONTAL wxVERTICAL);
use Wx::Event qw(EVT_PAINT);

use base (Wx::wxVERSION() >= 2.009 ) ? qw(Wx::PlHVScrolledWindow) : qw( Wx::Window );
# Wx::HVScrolledWindow is for wxWidgets 2.9.0
# Simply won't be loaded on lower Wx::Widgets (see sub add_to_tags )

sub new {
  my( $class, $parent ) = @_;
  my $this = $class->SUPER::new( $parent, -1 );

  $this->SetRowColumnCount( 100, 100 );

  $this->SetBackgroundColour( wxWHITE );

  EVT_PAINT( $this, \&OnPaint );

  $this->ScrollToRowColumn( Wx::Position->new( 50, 50 ) );

  return $this;
}

sub _w { int( ( ( 2 - $_[0] % 3 ) / 2 + 1.5 ) * 25 ) }
sub _h { int( ( ( $_[0] % 3 ) / 2 + 1.5 ) * 25 ) }

sub OnGetColumnWidth {
    my( $this, $item ) = @_;

    return _w( $item );
}

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

  my $y = 0;
  for my $r ( $first->GetRow .. $last->GetRow - 1 ) {
    my $h = _h( $r );
    my $x = 0;
    for my $c ( $first->GetColumn .. $last->GetColumn - 1 ) {
      my $w = _w( $c );
      my $c = 255 - ( $r % 3 + $c % 3 ) * 60 * 255 / 100;
      $dc->SetBrush( Wx::Brush->new( Wx::Colour->new( $c, $c, $c ),
                                     wxSOLID ) );
      $dc->DrawRectangle( $x, $y, $w + 1, $h + 1 );
      $x += $w;
    }
    $y += $h;
  }
}

sub add_to_tags  { ( Wx::wxVERSION() >= 2.009 ) ? qw(windows) : () }
sub title { 'wxHVScrolledWindow' }

1;
