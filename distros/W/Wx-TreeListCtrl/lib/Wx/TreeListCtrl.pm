#############################################################################
## Name:        TreeListCtrl.pm
## Purpose:     Wx::TreeListControl
## Author:      Mark Wardell
## Modified by: Mark Dootson
## RCS-ID:      $Id: TreeListCtrl.pm 17 2011-06-21 14:21:11Z mark.dootson $
## Copyright:   (c) 2006-2010 Mark Wardell
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::TreeListCtrl;
use 5.008;
use strict;
use warnings;
use Wx;

our $VERSION = '0.13';

our @constants = qw(
     wxTL_MODE_NAV_FULLTREE
     wxTL_MODE_NAV_EXPANDED
     wxTL_MODE_NAV_VISIBLE
     wxTL_MODE_NAV_LEVEL
     wxTL_MODE_FIND_EXACT
     wxTL_MODE_FIND_PARTIAL 
     wxTL_MODE_FIND_NOCASE
     wxTR_HAS_BUTTONS
     wxTR_NO_LINES
     wxTR_LINES_AT_ROOT
     wxTR_TWIST_BUTTONS
     wxTR_MULTIPLE
     wxTR_EXTENDED
     wxTR_HAS_VARIABLE_ROW_HEIGHT
     wxTR_EDIT_LABELS
     wxTR_ROW_LINES
     wxTR_HIDE_ROOT
     wxTR_FULL_ROW_HIGHLIGHT
     wxTR_DEFAULT_STYLE
     wxTR_SINGLE
     wxTR_NO_BUTTONS
     wxTR_VIRTUAL
     wxTR_COLUMN_LINES
     wxTREE_HITTEST_ONITEMCOLUMN
     wxTR_SHOW_ROOT_LABEL_ONLY
);

push @Wx::EXPORT_OK, @constants;
$Wx::EXPORT_TAGS{'treelist'} = [ @constants ];
require XSLoader;
XSLoader::load( 'Wx::TreeListCtrl', $VERSION );

#
# confirm inheritance tree
#

no strict;

package Wx::TreeListCtrl;  @ISA = qw( Wx::Control );

# Alias
*Wx::TreeListCtrl::Edit = \&Wx::TreeListCtrl::EditLabel;

1;
__END__

=head1 NAME

Wx::TreeListCtrl - interface to the Wx::TreeListCtrl class

=head1 VERSION 0.13

=head1 SYNOPSIS

  use Wx::TreeListCtrl;

=head1 DESCRIPTION

Wx::TreeListCtrl is a wrapper for the wxTreeListCtrl class in the wxWidgets GUI toolkit.

=head2 EXPORT

None by default.

=head2 Exportable constants

  wxTL_MODE_NAV_FULLTREE
  wxTL_MODE_NAV_EXPANDED
  wxTL_MODE_NAV_VISIBLE
  wxTL_MODE_NAV_LEVEL
  wxTL_MODE_FIND_EXACT
  wxTL_MODE_FIND_PARTIAL 
  wxTL_MODE_FIND_NOCASE
  wxTR_HAS_BUTTONS
  wxTR_NO_LINES
  wxTR_LINES_AT_ROOT
  wxTR_TWIST_BUTTONS
  wxTR_MULTIPLE
  wxTR_EXTENDED
  wxTR_HAS_VARIABLE_ROW_HEIGHT
  wxTR_EDIT_LABELS
  wxTR_ROW_LINES
  wxTR_HIDE_ROOT
  wxTR_FULL_ROW_HIGHLIGHT
  wxTR_DEFAULT_STYLE
  wxTR_SINGLE
  wxTR_NO_BUTTONS
  wxTR_VIRTUAL
  wxTR_COLUMN_LINES
  wxTREE_HITTEST_ONITEMCOLUMN
  wxTR_SHOW_ROOT_LABEL_ONLY  

=head1 DOCUMENTATION

  The main Wx::TreeListCtrl has the same interface as the wxPython module for
  wxTreeListCtrl which is available here:

  L<http://wxcode.sourceforge.net/components/treelistctrl/reference.html>

  To make column editable (inline) use $control->SetColumnEditable($column_number_from_0,1);

  Wx::TreeListColumnInfo is also available

  my $info = Wx::TreeListColumnInfo->new( coltext, width, flags, imageindex, shown, editable);

     only coltext is required, defaults for other items:
     width      = 100
     flags      = wxALIGN_LEFT
     imageindex = -1
     shown      = 1 (true)
     editable   = 0 (false)

  usage:

  $treelist->AddColumn($info);
  $treelist->InsertColumn(2, $info);
  $treelist->SetColumn(3, $info);

  # set methods have equivalent get methods
  my $info = $treelist->GetColumn(4); 
  $info->SetText('Column Four');
  $info->SetWidth('50');
  $info->SetAlignment(wxALIGN_RIGHT);
  $info->SetImage(1);
  $info->SetSelectedImage(2);
  $info->SetShown(1);
  $info->SetEditable(0);
  $treelist->SetColumn(4, $info);
  $info->SetText('Column Five');
  $treelist->SetColumn(5, $info);

  # note - changing a TreeListColumnInfo object will not
  # affect the underlying object. You must 'SetColumn' to
  # change the underlying data.

  # the two boolean members use 'Is' as a get method
  $info->IsShown
  $info->IsEditable

  The control processes some mouse events internally. To respond to 'right click' and
  context events, use
  EVT_TREE_ITEM_RIGHT_CLICK  - The user has clicked an item with the right mouse button
  EVT_RIGHT_UP - The user has right clicked the control with the right mouse button - but
  not on any item
  EVT_CONTEXT_MENU - The user has used keyboard method to invoke a context menu

=head1 AUTHOR

Mark Wardell <mwardell@cpan.org>

=head1 Current Maintainer

Mark Dootson <mdootson@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 - 2011 by Mark Wardell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

This package includes the wxTreeListCtrl source code which you may use
according to the the wxWidgets license.

The authors of the wxTreeListCtrl package are:
    Robert Roebling,
    Julian Smart,
    Alberto Griggio,
    Vadim Zeitlin,
    Otto Wyss,
    Guru Kathiresan

=cut
