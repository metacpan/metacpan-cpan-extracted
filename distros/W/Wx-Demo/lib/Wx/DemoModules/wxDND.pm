#############################################################################
## Name:        lib/Wx/DemoModules/wxDND.pm
## Purpose:     wxPerl demo helper for Drag and Drop
## Author:      Mattia Barbon
## Modified by:
## Created:     12/09/2001
## RCS-ID:      $Id: wxDND.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2001, 2004, 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use Wx::DND;

package Wx::DemoModules::wxDND;

use strict;
use base qw(Wx::Panel);

use Wx qw(wxNullBitmap wxTheApp wxICON_HAND wxRED);

my $tree;

sub new {
  my $class = shift;
  my $this = $class->SUPER::new( @_ );

  # text drop target
  Wx::StaticText->new( $this, -1, 'Drop text in listbox', [ 10, 10 ] );
  my $droptext = Wx::ListBox->new( $this, -1, [ 10 , 40 ], [ 150, 90 ] );
  $droptext->SetDropTarget
    ( Wx::DemoModules::wxDND::TextDropTarget->new( $droptext ) );

  # bitmap drop target
  Wx::StaticText->new( $this, -1, 'Drop bitmap below', [ 180, 10 ] );
  my $window = Wx::Panel->new( $this, -1, [ 180, 40 ], [ 80, 50 ] );
  $window->SetBackgroundColour( wxRED );
  my $dropbitmap = Wx::StaticBitmap->new( $this, -1, wxNullBitmap,
                                          [ 180, 100 ], [ 200, 200 ] );
  $window->SetDropTarget
    ( Wx::DemoModules::wxDND::BitmapDropTarget->new( $dropbitmap ) );
  $dropbitmap->SetBitmap( Wx::Bitmap->new( wxTheApp->GetStdIcon( wxICON_HAND ) ) );

  # files drop target
  Wx::StaticText->new( $this, -1, 'Drop files below', [ 10, 140 ] );
  my $dropfiles = Wx::ListBox->new( $this, -1, [ 10, 170 ], [ 150, 50 ] );
  $dropfiles->SetDropTarget
    ( Wx::DemoModules::wxDND::FilesDropTarget->new( $dropfiles ) );

  # drop source
  my $dragsource =
    Wx::DemoModules::wxDND::DropSource->new( $this, -1, [ 10, 230 ] );

  # tree control; you can drop on items
  Wx::StaticText->new( $this, -1, 'Drop bitmap in tree below', [ 300, 10 ] );
  $tree = Wx::TreeCtrl->new( $this, -1, [ 300, 40 ], [ 100, 90 ] );
  my $root = $tree->AddRoot( "Drop here" );
  $tree->AppendItem( $root, "and here" );
  $tree->AppendItem( $root, "and here" );
  $tree->AppendItem( $root, "and here" );
  $tree->Expand( $root );
  $tree->SetDropTarget
    ( Wx::DemoModules::wxDND::TreeDropTarget->new( $tree, $dropbitmap ) );

  # native perl data drop target
  Wx::StaticText->new( $this, -1, 'Drop data below', [ 300, 140 ] );
  my $dropdata = Wx::TextCtrl->new( $this, -1, '', [ 300, 170 ], [ 100, 50 ] );
  $dropdata->SetDropTarget
    ( Wx::DemoModules::wxDND::DataDropTarget->new( $dropdata ) );

  # drop data source
  my $dragdatasource =
    Wx::DemoModules::wxDND::DropDataSource->new( $this, -1, [ 300, 230 ] );

  return $this;
}

sub add_to_tags { qw(dnd) }
sub title { 'Drag and drop' }

package Wx::DemoModules::wxDND::TreeDropTarget;

use strict;
use base qw(Wx::DropTarget);

sub new {
  my $class = shift;
  my $tree = shift;
  my $canvas = shift;
  my $this = $class->SUPER::new;

  my $data = Wx::BitmapDataObject->new;
  $this->SetDataObject( $data );
  $this->{TREE} = $tree;
  $this->{DATA} = $data;
  $this->{CANVAS} = $canvas;

  return $this;
}

sub data { $_[0]->{DATA} }
sub canvas { $_[0]->{CANVAS} }

use Wx qw(:treectrl wxDragNone wxDragCopy);

# give visual feedback: select the item we're on
# ( probably better forms of feedback are possible )
# also return the desired action to make the OS display an appropriate
# "can drop here" icon
sub OnDragOver {
  my( $this, $x, $y, $desired ) = @_;
  my $tree = $this->{TREE};

  my( $item, $flags ) = $tree->HitTest( [$x, $y] );
  if( $flags & wxTREE_HITTEST_ONITEMLABEL ) {
    $tree->SelectItem( $item );
    return $desired;
  } else {
    $tree->Unselect();
    return wxDragNone;
  }
}

sub OnData {
  my( $this, $x, $y, $def ) = @_;

  $this->GetData;
  $this->canvas->SetBitmap( $this->data->GetBitmap );

  return $def;
}

package Wx::DemoModules::wxDND::DropSource;

use strict;
use base qw(Wx::Window);

use Wx::Event qw(EVT_LEFT_DOWN EVT_PAINT);

use Wx::DemoModules::lib::DataObjects;

sub new {
  my $class = shift;
  my $this = $class->SUPER::new( @_[0,1,2], [200,50] );

  EVT_PAINT( $this, \&OnPaint );
  EVT_LEFT_DOWN( $this, \&OnDrag );

  return $this;
}

sub OnPaint {
  my( $this, $event ) = @_;
  my $dc = Wx::PaintDC->new( $this );

  $dc->DrawText( "Drag text/bitmap from here", 2, 2 );
}

sub OnDrag {
  my( $this, $event ) = @_;

  my $data = get_text_bitmap_data_object();
  my $source = Wx::DropSource->new( $this );
  $source->SetData( $data );
  Wx::LogMessage( "Status: %d", $source->DoDragDrop( 1 ) );
}

package Wx::DemoModules::wxDND::TextDropTarget;

use strict;
use base qw(Wx::TextDropTarget);

sub new {
  my $class = shift;
  my $listbox = shift;
  my $this = $class->SUPER::new( @_ );

  $this->{LISTBOX} = $listbox;

  return $this;
}

sub OnDropText {
  my( $this, $x, $y, $data ) = @_;

  $data =~ s/[\r\n]+$//;
  Wx::LogMessage( "Dropped text: '$data'" );
  $this->{LISTBOX}->InsertItems( [ $data ], 0 );

  return 1;
}

package Wx::DemoModules::wxDND::FilesDropTarget;

use strict;
use base qw(Wx::FileDropTarget);

sub new {
  my $class = shift;
  my $listbox = shift;
  my $this = $class->SUPER::new( @_ );

  $this->{LISTBOX} = $listbox;

  return $this;
}

sub OnDropFiles {
  my( $this, $x, $y, $files ) = @_;

  $this->{LISTBOX}->Clear;
  Wx::LogMessage( "Dropped files at ($x, $y)" );
  foreach my $i ( @$files ) {
    $this->{LISTBOX}->Append( $i );
  }

  return 1;
}

package Wx::DemoModules::wxDND::BitmapDropTarget;

use strict;
use base qw(Wx::DropTarget);

sub new {
  my $class = shift;
  my $this = $class->SUPER::new;

  my $data = Wx::BitmapDataObject->new;
  $this->SetDataObject( $data );
  $this->{DATA} = $data;
  $this->{CANVAS} = $_[0];

  return $this;
}

sub data { $_[0]->{DATA} }
sub canvas { $_[0]->{CANVAS} }

sub OnData {
  my( $this, $x, $y, $def ) = @_;

  $this->GetData;
  $this->canvas->SetBitmap( $this->data->GetBitmap );

  return $def;
}

package Wx::DemoModules::wxDND::DropDataSource;

use strict;
use base qw(Wx::Window);

use Wx::Event qw(EVT_LEFT_DOWN EVT_PAINT);

use Wx::DemoModules::lib::DataObjects;

sub new {
  my $class = shift;
  my $this = $class->SUPER::new( @_[0,1,2], [200,50] );

  EVT_PAINT( $this, \&OnPaint );
  EVT_LEFT_DOWN( $this, \&OnDrag );

  return $this;
}

sub OnPaint {
  my( $this, $event ) = @_;
  my $dc = Wx::PaintDC->new( $this );
  $dc->DrawText( "Drag perl data from here", 2, 2 );
}

sub OnDrag {
  my( $this, $event ) = @_;

  my $PerlData = { fruit => 'lemon', colour => 'yellow' };
  my $data = get_perl_data_object( $PerlData );
  my $source = Wx::DropSource->new( $this );
  $source->SetData( $data );
  Wx::LogMessage( "OnDrag Status: %d", $source->DoDragDrop( 1 ) );
}

package Wx::DemoModules::wxDND::DataDropTarget;

use strict;
use base qw(Wx::DropTarget);
use Wx::DemoModules::lib::DataObjects;

sub new {
  my $class = shift;
  my $this = $class->SUPER::new;

  my $data = get_perl_data_object();
  $this->SetDataObject( $data );
  $this->{DATA} = $data;
  $this->{TEXTCTRL} = $_[0];

  return $this;
}

sub data { $_[0]->{DATA} }
sub textctrl { $_[0]->{TEXTCTRL} }

sub OnData {
  my( $this, $x, $y, $def ) = @_;

  Wx::LogMessage( "Dropped perl data at ($x, $y)" );
  $this->GetData;
  my $PerlData = $this->data->GetPerlData;
  my $text = '';
  foreach (keys %$PerlData) {
	  $text .= "$_ = $PerlData->{$_} ";
  }
  Wx::LogMessage( "( $text )" );

  $this->textctrl->SetValue( $text );

  return $def;
}

1;
