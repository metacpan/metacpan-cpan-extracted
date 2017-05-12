#############################################################################
## Name:        lib/Wx/DemoModules/wxNativeTreeListCtrl.pm
## Purpose:     wxPerl demo helper for native Wx::TreeListCtrl
## Author:      Mark Dootson
## Created:     29/02/2012
## RCS-ID:      $Id: wxNativeTreeListCtrl.pm 3162 2012-03-01 00:35:03Z mdootson $
## Copyright:   (c) 2012 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxNativeTreeListCtrl;

use strict;
use base qw(Wx::Panel Class::Accessor::Fast);
use Wx qw( :treectrl :listctrl wxDefaultPosition wxDefaultSize 
           wxVERTICAL wxNO_BORDER wxALL wxEXPAND wxCOL_SORTABLE 
           wxCOL_RESIZABLE wxALIGN_LEFT wxTL_CHECKBOX wxTL_MULTIPLE );
use Wx::Event;

our $VERSION = '0.01';


__PACKAGE__->mk_ro_accessors( qw(treelist) );

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent );
    
    my $tree = $self->{treelist} = Wx::DemoModules::wxNativeTreeListCtrl::Control->new( $self, -1,
	        wxDefaultPosition, [400,200], wxTL_CHECKBOX|wxTL_MULTIPLE );
    
    # add columns
    $tree->AppendColumn( "Column Zero", $tree->WidthFor("Column Data String"), wxALIGN_LEFT, wxCOL_SORTABLE|wxCOL_RESIZABLE );
	$tree->AppendColumn( "Column One", $tree->WidthFor("Column Data String"), wxALIGN_LEFT, wxCOL_SORTABLE|wxCOL_RESIZABLE );
	$tree->AppendColumn( "Column Two", $tree->WidthFor("Column Data String Longer"), wxALIGN_LEFT, wxCOL_SORTABLE|wxCOL_RESIZABLE );
	
    # add items
    
    my $root = $tree->GetRootItem();
    my $item1 = $tree->AppendItem( $root, 'First Top Level Tree Item' );
    my $item2 = $tree->AppendItem( $root, 'Second Top Level Tree Item' );
    my $item3 = $tree->AppendItem( $root, 'Third Top Level Tree Item' );
        
    my $child1_1 = $tree->AppendItem( $item1, 'Child First #1' );
    my $child1_2 = $tree->AppendItem( $item1, 'Child First #2' );
    my $child1_3 = $tree->AppendItem( $item1, 'Child First #3' );
    
    $tree->SetItemText($child1_1, 1, 'First 1 Col 1');
    $tree->SetItemText($child1_2, 1, 'First 2 Col 1');
    $tree->SetItemText($child1_3, 1, 'First 3 Col 1');
    $tree->SetItemText($child1_1, 2, 'First 1 Col 2');
	$tree->SetItemText($child1_2, 2, 'First 2 Col 2');
    $tree->SetItemText($child1_3, 2, 'First 3 Col 2');
    
    my $child2_1 = $tree->AppendItem( $item2, 'Child Second #1' );
	my $child2_2 = $tree->AppendItem( $item2, 'Child Second #2' );
    my $child2_3 = $tree->AppendItem( $item2, 'Child Second #3' );
        
    $tree->SetItemText($child2_1, 1, 'Second 1 Col 1');
    $tree->SetItemText($child2_2, 1, 'Second 2 Col 1');
    $tree->SetItemText($child2_3, 1, 'Second 3 Col 1');
    $tree->SetItemText($child2_1, 2, 'Second 1 Col 2');
	$tree->SetItemText($child2_2, 2, 'Second 2 Col 2');
    $tree->SetItemText($child2_3, 2, 'Second 3 Col 2');   
    
    my $child3_1 = $tree->AppendItem( $item3, 'Child Third #1' );
	my $child3_2 = $tree->AppendItem( $item3, 'Child Third #2' );
    my $child3_3 = $tree->AppendItem( $item3, 'Child Third #3' );
    
	$tree->SetItemText($child3_1, 1, 'Third 1 Col 1');
	$tree->SetItemText($child3_2, 1, 'Third 2 Col 1');
	$tree->SetItemText($child3_3, 1, 'Third 3 Col 1');
	$tree->SetItemText($child3_1, 2, 'Third 1 Col 2');
	$tree->SetItemText($child3_2, 2, 'Third 2 Col 2');
    $tree->SetItemText($child3_3, 2, 'Third 3 Col 2');   
    
    # EVENTS
    
    Wx::Event::EVT_TREELIST_SELECTION_CHANGED($self, $tree, \&OnSelChange);
    Wx::Event::EVT_TREELIST_ITEM_EXPANDING($self, $tree, \&OnItemExpanding);
    Wx::Event::EVT_TREELIST_ITEM_EXPANDED($self, $tree, \&OnItemExpanded);
    Wx::Event::EVT_TREELIST_ITEM_CHECKED($self, $tree, \&OnItemChecked);
    Wx::Event::EVT_TREELIST_COLUMN_SORTED($self, $tree, \&OnCtrlSorted);

    my $sizer = Wx::BoxSizer->new(wxVERTICAL);
    $sizer->Add($tree,1,wxALL|wxEXPAND, 5);
    $self->SetSizer($sizer);
    $self->Layout;
        
    return $self;
}

sub add_to_tags { qw(new controls) }
sub title { 'wxTreeListCtrl' }


sub OnSelChange {
	my ($self, $event) = @_;
	
	my @selections = $self->{treelist}->GetSelections();
	my $selcount = @selections;
	Wx::LogMessage('Selection count: %s', $selcount);
	for ( my $i = 0; $i < @selections; $i++ ) {
	    next unless $selections[$i]->IsOk;
	    my $seltext = $self->{treelist}->GetItemText($selections[$i], 0); # col 0
		Wx::LogMessage('Selection %s : %s', $i, $seltext);
	}
}

sub OnItemExpanding {
    my ($self, $event) = @_;
    
    my $item = $event->GetItem;
    my $itemtext = $self->{treelist}->GetItemText($item);
    Wx::LogMessage('Evt Item is expanding : %s', $itemtext);
    
}

sub OnItemExpanded {
    my ($self, $event) = @_;
    
    my $item = $event->GetItem;
    my $itemtext = $self->{treelist}->GetItemText($item);
    Wx::LogMessage('Evt Item has expanded : %s', $itemtext);
    
}

sub OnItemChecked {
    my ($self, $event) = @_;
    
    my $item = $event->GetItem;
    my $oldchkstate = $event->GetOldCheckedState;
    my $newchkstate = $self->{treelist}->GetCheckedState($item);
    my $itemtext = $self->{treelist}->GetItemText($item);
    
    Wx::LogMessage('Check : %s : old state %s : new state %s', $itemtext, $oldchkstate, $newchkstate);
}

sub OnCtrlSorted {
    my ($self, $event) = @_;
    my ($col, $ascending) = $self->{treelist}->GetSortColumn;
    Wx::LogMessage('Ctrl Sorted on Column : %s', $col) if defined($col);
    
}

package Wx::DemoModules::wxNativeTreeListCtrl::Control;  
use strict;
use base qw( Wx::TreeListCtrl );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    $self->{comp} = Wx::DemoModules::wxNativeTreeListCtrl::Comparator->new();
    $self->SetItemComparator( $self->{comp} );
    
    return $self;
}

package Wx::DemoModules::wxNativeTreeListCtrl::Comparator;  
use strict;
use base qw( Wx::PlTreeListItemComparator );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}


sub Compare {
	my($self, $treelist, $col, $item1, $item2) = @_;
	my $text1 = $treelist->GetItemText( $item1, $col );
    my $text2 = $treelist->GetItemText( $item2, $col );
    my $rval = $text1 cmp $text2;
    Wx::LogMessage("Sort Compare Col %s; %s : %s = %s", $col, $text1, $text2, $rval);
    return $rval
}
	
#Skip loading if no native wxTreeListCtrl
defined &Wx::PlTreeListItemComparator::new;
