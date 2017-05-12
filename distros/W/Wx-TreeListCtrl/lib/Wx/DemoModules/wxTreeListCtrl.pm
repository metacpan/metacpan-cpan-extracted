#############################################################################
## Name:        lib/Wx/DemoModules/wxTreeListCtrl.pm
## Purpose:     wxPerl demo helper for Wx::TreeListCtrl
## Author:      Mattia Barbon
## Modified by: Mark Dootson
## Created:     13/08/2006
## RCS-ID:      $Id: wxTreeListCtrl.pm 17 2011-06-21 14:21:11Z mark.dootson $
## Copyright:   (c) 2005-2010 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################


package Wx::DemoModules::wxTreeListCtrl;

use strict;
use base qw(Wx::Panel Class::Accessor::Fast);
use Wx::TreeListCtrl;
use Wx qw( :treelist :listctrl wxDefaultPosition wxDefaultSize wxVERTICAL wxNO_BORDER wxALL wxEXPAND);

our $VERSION = '0.13';


__PACKAGE__->mk_ro_accessors( qw(treelist) );

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent );

    my $tree = $self->{treelist} = Wx::DemoModules::wxTreeListCtrl::Control->new( $self, -1,
        wxDefaultPosition, [400,200],
        wxTR_HIDE_ROOT | wxTR_ROW_LINES | wxTR_HAS_BUTTONS
        | wxTR_FULL_ROW_HIGHLIGHT | wxTR_SHOW_ROOT_LABEL_ONLY | wxTR_NO_LINES
    );


    # now add the columns
    if ($Wx::TreeListCtrl::VERSION > 0.06) {
        my $colinfo = Wx::TreeListColumnInfo->new("Column Three", 120, wxLIST_FORMAT_LEFT);
        $tree->AddColumn($colinfo);
        $colinfo->SetText("Column Two");
        $tree->InsertColumn(0, $colinfo);
        $colinfo->SetText("Column One");
        $tree->InsertColumn(0, $colinfo);
    } else {
        $tree->AddColumn( "Column Three",   120, wxLIST_FORMAT_LEFT );
        $tree->InsertColumn( 0, "Column Two",       120, wxLIST_FORMAT_LEFT );
        $tree->InsertColumn( 0, "Column One",       120, wxLIST_FORMAT_LEFT );
    }
    
    my $root = $tree->AddRoot( 'Root Item' );
    my $item1 = $tree->AppendItem( $root, 'First Top Level Tree Item Is Very Long' );
    # $tree->SetItemHeight( $item1, 120 );
    $tree->SetItemBold( $item1, 1 );
    $tree->SetItemTextColour( $item1, Wx::Colour->new( 22, 14, 135 ));
    $tree->SetItemBackgroundColour( $item1, Wx::Colour->new( 160, 184, 255 ));
    my $child1 = $tree->AppendItem( $item1, 'Editable Child #1' );
    my $child2 = $tree->AppendItem( $item1, 'Editable Child #2' );
    my $child3 = $tree->AppendItem( $item1, 'Editable Child #3' );
        
        # call Column method directly
    $tree->SetItemColumnText( $child1, 1, "Child #1 - Column 2" );
    $tree->SetItemColumnText( $child1, 2, "Child #1 - Column 3" );
    $tree->SetItemColumnText( $child2, 1, "Child #2 - Column 2" );
        # call overloaded method - same result as above
    $tree->SetItemText( $child2, 2, "Child #2 - Column 3" );
    $tree->SetItemText( $child3, 1, "Child #3 - Column 2" );
    $tree->SetItemText( $child3, 2, "Child #3 - Column 3" );
    
    $tree->SetItemTextColour( $child3, 2, Wx::Colour->new(255,0,0));
    
    my $item2 = $tree->AppendItem( $root, 'Second Tree Item Is Also Long' );
    $tree->SetItemBold( $item2, 1 );
    $tree->SetItemTextColour( $item2, Wx::Colour->new( 178, 12, 48 ));
    $tree->SetItemBackgroundColour( $item2, Wx::Colour->new( 255, 211, 135 ));
    my $childA = $tree->AppendItem( $item2, 'Editable Child A' );
    my $childB = $tree->AppendItem( $item2, 'Editable Child B' );
    my $childC = $tree->AppendItem( $item2, 'Editable Child C' );
    $tree->SetItemText( $childA, 1, "Child A - Column 2" );
    $tree->SetItemText( $childA, 2, "Child A - Column 3" );
    $tree->SetItemText( $childB, 1, "Child B - Column 2" );
    $tree->SetItemText( $childB, 2, "Child B - Column 3" );
    $tree->SetItemText( $childC, 1, "Child C - Column 2" );
    $tree->SetItemText( $childC, 2, "Child C - Column 3" );
    
    $tree->ExpandAll( $tree->GetRootItem );
    $tree->SortChildren($item1);
    $tree->SortChildren($item2);
    
    # set colour of list item
    

    $tree->SetColumnEditable(0,1);
        
    my $sizer = Wx::BoxSizer->new(wxVERTICAL);
    $sizer->Add($tree,1,wxALL|wxEXPAND, 5);
    $self->SetSizer($sizer);
    $self->Layout;
        
    return $self;
}

sub add_to_tags { qw(controls) }
sub title { 'wxTreeListCtrl' }

package Wx::DemoModules::wxTreeListCtrl::Control;
  
use strict;
use Wx::TreeListCtrl;
use base qw( Wx::TreeListCtrl );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub OnCompareItems {
    my ($self, $item1, $item2) = @_;
    my $text1 = $self->GetItemText( $item1 );
    my $text2 = $self->GetItemText( $item2 );
    Wx::LogMessage("Wx::TreeListCtrl Compare Items; %s : %s", $text1, $text2);
    return $text1 cmp $text2;
}

1;

