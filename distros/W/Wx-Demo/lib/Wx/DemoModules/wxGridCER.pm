#############################################################################
## Name:        lib/Wx/DemoModules/wxGridCER.pm
## Purpose:     wxPerl demo hlper for wxGrid custom editors and renderers
## Author:      Mattia Barbon
## Modified by:
## Created:     05/06/2003
## RCS-ID:      $Id: wxGridCER.pm 2378 2008-04-26 04:21:45Z mdootson $
## Copyright:   (c) 2003, 2005-2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxGridCER;

use strict;
use base qw(Wx::Grid);

sub new {
  my $class = shift;
  my $this = $class->SUPER::new( $_[0], -1 );

  $this->CreateGrid( 3, 7 );
  # set every cell read-only
  for my $x ( 1 .. 7 ) {
    for my $y ( 1 .. 3 ) {
      $this->SetReadOnly( $y, $x, 1 ); # rows, cols
    }
  }

  $this->SetColSize( 0, 20 );
  $this->SetColSize( 1, 150 );
  $this->SetColSize( 2, 100 );
  $this->SetColSize( 3, 20 );
  $this->SetColSize( 4, 150 );
  $this->SetColSize( 5, 100 );
  $this->SetColSize( 6, 20 );

  $this->SetCellValue( 1, 1, "Custom editor" );
  $this->SetCellValue( 1, 2, "Some value" );
  $this->SetCellEditor( 1, 2, Wx::DemoModules::wxGridCER::CustomEditor->new );
  $this->SetReadOnly( 1, 2, 0 );

  $this->SetCellValue( 1, 4, "Custom renderer" );
  $this->SetCellValue( 1, 5, "SoMe TeXt!" );
  $this->SetCellRenderer( 1, 5, Wx::DemoModules::wxGridCER::CustomRenderer->new );
  $this->SetReadOnly( 1, 5, 0 );

  return $this;
}

sub add_to_tags { 'controls/grid' }
sub title { 'Custom editors and renderers' }

package Wx::DemoModules::wxGridCER::CustomRenderer;

use strict;
use base 'Wx::PlGridCellRenderer';
use Wx qw(wxBLACK_PEN wxWHITE_BRUSH wxSYS_DEFAULT_GUI_FONT);

sub Draw {
  my( $self, $grid, $attr, $dc, $rect, $row, $col, $sel ) = ( shift, @_ );

  $self->SUPER::Draw( @_ );

  $dc->SetPen( wxBLACK_PEN );
  $dc->SetBrush( wxWHITE_BRUSH );
  $dc->SetFont(Wx::SystemSettings::GetFont(wxSYS_DEFAULT_GUI_FONT ));
  $dc->DrawEllipse( $rect->x, $rect->y, $rect->width, $rect->height );
  
  # should check $attr->GetOverflow and then IsEmpty on every cell to the right
  # to extend $rect if overflow is true.
  
  $dc->DestroyClippingRegion();
  $dc->SetClippingRegion($rect->x, $rect->y, $rect->width, $rect->height);
  $dc->DrawText( $grid->GetCellValue( $row, $col ), $rect->x, $rect->y );
  $dc->DestroyClippingRegion();
  
}

sub Clone {
  my $self = shift;

  return $self->new;
}

package Wx::DemoModules::wxGridCER::CustomEditor;

use strict;
use base 'Wx::PlGridCellEditor';

sub new {
  my $class = shift;
  my $self = $class->SUPER::new;

  return $self;
}

sub Create {
  my( $self, $parent, $id, $evthandler ) = @_;

  $self->SetControl( Wx::TextCtrl->new( $parent, $id, 'Default value', [-1,-1], [-1,-1], Wx::wxTE_PROCESS_TAB ) );

  $self->GetControl->PushEventHandler( $evthandler );

  Wx::LogMessage( 'Create called' );
}

sub Destroy {
  my $self = shift;

  $self->GetControl->Destroy if $self->GetControl;
  $self->SetControl( undef );
}

sub SetSize {
  my( $self, $size ) = @_;

  $self->GetControl->SetSize( $size );

  Wx::LogMessage( 'SetSize called' );
}

sub Show {
  my( $self, $show, $attr ) = @_;

  $self->GetControl->Show( $show );

  Wx::LogMessage( 'Show called' );
}

sub EndEdit {
  my( $self, $row, $col, $grid ) = @_;

  my $value = '>> ' . $self->GetControl->GetValue . ' <<';
  my $oldValue = $grid->GetCellValue( $row, $col );

  my $changed =  $value ne $oldValue;

  if( $changed ) { $grid->SetCellValue( $row, $col, $value ) }

  $self->GetControl->Destroy;
  $self->SetControl( undef );

  Wx::LogMessage( 'EndEdit called' );

  return $changed;
}

1;
