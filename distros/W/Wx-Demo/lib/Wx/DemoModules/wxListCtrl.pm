#############################################################################
## Name:        lib/Wx/DemoModules/wxListCtrl.pm
## Purpose:     wxPerl demo helper for Wx::ListCtrl
## Author:      Mattia Barbon
## Modified by:
## Created:     12/09/2001
## RCS-ID:      $Id: wxListCtrl.pm 2468 2008-09-08 20:55:33Z szabgab $
## Copyright:   (c) 2001, 2003-2004, 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxListCtrl;

use strict;
use Wx::DemoModules::lib::Utility;
use base qw(Wx::ListCtrl);

use Wx qw(:icon wxTheApp :listctrl);
use Wx::Event
  qw(EVT_LIST_BEGIN_DRAG EVT_LIST_BEGIN_RDRAG
     EVT_LIST_BEGIN_LABEL_EDIT EVT_LIST_END_LABEL_EDIT EVT_LIST_DELETE_ITEM
     EVT_LIST_DELETE_ALL_ITEMS
     EVT_LIST_ITEM_SELECTED EVT_LIST_ITEM_DESELECTED EVT_LIST_KEY_DOWN
     EVT_LIST_ITEM_ACTIVATED EVT_LIST_COL_CLICK EVT_CHAR
     EVT_MENU
     );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->create_menu;

    return $self;
}

sub create_image_lists {
    my $images_sm = Wx::ImageList->new( 16, 16, 1 );
    my $images_no = Wx::ImageList->new( 32, 32, 1 );

    $images_sm->Add( Wx::GetWxPerlIcon( 1 ) );
    $images_sm->Add( resize_to( wxTheApp->GetStdIcon( wxICON_EXCLAMATION ),
                                16 ) );
    $images_sm->Add( resize_to( wxTheApp->GetStdIcon( wxICON_ERROR ), 16 ) );

    $images_no->Add( Wx::GetWxPerlIcon() );
    $images_no->Add( wxTheApp->GetStdIcon( wxICON_HAND ) );
    $images_no->Add( wxTheApp->GetStdIcon( wxICON_EXCLAMATION ) );
    $images_no->Add( wxTheApp->GetStdIcon( wxICON_ERROR ) );
    $images_no->Add( wxTheApp->GetStdIcon( wxICON_QUESTION ) );

    return ( $images_sm, $images_no );
}

sub bind_events {
    my( $listctrl ) = @_;

    # bind events
    EVT_LIST_BEGIN_DRAG( $listctrl, $listctrl, \&OnBeginDrag);
    EVT_LIST_BEGIN_RDRAG( $listctrl, $listctrl, \&OnBeginRDrag );
    EVT_LIST_BEGIN_LABEL_EDIT( $listctrl, $listctrl, \&OnBeginLabelEdit );
    EVT_LIST_END_LABEL_EDIT( $listctrl, $listctrl, \&OnEndLabelEdit );
    EVT_LIST_DELETE_ITEM( $listctrl, $listctrl, \&OnDeleteItem );
    EVT_LIST_DELETE_ALL_ITEMS( $listctrl, $listctrl, \&OnDeleteAllItems );
    EVT_LIST_ITEM_SELECTED( $listctrl, $listctrl, \&OnSelected );
    EVT_LIST_ITEM_DESELECTED( $listctrl, $listctrl, \&OnDeselected );
    EVT_LIST_KEY_DOWN( $listctrl, $listctrl, \&OnListKeyDown );
    EVT_LIST_ITEM_ACTIVATED( $listctrl, $listctrl, \&OnActivated );
    EVT_LIST_COL_CLICK( $listctrl, $listctrl, \&OnColClick );
    EVT_CHAR( $listctrl, \&OnChar );
}

sub create_menu {
    my( $listctrl ) = @_;

    my $top = Wx::GetTopLevelParent( $listctrl );
    my $menu = Wx::Menu->new;
    EVT_MENU( $top, $menu->Append( -1, "Toggle first selection" ),
              sub { $listctrl->on_toggle_first } );
    EVT_MENU( $top, $menu->Append( -1, "Deselect all" ),
              sub { $listctrl->on_deselect_all } );
    EVT_MENU( $top, $menu->Append( -1, "Select all" ),
              sub { $listctrl->on_select_all } );
    $menu->AppendSeparator;
    EVT_MENU( $top, $menu->Append( -1, "Sort" ),
              sub { $listctrl->on_sort } );
    $menu->AppendSeparator;
    EVT_MENU( $top, $menu->Append( -1, "Delete all items" ),
              sub { $listctrl->on_delete_all } );
    $listctrl->{menu} = [ '&List Control', $menu ];

    return;
}

sub menu { @{$_[0]->{menu}} }

sub on_toggle_first {
    my( $listctrl ) = @_;

    my $state = $listctrl->GetItemState( 0, wxLIST_STATE_SELECTED );
    my $newState = $state ? 0 : wxLIST_STATE_SELECTED;
    $listctrl->SetItemState( 0, $newState, wxLIST_STATE_SELECTED );
}

sub on_deselect_all {
    my( $listctrl ) = @_;

    foreach ( 0 .. $listctrl->GetItemCount - 1 ) {
        $listctrl->SetItemState( $_, 0, wxLIST_STATE_SELECTED );
    }
}

sub on_select_all {
    my( $listctrl ) = @_;

    foreach ( 0 .. $listctrl->GetItemCount - 1 ) {
        $listctrl->SetItemState( $_, wxLIST_STATE_SELECTED, wxLIST_STATE_SELECTED );
    }
}

my $sort_order = 'asc';
sub on_sort {
    my( $listctrl ) = @_;

    if( $sort_order eq 'asc' ) {
        $sort_order = 'desc';
        $listctrl->SortItems( sub { $_[0] < $_[1] } );
    } else {
        $sort_order = 'asc';
        $listctrl->SortItems( sub { $_[1] < $_[0] } );
    }
}

sub on_delete_all {
    my( $listctrl ) = @_;

    $listctrl->DeleteAllItems;
}

sub OnColClick {
    my( $listctrl, $event ) = @_;

    Wx::LogMessage( "OnClumnClick at %d.", $event->GetColumn );
    $event->Skip;
}

sub OnBeginDrag {
    my( $listctrl, $event ) = @_;

    Wx::LogMessage( "OnBeginDrag ad ( %d, %d ).", 
                    $event->GetPoint->x, $event->GetPoint->y );
    $event->Skip;
}

sub OnBeginRDrag {
    my( $listctrl, $event ) = @_;

    Wx::LogMessage( "OnBeginRDrag ad ( %d, %d ).",
                    $event->GetPoint->x, $event->GetPoint->y );
    $event->Skip;
}

sub OnBeginLabelEdit {
    my( $listctrl, $event ) = @_;

    Wx::LogMessage( "OnBeginLabelEdit: %s",
                    $event->GetItem->GetText );
    $event->Skip;
}

sub OnEndLabelEdit {
    my( $listctrl, $event ) = @_;

    Wx::LogMessage( "OnBeginLabelEdit: %s",
                    $event->GetItem->GetText );
    $event->Skip;
}

sub OnDeleteItem {
    my( $listctrl, $event ) = @_;

    LogEvent( $listctrl, $event, "OnDeleteItem" );
}

sub OnDeleteAllItems {
    my( $listctrl, $event ) = @_;

    LogEvent( $listctrl, $event, "OnDeleteAllItems" );
}

sub OnSelected {
    my( $listctrl, $event ) = @_;

    LogEvent( $listctrl, $event, "OnSelected" );
}

sub OnDeselected {
    my( $listctrl, $event ) = @_;

    LogEvent( $listctrl, $event, "OnDeselected" );
}

sub OnActivated {
    my( $listctrl, $event ) = @_;

    LogEvent( $listctrl, $event, "OnActivated" );
}

sub OnListKeyDown {
    my( $listctrl, $event ) = @_;

    LogEvent( $listctrl, $event, "OnListKeyDown" );
}

sub OnChar {
    my( $listctrl, $event ) = @_;

    Wx::LogMessage( "OnChar" );
}

sub LogEvent {
    my( $listctrl, $event, $name ) = @_;

    Wx::LogMessage( "Item %d: %s ( item text = %s, data = %d )",
                    $event->GetIndex(), $name,
                    $event->GetText(), $event->GetData() );
    $event->Skip;
}

sub tags { [ 'controls/listctrl', 'wxListCtrl' ] }

package Wx::DemoModules::wxListCtrl::Report;

use strict;
use base qw(Wx::ListView Wx::DemoModules::wxListCtrl);

use Wx qw(:listctrl wxDefaultPosition wxDefaultSize);

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent, -1, wxDefaultPosition,
                                   wxDefaultSize, wxLC_REPORT );
    $self->bind_events;
    $self->create_menu;

    my @names = ( "Cheese", "Apples", "Oranges" );

    my( $small, $normal ) = $self->create_image_lists;
    $self->AssignImageList( $small, wxIMAGE_LIST_SMALL );
    $self->AssignImageList( $normal, wxIMAGE_LIST_NORMAL );

    $self->InsertColumn( 0, "Type" );
    $self->InsertColumn( 1, "Amount" );
    $self->InsertColumn( 2, "Price" );

    foreach my $i ( 0 .. 50 ) {
        my $t = ( rand() * 100 ) % 3;
        my $q = int( rand() * 100 );
        my $idx = $self->InsertImageStringItem( $i, $names[$t], 0 );
        $self->SetItemData( $idx, $i );
        $self->SetItem( $idx, 1, $q );
        $self->SetItem( $idx, 2, $q * ( $t + 1 ) );
    }

    return $self;
}

sub add_to_tags { qw(controls/listctrl) }
sub title { 'Report' }
sub file { __FILE__ }

package Wx::DemoModules::wxListCtrl::Virtual;

use strict;
use base qw(Wx::ListCtrl Wx::DemoModules::wxListCtrl);
use Wx qw(:listctrl wxRED wxBLUE wxITALIC_FONT
          wxDefaultPosition wxDefaultSize);

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new
      ( $parent, -1, wxDefaultPosition, wxDefaultSize,
        wxLC_REPORT | wxLC_VIRTUAL );
    $self->bind_events;
    $self->create_menu;

    my( $small, $normal ) = $self->create_image_lists;
    $self->AssignImageList( $small, wxIMAGE_LIST_SMALL );
    $self->AssignImageList( $normal, wxIMAGE_LIST_NORMAL );

    $self->InsertColumn( 0, "Column 1" );
    $self->InsertColumn( 1, "Column 2" );
    $self->InsertColumn( 2, "Column 3" );
    $self->InsertColumn( 3, "Column 4" );
    $self->InsertColumn( 4, "Column 5" );
    $self->SetItemCount( 100000 );

    return $self;
}

sub OnGetItemText {
    my( $self, $item, $column ) = @_;

    return "( $item, $column )";
}

sub OnGetItemAttr {
    my( $self, $item ) = @_;

    my $attr = Wx::ListItemAttr->new;

    if( $item % 2 == 0 ) { $attr->SetTextColour( wxRED ) }
    if( $item % 3 == 0 ) { $attr->SetBackgroundColour( wxBLUE ) }
    if( $item % 5 == 0 ) { $attr->SetFont( wxITALIC_FONT ) }

    return $attr;
}

sub OnGetItemImage {
    my( $self, $item ) = @_;

    return 0;
}

sub OnGetItemColumnImage {
    my( $self, $item, $column ) = @_;

    return $column % 3;
}

sub add_to_tags { qw(controls/listctrl) }
sub title { 'Virtual' }
sub file { __FILE__ }

package Wx::DemoModules::wxListCtrl::List;

use strict;
use base qw(Wx::ListView Wx::DemoModules::wxListCtrl);

use Wx qw(:listctrl wxDefaultPosition wxDefaultSize);

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent, -1, wxDefaultPosition,
                                   wxDefaultSize, wxLC_LIST );
    $self->bind_events;
    $self->create_menu;

    foreach my $i ( 0 .. 40 ) {
        my $idx = $self->InsertStringItem( $i, "Item $i" );
        $self->SetItemData( $idx, $i );
    }

    return $self;
}

sub add_to_tags { qw(controls/listctrl) }
sub title { 'Text' }
sub file { __FILE__ }

package Wx::DemoModules::wxListCtrl::Icon;

use strict;
use base qw(Wx::ListView Wx::DemoModules::wxListCtrl);

use Wx qw(:listctrl wxDefaultPosition wxDefaultSize);

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent, -1, wxDefaultPosition,
                                   wxDefaultSize, wxLC_ICON );
    $self->bind_events;
    $self->create_menu;

    my( $small, $normal ) = $self->create_image_lists;
    $self->AssignImageList( $small, wxIMAGE_LIST_SMALL );
    $self->AssignImageList( $normal, wxIMAGE_LIST_NORMAL );

    foreach my $i ( 0 .. 7 ) {
        my $idx = $self->InsertImageItem( $i, $i % 5 );
        $self->SetItemData( $idx, $i );
    }

    return $self;
}

sub add_to_tags { qw(controls/listctrl) }
sub title { 'Icon' }
sub file { __FILE__ }

package Wx::DemoModules::wxListCtrl::IconText;

use strict;
use base qw(Wx::ListView Wx::DemoModules::wxListCtrl);

use Wx qw(:listctrl wxDefaultPosition wxDefaultSize);

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent, -1, wxDefaultPosition,
                                   wxDefaultSize, wxLC_ICON );
    $self->bind_events;
    $self->create_menu;

    my( $small, $normal ) = $self->create_image_lists;
    $self->AssignImageList( $small, wxIMAGE_LIST_SMALL );
    $self->AssignImageList( $normal, wxIMAGE_LIST_NORMAL );

    foreach my $i ( 0 .. 7 ) {
        my $idx = $self->InsertStringImageItem( $i, "Item $i", $i % 5 );
        $self->SetItemData( $idx, $i );
    }

    return $self;
}

sub add_to_tags { qw(controls/listctrl) }
sub title { 'Icon and Text' }
sub file { __FILE__ }

1;
