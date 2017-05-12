#############################################################################
## Name:        lib/Wx/DemoModules/wxOverlay.pm
## Purpose:     Overlay demo
## Author:      Mark Dootson
## Modified by:
## Created:     06 Feb 2010
## RCS-ID:      $Id: wxOverlay.pm 3450 2013-03-30 04:03:16Z mdootson $
## Copyright:   (c) 2010 Mark Dootson
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxOverlay;
use strict;
use Wx 0.97;
use Wx qw( :misc :window :panel :sizer);
use base qw( Wx::Panel );

sub add_to_tags { qw( misc ) }
sub title { 'wxOverlay' }

sub new {
  my $class = shift;
  my $parent = shift;
  my $self = $class->SUPER::new($parent, -1, wxDefaultPosition, wxDefaultSize, wxBORDER_NONE);
  my $sizer = Wx::BoxSizer->new(wxVERTICAL);
  my $canvas = Wx::DemoModules::wxOverlay::Canvas->new($self);
  $sizer->Add($canvas, 1, wxGROW);
  $self->SetSizer($sizer);
  return $self;
}

package Wx::DemoModules::wxOverlay::Canvas;

use strict;
use Wx qw(:sizer :cursor :colour :pen :brush :font wxSYS_SYSTEM_FONT wxSYS_DEFAULT_GUI_FONT wxSYS_OEM_FIXED_FONT :window :misc );
use Wx::Event qw(EVT_MOTION EVT_LEFT_DOWN EVT_LEFT_UP EVT_PAINT);

use base qw(Wx::ScrolledWindow);

my $penwidth = 2;

use vars qw($x_size $y_size);

( $x_size, $y_size ) = ( 1200, 1000 );

sub new {
  my $class = shift;
  my $parent = shift;
  my $this = $class->SUPER::new( $parent, -1 );
  $this->SetVirtualSize(  $x_size, $y_size  );
  $this->SetScrollRate( 1, 1 );
  $this->SetBackgroundColour( wxWHITE );
  $this->SetCursor( Wx::Cursor->new( wxCURSOR_PENCIL ) );
  $this->{overlay} = Wx::Overlay->new;
  
  EVT_MOTION( $this, \&OnMouseMove );
  EVT_LEFT_DOWN( $this, \&OnButton );
  EVT_LEFT_UP( $this, \&OnButton );
  EVT_PAINT( $this, \&OnPaint );
  return $this;
}

my ($usegctx, $usegcdc);
if(defined(&Wx::GraphicsContext::Create)) {
  
  $usegcdc = (($Wx::VERSION > 0.965) && (Wx::wxVERSION > 2.0080075));
  $usegctx = ( $usegcdc ) ? 0 : 1;
}

# GraphicsContext problems on wxGTK if no wxGCDC
$usegctx = 0 if Wx::wxGTK;

sub OnPaint {
  my $this = shift;
  my $dcnew = Wx::PaintDC->new( $this );
  my $pen   = Wx::Pen->new( wxRED, $penwidth, wxSOLID );
  my $brush = Wx::Brush->new(Wx::Colour->new(255, 192, 192, 127 ), wxSOLID );
  
  my $font = wxSMALL_FONT;
  # This line needed to init the font on MSW with public domain GDIPlus headers (mingw)
  $font->GetFaceName;
  
  my $drawdc = ( $usegcdc ) ? Wx::GCDC->new( $dcnew ) : $dcnew;
  $this->PrepareDC( $drawdc );
  if($usegctx) {
   
    my $ctx = Wx::GraphicsContext::Create( $dcnew );
    $ctx->SetBrush( $brush );
    $ctx->SetPen( $pen );
    foreach my $i ( @{$this->{RECTS}} ) {
      $ctx->DrawRectangle( $i->x, $i->y, $i->width, $i->height );
    }
    $ctx->SetFont( $font, wxBLACK );
    $ctx->DrawText('Drag the pointer to create rectangles',20,20);
    $ctx->DrawText('Using GraphicsContext',20,50);
  } else {
    
    $drawdc->SetPen( $pen );
    $drawdc->SetBrush ( $brush );
    foreach my $i ( @{$this->{RECTS}} ) {
      $drawdc->DrawRectangle( $i->x, $i->y, $i->width, $i->height );
    }
    $drawdc->SetFont( $font );
    $drawdc->DrawText('Drag the pointer to create rectangles',20,20);
    my $text = ($usegcdc) ? 'Using Graphics CTX Based Wx::GCDC' : 'Using Standard Wx::DC';
    $drawdc->DrawText($text ,20,50);
  }
}

sub OnMouseMove {
  my( $this, $event ) = @_;

  return unless $event->Dragging;
  return unless($this->{START_POINT});
  
  my $dc = Wx::ClientDC->new( $this );
  my $overlaydc = Wx::DCOverlay->new($this->{overlay}, $dc);
  $overlaydc->Clear;
  
  $this->PrepareDC( $dc ); # as this is a ScrolledWindow
  
  my $pen   = Wx::Pen->new( wxBLACK, 1, wxSHORT_DASH );
  my $brush = wxTRANSPARENT_BRUSH;
  #my $font  = Wx::SystemSettings::GetFont( wxSYS_SYSTEM_FONT );
  
  $dc->SetPen( $pen );
  $dc->SetBrush ( $brush );
  #$dc->SetFont( $font );
 
  my $pos = $event->GetLogicalPosition( $dc );
  my( $x, $y ) = ( $pos->x, $pos->y );
 
  my $width  =  $x - $this->{START_POINT}->[0];
  my $height =  $y - $this->{START_POINT}->[1];
  
  
  $dc->DrawRectangle( @{ $this->{START_POINT} }, $width, $height );
  #my $sztext = qq($x, $y, : $width x $height);
  #my $textposx = ( $width >= 0 ) ? $this->{START_POINT}->[0] : $x;
  #my $textposy = ( $height >= 0 ) ? $this->{START_POINT}->[1] : $y;
  #$dc->DrawText($sztext, $textposx, $textposy);

}

sub OnButton {
  my( $this, $event ) = @_;

  my $dc = Wx::ClientDC->new( $this );
  $this->PrepareDC( $dc );
  my $pos = $event->GetLogicalPosition( $dc );
  my( $x, $y ) = ( $pos->x, $pos->y );
  if( $event->LeftUp ) {
   
    if ($this->{START_POINT}) {
      my $width  =  $x - $this->{START_POINT}->[0];
      my $height =  $y - $this->{START_POINT}->[1];
      
      # graphics context doesn't like negative width / height
      if( $width < 0 ) {
        $width = abs($width);
        $this->{START_POINT}->[0] -= $width;
      }
      if( $height < 0 ) {
        $height = abs($height);
        $this->{START_POINT}->[1] -= $height;
      }
      
      my $rec = Wx::Rect->new( @{ $this->{START_POINT} }, $width, $height);
      push(@{ $this->{RECTS} }, $rec);
      $this->{START_POINT} = undef;
    
    
      # set a clipping rect  but we must convert for scrolling and width of pen
      my ($clipx, $clipy) = $this->CalcScrolledPosition($rec->x - $penwidth, $rec->y - $penwidth);
    
      my $clip = Wx::Rect->new(
        $clipx, $clipy, $rec->width + $penwidth + 1, $rec->height + $penwidth + 1
      );
    
      $this->Refresh(1, $clip ); # rewdraws the necessary part of underlying window
    }
    
    $this->ReleaseMouse();
    $this->{overlay}->Reset; # drops internally held pointers/refs
    
  } elsif( $event->LeftDown) {
    $this->{START_POINT} = [ $x, $y ];
    $this->CaptureMouse();
  }

}

eval { my $olay = Wx::Overlay->new; };
( $@ ) ? 0 : 1;


