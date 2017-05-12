#############################################################################
## Name:        lib/Wx/DemoModules/wxTreeCtrl.pm
## Purpose:     wxPerl demo helper for Wx::TreeCtrl
## Author:      Mattia Barbon
## Modified by:
## Created:     17/02/2001
## RCS-ID:      $Id: wxTreeCtrl.pm 3324 2012-08-09 01:21:55Z mdootson $
## Copyright:   (c) 2001, 2004, 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxTreeCtrl;

use strict;
use base qw(Wx::TreeCtrl);

use Wx qw(:treectrl :window wxDefaultPosition wxDefaultSize 
          wxMOD_ALT wxMOD_SHIFT wxMOD_META wxMOD_CONTROL);
use Wx::Event qw(EVT_TREE_BEGIN_DRAG EVT_TREE_END_DRAG
                 EVT_TREE_SEL_CHANGED EVT_MENU
                 EVT_TREE_KEY_DOWN);

use Wx::DemoModules::lib::Utility;

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new
      ( $parent, -1, wxDefaultPosition, wxDefaultSize,
        wxTR_HAS_BUTTONS|wxTR_EDIT_LABELS|wxSUNKEN_BORDER );

    my $imagelist = Wx::ImageList->new( 16, 16, 1 );
    $imagelist->Add( Wx::GetWxPerlIcon( 1 ) );
    $imagelist->Add
      ( resize_to( Wx::wxTheApp()->GetStdIcon( Wx::wxICON_EXCLAMATION() ),
                   16 ) );

    $self->AssignImageList( $imagelist );
    $self->PopulateTree( 2, 3 );

    EVT_TREE_BEGIN_DRAG( $self, $self, \&OnBeginDrag );
    EVT_TREE_END_DRAG( $self, $self, \&OnEndDrag );
    EVT_TREE_SEL_CHANGED( $self, $self, \&OnSelChange );
    EVT_TREE_KEY_DOWN( $self, $self, \&OnTreeKeyDown );

    # drop down menus
    my $top = Wx::GetTopLevelParent( $self );
    my $treemenu = Wx::Menu->new;
    EVT_MENU( $top, $treemenu->Append( -1, "Traverse" ),
              sub { $self->on_traverse } );
    my $itemmenu = Wx::Menu->new;
    EVT_MENU( $top, $itemmenu->Append( -1, "Rename" ),
              sub { $self->on_rename } );
    EVT_MENU( $top, $itemmenu->Append( -1, "Sort childs ascending" ),
              sub { $self->on_sort( 1 ) } );
    EVT_MENU( $top, $itemmenu->Append( -1, "Sort childs descending" ),
              sub { $self->on_sort( 0 ) } );
    $itemmenu->AppendSeparator;
    EVT_MENU( $top, $itemmenu->Append( -1, "Deselect All" ),
              sub { $self->UnselectAll } );
    $self->{menu} = [ '&Tree Control', $treemenu,
                      '&Items',        $itemmenu ];

    return $self;
}

sub on_sort {
    my( $self, $ascending ) = @_;
    my $item = $self->GetSelection;

    if( !$item->IsOk ) {
        Wx::MessageBox( "Must select an item, first!" );
        return;
    }
    $self->DoSortChildren( $item, $ascending );
}

sub on_rename {
    my( $self ) = @_;
    my $item = $self->GetSelection;

    if( !$item->IsOk ) {
        Wx::MessageBox( "Must select an item, first!" );
        return;
    }
    $self->EditLabel( $item );
}

sub on_traverse {
    my( $self ) = @_;

    $self->DoTraverse( $self->GetRootItem, -1 );
}

sub DoTraverse {
    my( $self, $parent ) = @_;

    # non-leaf: display now
    Wx::LogMessage( "%s", $self->GetItemText( $parent ) );

    my( $id, $cookie ) = $self->GetFirstChild( $parent );
    while( $id->IsOk ) {
        # traverse childs first
        if( $self->ItemHasChildren( $id ) ) {
            $self->DoTraverse( $id, -1 );
        } else {
            # display leaf
            Wx::LogMessage( "%s", $self->GetItemText( $id ) );
        }
        ( $id, $cookie ) = $self->GetNextChild( $parent, $cookie );
    }
}

sub PopulateTree {
    my( $self, $childs, $depth ) = @_;

    my $root = $self->AddRoot( 'Root', -1, -1, 
                               Wx::TreeItemData->new( 'Data' ) );
    $self->PopulateRecursively( $root, $childs, $depth );
}

sub PopulateRecursively {
    my( $self, $parent, $childs, $depth ) = @_;
    my( $text, $item );

    use Wx qw(wxITALIC_FONT wxRED wxBLUE);

    foreach my $i ( 1 .. $childs ) {
        my $text = ( $depth > 0 ) ? "Node $i/$childs" : "Leaf $i/$childs";

        $item = $self->AppendItem( $parent, $text, 0, 1,
                                   Wx::TreeItemData->new( $text ) );
        $self->SetItemFont( $item, wxITALIC_FONT ) if $depth == 0;
        $self->SetItemBackgroundColour( $item, wxBLUE ) if $depth == 1;
        $self->SetItemTextColour( $item, wxRED ) if $depth == 2;

        if( $i == 2 ) {
            my $t = Wx::TreeItemData->new; $t->SetData( "Foo $i" );
            $self->SetItemData( $item, $t );
        }
        $self->SetPlData( $item, "Bar $i" )
          if $i == 3;
        $self->GetItemData( $item )->SetData( "A" )
          if $i == 4;

        $self->PopulateRecursively( $item, $childs + 1, $depth - 1 )
          if $depth >= 1;
    }
}

sub DoSortChildren {
    my( $self, $item, $ascending ) = @_;

    $self->{reverse_sort} = !$ascending;
    $self->SortChildren( $item );
}

sub OnCompareItems {
    my( $self, $item1, $item2 ) = @_;

    if( $self->{reverse_sort} ) {
        return $self->SUPER::OnCompareItems( $item2, $item1 );
    } else {
        return $self->SUPER::OnCompareItems( $item1, $item2 );
    }
}

sub OnBeginDrag {
    my( $self, $event ) = @_;

    if( $event->GetItem != $self->GetRootItem ) {
        $self->{dragged_item} = $event->GetItem;

        Wx::LogMessage( "Dragging %s",
                        $self->GetItemText( $self->{dragged_item} ) );

        $event->Allow;
    } else {
        Wx::LogMessage( "This item can't be dragged" );
    }
}

# this is only a test: a real implementation probably will
# move ( mot copy ) a node, and probably the node childrens, too
# and drop the item at the right place ( not just append it )
sub OnEndDrag {
    my( $self, $event ) = @_;
    my( $src, $dst ) = ( $self->{dragged_item}, $event->GetItem );

    if( $dst->IsOk && !$self->ItemHasChildren( $dst ) ) {
        # copy to parent
        $dst = $self->GetParent( $dst );
    }

    if( !$dst->IsOk ) {
        Wx::LogMessage( "Can't drop here" );
        return;
    }

    my $text = $self->GetItemText( $src );
    Wx::LogMessage( "'%s' copied to '%s'", $text, $self->GetItemText( $dst ) );
    $self->AppendItem( $dst, $text, -1 );
}

sub OnSelChange {
    my( $self, $event ) = @_;
    my $item = $event->GetItem;
    my $data;

    Wx::LogMessage( 'Text: %s', $self->GetItemText( $item ) );
    if( $data = $self->GetItemData( $item ) ) {
        Wx::LogMessage( 'Data: %s', $data->GetData );
    }
    Wx::LogMessage( 'Perl data: %s', $self->GetPlData( $item ) );
}

sub OnTreeKeyDown {
    my( $self, $event ) = @_;
    my $keycode = $event->GetKeyCode;
    my $output = qq(KEYCODE: $keycode);
    
    # Wx >= 0.9911
    if( defined( &Wx::TreeEvent::GetKeyEvent ) ) {
    	my $modifiers = $event->GetKeyEvent->GetModifiers;
    	$output .= qq( MODIFIERS:);
    	if( $modifiers & wxMOD_ALT ) {
    		$output .= qq( Alt);
    	}
    	if( $modifiers & wxMOD_SHIFT ) {
    		$output .= qq( Shift);
    	}	
    	if( $modifiers & wxMOD_CONTROL ) {
		    $output .= qq( Control);
    	}	
        if( $modifiers & wxMOD_META ) {
			$output .= qq( Meta);
    	}
    }
    Wx::LogMessage( qq(Keys $output) );
    
}


sub menu { @{$_[0]->{menu}} }
sub add_to_tags { qw(controls) }
sub title { 'wxTreeCtrl' }

1;
