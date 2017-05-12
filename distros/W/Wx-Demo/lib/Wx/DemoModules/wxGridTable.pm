#############################################################################
## Name:        lib/Wx/DemoModules/wxGridTable.pm
## Purpose:     wxPerl demo hlper for wxGrid custom wxGridTable
## Author:      Mattia Barbon
## Modified by:
## Created:     05/08/2003
## RCS-ID:      $Id: wxGridTable.pm 3118 2011-11-18 09:58:12Z mdootson $
## Copyright:   (c) 2003, 2005, 2006, 2011 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use Wx::Grid;

package Wx::DemoWindows::wxGridTable::Table;

use strict;
use base qw(Wx::PlGridTable);

use Wx qw(wxRED wxGREEN);

sub new {
  my( $class ) = @_;
  my $self = $class->SUPER::new;

  $self->{default} = Wx::GridCellAttr->new;
  $self->{red_bg} = Wx::GridCellAttr->new;
  $self->{green_fg} = Wx::GridCellAttr->new;

  $self->{red_bg}->SetBackgroundColour( wxRED );
  $self->{green_fg}->SetTextColour( wxGREEN );

  return $self;
}

sub GetNumberRows { 100000 }
sub GetNumberCols { 100000 }
sub IsEmptyCell { 0 }

sub GetValue {
  my( $this, $y, $x ) = @_;

  return "($y, $x)";
}

sub SetValue {
  my( $this, $x, $y, $value ) = @_;

  die "Read-Only table";
}

sub GetTypeName {
  my( $this, $r, $c ) = @_;

  return $c == 0 ? 'bool' :
         $c == 1 ? 'double' :
                   'string';
}

sub CanGetValueAs {
  my( $this, $r, $c, $type ) = @_;

  return $c == 0 ? $type eq 'bool' :
         $c == 1 ? $type eq 'double' :
                   $type eq 'string';
}

sub GetValueAsBool {
  my( $this, $r, $c ) = @_;

  return $r % 2;
}

sub GetValueAsDouble {
  my( $this, $r, $c ) = @_;

  return $r + $c / 1000;
}

sub GetAttr {
  my( $self, $row, $col, $kind ) = @_;

  return $self->{default} if $row % 2 && $col % 2;
  return $self->{red_bg} if $row % 2;
  return $self->{green_fg} if $col % 2;
  return Wx::GridCellAttr->new;
}

package Wx::DemoModules::wxGridTable;

use strict;
use base qw(Wx::Grid);

use Wx::Event qw(EVT_GRID_CELL_LEFT_CLICK EVT_GRID_CELL_RIGHT_CLICK
    EVT_GRID_CELL_LEFT_DCLICK EVT_GRID_CELL_RIGHT_DCLICK
    EVT_GRID_LABEL_LEFT_CLICK EVT_GRID_LABEL_RIGHT_CLICK
    EVT_GRID_LABEL_LEFT_DCLICK EVT_GRID_LABEL_RIGHT_DCLICK
    EVT_GRID_ROW_SIZE EVT_GRID_COL_SIZE EVT_GRID_RANGE_SELECT
    EVT_GRID_SELECT_CELL);
    
# events changed names in version 2.9.x
my $events29plus = ( defined(&Wx::Event::EVT_GRID_CELL_CHANGED) );

sub new {
  my $class = shift;
  my $this = $class->SUPER::new( $_[0], -1 );

  my $table = Wx::DemoWindows::wxGridTable::Table->new;

  $this->SetTable( $table );

  EVT_GRID_CELL_LEFT_CLICK( $this, c_log_skip( "Cell left click" ) );
  EVT_GRID_CELL_RIGHT_CLICK( $this, c_log_skip( "Cell right click" ) );
  EVT_GRID_CELL_LEFT_DCLICK( $this, c_log_skip( "Cell left double click" ) );
  EVT_GRID_CELL_RIGHT_DCLICK( $this, c_log_skip( "Cell right double click" ) );
  EVT_GRID_LABEL_LEFT_CLICK( $this, c_log_skip( "Label left click" ) );
  EVT_GRID_LABEL_RIGHT_CLICK( $this, c_log_skip( "Label right click" ) );
  EVT_GRID_LABEL_LEFT_DCLICK( $this, c_log_skip( "Label left double click" ) );
  EVT_GRID_LABEL_RIGHT_DCLICK( $this, c_log_skip( "Label right double click" ) );

  EVT_GRID_ROW_SIZE( $this, sub {
                       Wx::LogMessage( "%s %s", "Row size", GS2S( $_[1] ) );
                       $_[1]->Skip;
                     } );
  EVT_GRID_COL_SIZE( $this, sub {
                       Wx::LogMessage( "%s %s", "Col size", GS2S( $_[1] ) );
                       $_[1]->Skip;
                     } );

  EVT_GRID_RANGE_SELECT( $this, sub {
                           Wx::LogMessage( "Range %sselect (%d, %d, %d, %d)",
                                           ( $_[1]->Selecting ? '' : 'de' ),
                                           $_[1]->GetLeftCol, $_[1]->GetTopRow,
                                           $_[1]->GetRightCol,
                                           $_[1]->GetBottomRow );
                           $_[0]->ShowSelections;
                           $_[1]->Skip;
                         } );
  
  if( $events29plus ) {
        Wx::Event::EVT_GRID_CELL_CHANGED( $this, c_log_skip( "Cell content changed" ) );
    } else {
        Wx::Event::EVT_GRID_CELL_CHANGE( $this, c_log_skip( "Cell content changed" ) );
  }
  
  EVT_GRID_SELECT_CELL( $this, c_log_skip( "Cell select" ) );

  return $this;
}

sub ShowSelections {
    my $this = shift;

    my @cells = $this->GetSelectedCells;
    if( @cells ) {
        Wx::LogMessage( "Cells %s selected", join ', ',
                                                  map { "(" . $_->GetCol .
                                                        ", " . $_->GetRow . ")"
                                                       } @cells );
    } else {
        Wx::LogMessage( "No cells selected" );
    }

    my @tl = $this->GetSelectionBlockTopLeft;
    my @br = $this->GetSelectionBlockBottomRight;
    if( @tl && @br ) {
        Wx::LogMessage( "Blocks %s selected",
                        join ', ',
                        map { "(" . $tl[$_]->GetCol .
                              ", " . $tl[$_]->GetRow . "-" .
                              $br[$_]->GetCol . ", " .
                              $br[$_]->GetRow . ")"
                            } 0 .. $#tl );
    } else {
        Wx::LogMessage( "No blocks selected" );
    }

    my @rows = $this->GetSelectedRows;
    if( @rows ) {
        Wx::LogMessage( "Rows %s selected", join ', ', @rows );
    } else {
        Wx::LogMessage( "No rows selected" );
    }

    my @cols = $this->GetSelectedCols;
    if( @cols ) {
        Wx::LogMessage( "Columns %s selected", join ', ', @cols );
    } else {
        Wx::LogMessage( "No columns selected" );
    }
}

# pretty printer for Wx::GridEvent
sub G2S {
  my $event = shift;
  my( $x, $y ) = ( $event->GetCol, $event->GetRow );

  return "( $x, $y )";
}

# prety printer for Wx::GridSizeEvent
sub GS2S {
  my $event = shift;
  my $roc = $event->GetRowOrCol;

  return "( $roc )";
}

# creates an anonymous sub that logs and skips any grid event
sub c_log_skip {
  my $text = shift;

  return sub {
    Wx::LogMessage( "%s %s", $text, G2S( $_[1] ) );
    $_[0]->ShowSelections;
    $_[1]->Skip;
  };
}

sub add_to_tags { qw(controls/grid) }
sub title { 'Custom wxGridTable' }

1;
