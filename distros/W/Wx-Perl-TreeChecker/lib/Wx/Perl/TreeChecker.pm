#############################################################################
## Name:        Wx::Perl::TreeChecker
## Purpose:     Tree Control with checkbox functionality
## Author:      Simon Flack
## Modified by: $Author: simonflack $ on $Date: 2005/03/25 13:44:30 $
## Created:     28/11/2002
## RCS-ID:      $Id: TreeChecker.pm,v 1.13 2005/03/25 13:44:30 simonflack Exp $
#############################################################################

package Wx::Perl::TreeChecker;
use strict;
use vars qw(@ISA $VERSION @EXPORT_OK %EXPORT_TAGS);
use Wx ':treectrl', 'wxTR_MULTIPLE', 'WXK_SPACE';
use Wx::Event qw[EVT_LEFT_DOWN EVT_LEFT_DCLICK EVT_KEY_DOWN];
use Exporter;
use Carp;

@ISA = ('Wx::TreeCtrl', 'Exporter');
$VERSION = sprintf'%d.%02d', q$Revision: 1.13 $ =~ /: (\d+)\.(\d+)/;
@EXPORT_OK = qw(TC_SELECTED TC_PART_SELECTED TC_SEL_COMPACT TC_SEL_FULL
                TC_IMG_ROOT TC_IMG_C_NORMAL TC_NORMAL);
%EXPORT_TAGS = (status => [qw(TC_SELECTED TC_PART_SELECTED TC_SEL_COMPACT
                              TC_SEL_FULL)],
                icons  => [qw(TC_IMG_ROOT TC_IMG_C_NORMAL TC_IMG_NORMAL)]);

use constant TC_SELECTED      => 1;  # tree item that is selected
use constant TC_PART_SELECTED => 2;  # non-terminal tree item that has
                                     # some children selected

use constant TC_SEL_FULL      => 0;  # get all (part)?selected treeitems
use constant TC_SEL_COMPACT   => 1;  # get a compact list

# Name the Wx::ImageList indices
use constant TC_IMG_ROOT                 => 0;   # root icon
use constant TC_IMG_ROOT_SELECTED        => 1;   # ^ selected
use constant TC_IMG_ROOT_PART_SELECTED   => 2;   # ^ selected
use constant TC_IMG_C_NORMAL             => 3;   # container icon
use constant TC_IMG_C_SELECTED           => 4;   # ^ selected
use constant TC_IMG_C_PART_SELECTED      => 5;   # partially selected icon
use constant TC_IMG_NORMAL               => 6;   # normal icon
use constant TC_IMG_SELECTED             => 7;   # ^ selected

my (%_multiple, %_images, %_containers_only, %_items_only, %_no_recurse);

sub new {
    my $class = shift;
    my $opts = pop @_ if ref $_[-1] eq 'HASH';
    my $self = $class -> SUPER::new (@_);

    $self -> _init ($opts || {});
    bless $self, $class;
    return $self;
}

sub Convert {
    my $class = shift;
    my ($treectrl, $opts) = @_;
    croak q[object isn't a Wx::TreeCtrl]
            unless ref $treectrl && UNIVERSAL::isa($treectrl, 'Wx::TreeCtrl');
    $treectrl = bless $treectrl, $class;

    $treectrl -> _init ($opts || {});
    return $treectrl;
}

sub _init {
    my $self = shift;
    my $opts = shift;

    # Wx::Perl::TreeCheckers should be wxTR_SINGLE only
    my $flag = $self->GetWindowStyleFlag();
    $flag &=~ wxTR_MULTIPLE;
    $self->SetWindowStyleFlag($flag);

    $opts -> {allow_multiple} = 1 unless defined $opts -> {allow_multiple};
    $self -> allow_multiple ($opts -> {allow_multiple});
    EVT_LEFT_DOWN   ($self, \&OnSelectCheckBox);
    EVT_LEFT_DCLICK ($self, \&OnSelectCheckBox);
    EVT_KEY_DOWN    ($self, \&OnSelectCheckBox);

    $self -> image_list($opts -> {image_list} || $self -> _default_images());
    $self -> containers_only ($opts -> {containers_only});
    $self -> items_only ($opts -> {items_only});
    $self -> no_recurse ($opts -> {no_recurse});
}

sub DESTROY {
    my $self = shift;
    delete $_multiple        {$self};
    delete $_images          {$self};
    delete $_containers_only {$self};
    delete $_items_only      {$self};
    delete $_no_recurse      {$self};
}
##############################################################################
# Accessors

sub allow_multiple {
    my $self = shift;
    return $_multiple {$self} unless defined $_[0];
    $_multiple {$self} = $_[0];
}

sub image_list {
    my $self = shift;
    return $_images {$self} unless defined $_[0];
    croak "USAGE: imagelist( Wx::ImageList)" unless
            ref $_[0] && UNIVERSAL::isa($_[0], 'Wx::ImageList');
    my $image_list = shift;
    $self -> SUPER::SetImageList ($image_list);
    $_images {$self} = $image_list;
}

sub containers_only {
    my $self = shift;
    return $_containers_only {$self} unless defined $_[0];
    croak q[ERROR: 'items_only' and 'containers_only' are mutually exclusive]
            if $_[0] && $self -> items_only;
    $_containers_only {$self} = $_[0];
}

sub items_only {
    my $self = shift;
    return $_items_only {$self} unless defined $_[0];
    croak q[ERROR: 'items_only' and 'containers_only' are mutually exclusive]
            if $_[0] && $self -> containers_only;
    $_items_only {$self} = $_[0];
}

sub no_recurse {
    my $self = shift;
    return $_no_recurse {$self} unless defined $_[0];
    $_no_recurse {$self} = $_[0];
}

##############################################################################
# Extras


sub IsContainer {
    my $self = shift;
    my $item = shift;
    croak "USAGE: IsContainer(Wx::TreeItemId)" unless defined $item
            && ref $item && UNIVERSAL::isa($item, 'Wx::TreeItemId');
    my $data = $self -> Wx::TreeCtrl::GetPlData ($item);
    return $data  -> {container} || $self -> ItemHasChildren ($item)
}

sub UnselectAll {
    my $self = shift;
    my $root = $self -> GetRootItem();
    my $data = $self -> SUPER::GetPlData($root);
    $data -> {selected} = 0;
    $self -> SUPER::SetPlData($root, $data);
    $self -> SetItemImage($root, TC_IMG_ROOT);
    $self -> SetItemImage($root, TC_IMG_ROOT, wxTreeItemIcon_Selected);
    $self -> _update_children($root, 0);
}

##############################################################################
# Overriden Wx::TreeCtrl Methods

sub AddRoot {
    my $self = shift;
    my ($text, $data) = (@_)[0,-1];
    my $_data = $self -> _makedata($data, 1);
    $self -> SUPER::AddRoot($text, TC_IMG_ROOT, TC_IMG_ROOT, $_data);
}

sub AppendItem {
    my $self = shift;
    my ($parent, $text, $data) = (@_)[0,1,-1];
    my $_data = $self -> _makedata($data);
    $self -> SUPER::AppendItem($parent, $text, TC_IMG_NORMAL, TC_IMG_NORMAL,
                               $_data);
}

sub AppendContainer {
    # This isn't a std Wx::TreeCtrl method - It's the same as AddItem() but
    # adds a 'container'
    my $self = shift;
    my ($parent, $text, $data) = (@_)[0,1,-1];
    my $_data = $self -> _makedata($data, 1);
    $self -> SUPER::AppendItem($parent, $text, TC_IMG_C_NORMAL,
                               TC_IMG_C_NORMAL, $_data);
}

sub PrependItem {
    my $self = shift;
    my ($parent, $text, $data) = (@_)[0,1,-1];
    my $_data = $self -> _makedata($data);
    $self -> SUPER::PrependItem($parent, $text, TC_IMG_NORMAL, TC_IMG_NORMAL,
                               $_data);
}

sub PrependContainer {
    my $self = shift;
    my ($parent, $text, $data) = (@_)[0,1,-1];
    my $_data = $self -> _makedata($data, 1);
    $self -> SUPER::PrependItem($parent, $text, TC_IMG_C_NORMAL,
                               TC_IMG_C_NORMAL, $_data);
}

sub InsertItem {
    my $self = shift;
    my ($parent, $previous, $text, $data) = (@_)[0,1,2,-1];
    my $_data = $self -> _makedata($data);
    $self -> SUPER::InsertItem($parent, $previous, $text, TC_IMG_NORMAL,
                               TC_IMG_NORMAL, $_data);
}

sub InsertContainer {
    my $self = shift;
    my ($parent, $previous, $text, $data) = (@_)[0,1,2,-1];
    my $_data = $self -> _makedata($data, 1);
    $self -> SUPER::InsertItem($parent, $previous, $text, TC_IMG_C_NORMAL,
                               TC_IMG_C_NORMAL, $_data);
}

BEGIN {
    *InsertItemPrev      = \&InsertItem;
    *InsertItemBef       = \&InsertItem;
    *InsertConatinerPrev = \&InsertContainer;
    *InsertContainerBef  = \&InsertContainer;
};

sub GetPlData {
    my $self = shift;
    my $item = shift;
    my $_data = $self -> SUPER::GetPlData ($item);
    return ref $_data ? $_data -> {_USERDATA} : $_data;
}

sub SetPlData {
    my $self = shift;
    my ($item, $data) = @_;
    my $_data = $self -> SUPER::GetPlData($item);
    $_data -> {_USERDATA} = $data;
    $self -> SUPER::SetPlData ($item, $_data);
}

sub GetItemData {
    my $self = shift;
    my $item = shift;
    return new Wx::TreeItemData($self -> GetPlData ($item));
}

sub SetItemData {
    my $self = shift;
    my ($item, $data) = @_;
    $self -> SetPlData ($item, $data -> GetData);
}

sub IsSelected {
    my $self = shift;
    my $item = shift;
    croak "USAGE: IsSelected(Wx::TreeItemId)" unless defined $item
            && ref $item && UNIVERSAL::isa($item, 'Wx::TreeItemId');
    my $data = $self -> SUPER::GetPlData ($item);
    return $data -> {selected};
}

sub SelectItem {
    my $self = shift;
    my $item = shift;
    croak "USAGE: SelectItem(Wx::TreeItemId)" unless defined $item
            && ref $item && UNIVERSAL::isa($item, 'Wx::TreeItemId');
    if ($self -> allow_multiple) {
        $self -> on_select_multiple ($item, 1)
    } else {
        $self -> on_select_single ($item, 1)
    }
    return 1 if $self -> IsSelected ($item);
}

sub UnSelectItem {
    my $self = shift;
    my $item = shift;
    croak "USAGE: UnSelectItem(Wx::TreeItemId)" unless defined $item
            && ref $item && UNIVERSAL::isa($item, 'Wx::TreeItemId');
    if ($self -> allow_multiple) {
        $self -> on_select_multiple ($item, 0)
    } else {
        $self -> on_select_single ($item, 0)
    }
    return 1 if ! $self -> IsSelected ($item);
}

sub GetImageList {
    # Default method removes the list from memory
    my $self = shift;
    return $self -> image_list;
}

sub SetImageList {
    my $self = shift;
    $self -> image_list(shift);
}

sub GetSelection {
    my $self = shift;
    return $self -> _get_selected(@_);
}

sub GetSelections {
    my $self = shift;
    return $self -> _get_selected(@_);
}

##############################################################################
# Event Handlers

sub OnSelectCheckBox {
    my ($self, $event) = @_;

    my $item;
    if ($event->isa('Wx::KeyEvent')) {
        return $event -> Skip (1) unless $event -> GetKeyCode() == WXK_SPACE;
        $item = $self -> SUPER::GetSelection;
    } else {
        my $flags;
        my $pos = $event -> GetPosition;
        ($item, $flags) = $self -> HitTest ($pos);
        return $event -> Skip (1) unless $flags & wxTREE_HITTEST_ONITEMICON;
        $event -> Skip (0) if $event -> ButtonDClick;
    }

    if ($self -> allow_multiple) {
        $self -> on_select_multiple ($item)
    } else {
        $self -> on_select_single ($item)
    }
}

sub on_select_multiple {
    my $self = shift;
    my ($item, $_sel) = @_;

    my $data = $self -> SUPER::GetPlData($item);
    $data->{selected} = $_sel || !$data -> {selected};
    $self -> SUPER::SetPlData( $item, $data );

    my $container = $self -> IsContainer($item);
    return if (!$container && $self -> containers_only());
    return if ($container && $self -> items_only());

    my $imagename;
    if ($container) {
        $imagename = $data -> {selected} ? TC_IMG_C_SELECTED : TC_IMG_C_NORMAL;
        if ($self -> no_recurse) {
            $self -> _update_children($item, 0)
        } else {
            $self -> _update_children($item, $data -> {selected})
        }
    } else {
        $imagename = $data -> {selected} ? TC_IMG_SELECTED : TC_IMG_NORMAL;
    }

    my $treeroot = $self -> GetRootItem;
    $imagename = $treeroot == $item ? $data->{selected} ? TC_IMG_ROOT_SELECTED
            : TC_IMG_ROOT : $imagename;

    $self -> SetItemImage($item, $imagename);
    $self -> SetItemImage($item, $imagename, wxTreeItemIcon_Selected);
    $self -> _update_parents ($item);
}

sub on_select_single {
    my $self = shift;
    my ($item, $_sel) = @_;

    my $data = $self -> SUPER::GetPlData($item);
    my $container = $self -> IsContainer ($item);

    return if (!$container && $self -> containers_only());
    return if ($container && $self -> items_only());

    $self -> UnselectAll();

    $data -> {selected} = $_sel || !$data -> {selected};
    $self -> SUPER::SetPlData( $item, $data );

    my $imagename;
    if ($data -> {container} || $self -> ItemHasChildren ($item)) {
        $imagename = $data -> {selected} ? TC_IMG_C_SELECTED : TC_IMG_C_NORMAL;
        $self -> _update_children($item, $data -> {selected})
                unless $self -> no_recurse;
    } else {
        $imagename = $data -> {selected} ? TC_IMG_SELECTED : TC_IMG_NORMAL;
    }

    my $treeroot = $self -> GetRootItem;
    $imagename = $treeroot == $item ? $data->{selected} ? TC_IMG_ROOT_SELECTED
            : TC_IMG_ROOT : $imagename;

    $self -> SetItemImage($item, $imagename);
    $self -> SetItemImage($item, $imagename, wxTreeItemIcon_Selected);
}

##############################################################################
# Private methods


sub _update_children {
    my ($self, $item, $selected) = @_;

    return unless $self -> ItemHasChildren ($item);
    my $i_children = $self -> GetChildrenCount ($item, 0);

    my (@children, $num_sel, $cookie);
    for ( 1 .. $i_children ) {
        my $child_id;
        if ($_ == 1) {
            ($child_id, $cookie) = $self -> GetFirstChild ($item);
        } else {
            ($child_id, $cookie) = $self -> GetNextChild ($item, $cookie);
        }
        push @children, $child_id;
    }

    foreach my $child_id ( @children ) {
        my $data = $self -> SUPER::GetPlData ($child_id);
        $data -> {selected} = $selected;
        $self -> SUPER::SetPlData ($child_id, $data);

        my $imagename;
        if ($data -> {container} || $self -> ItemHasChildren ($child_id)) {
            $imagename = $data -> {selected} ? TC_IMG_C_SELECTED : TC_IMG_C_NORMAL;
            $self -> _update_children($child_id, $selected);
        } else {
            $imagename = $data -> {selected} ? TC_IMG_SELECTED : TC_IMG_NORMAL;
        }

        $self -> SetItemImage($child_id, $imagename);
        $self -> SetItemImage($child_id, $imagename, wxTreeItemIcon_Selected);
    }

}


sub _update_parents {
    my ($self, $item) = @_;

    my $parent = $self -> GetItemParent ($item);
    return unless $parent;
    my $parent_data = $self -> SUPER::GetPlData ($parent);

    # check if all of the children are selected:
    return unless $self -> ItemHasChildren ($parent);
    my $i_children = $self -> GetChildrenCount ($parent, 0);

    my $cookie = int rand 1000;
    my (@children, $num_sel);

    for ( 1 .. $i_children ) {
        my $child_id;
        if ($_ == 1) {
            ($child_id, $cookie) = $self -> GetFirstChild ($parent);
        } else {
            ($child_id, $cookie) = $self -> GetNextChild ($parent, $cookie);
        }
        push @children, $child_id;
    }

    my @selected = map { $self -> SUPER::GetPlData($_)->{selected} } @children;
    $num_sel = scalar grep $_ >= 1, @selected;
    my $fully_selected  = scalar grep $_ == 1, @selected;

    my $imagename;
    my $_isroot = $self -> GetRootItem() == $parent;
    if ($num_sel == 0) {
        $imagename = $_isroot ? TC_IMG_ROOT : TC_IMG_C_NORMAL;
        $parent_data->{selected} = 0;
    } elsif ($num_sel == $i_children && $fully_selected == $num_sel) {
        $imagename = $_isroot ? TC_IMG_ROOT_SELECTED : TC_IMG_C_SELECTED;
        $parent_data->{selected} = TC_SELECTED;
    } else {
        $imagename = $_isroot ? TC_IMG_ROOT_PART_SELECTED
                : TC_IMG_C_PART_SELECTED;
        $parent_data->{selected} = TC_PART_SELECTED;
    }

    $self -> SUPER::SetPlData( $parent, $parent_data );
    $self -> SetItemImage($parent, $imagename);
    $self -> SetItemImage($parent, $imagename, wxTreeItemIcon_Selected);

    $self -> _update_parents ($parent);
}

sub _get_selected{
    my $self = shift;
    my ($style, $item) = @_;

    $style ||= TC_SEL_FULL;
    $item  ||= $self -> GetRootItem();

    my @_selected;
    my $data = $self -> SUPER::GetPlData( $item );
    my $container = $data  -> {container} || $self -> ItemHasChildren ($item);

    if ($container && $data -> {selected}) {
        if ($style == TC_SEL_COMPACT && $data -> {selected} == TC_SELECTED) {
            return $item;
        } elsif ($style == TC_SEL_FULL) {
            if ($data -> {selected} == TC_SELECTED) {
                return $item if $self -> no_recurse;
            }
            push @_selected, $item;
        }
    } elsif ($container) {
        # if allow_multiple is true and the container isn't selected, then none
        # of its children are
        return () if $self -> allow_multiple;
    } else {
        return $data -> {selected} ? $item : ();
    }

    # Now we recurse for all our children...
    my $i_children = $self -> GetChildrenCount ($item, 0);

    my ($cookie);
    for ( 1 .. $i_children ) {
        my $child_id;
        if ($_ == 1) {
            ($child_id, $cookie) = $self -> GetFirstChild ($item);
        } else {
            ($child_id, $cookie) = $self -> GetNextChild ($item, $cookie);
        }
        my @c_selected = $self -> _get_selected ($style, $child_id);
        push @_selected, @c_selected if @c_selected;
    }
    return @_selected;
}


sub _makedata {
    my $self = shift;
    my ($data, $container) = @_;

    if (ref $data && UNIVERSAL::isa($data, 'Wx::TreeItemData')) {
        $data = $data -> GetData;
    }

    $container = 0 unless defined $container;
    my $_data = {
                container => $container,
                selected  => 0,
                _USERDATA => $data,
               };
    return new Wx::TreeItemData($_data);
}

##############################################################################
# Default Icons - XPM

sub std_icons {
    Wx::Image::AddHandler( new Wx::XPMHandler() );
    my @icons;
    push @icons, Wx::Icon->newFromXPM (_empty_checkbox());
    push @icons, Wx::Icon->newFromXPM (_ticked_checkbox());
    push @icons, Wx::Icon->newFromXPM (_grey_checkbox());

    return @icons;
}

sub _default_images {
    my $self = shift;

    my ($_empty_xpm, $_ticked_xpm, $_part_xpm) = $self -> std_icons();
    my $_images = new Wx::ImageList (16, 16, 1);

    $_images -> Add( $_empty_xpm );
    $_images -> Add( $_ticked_xpm );
    $_images -> Add( $_part_xpm );
    $_images -> Add( $_empty_xpm );
    $_images -> Add( $_ticked_xpm );
    $_images -> Add( $_part_xpm );
    $_images -> Add( $_empty_xpm );
    $_images -> Add( $_ticked_xpm );
    $_images -> Add( $_part_xpm );
    return $_images;
}


sub _empty_checkbox {
    my $icon = [ map { m/^"(.*)"/ ? ( $1 ) : () } split /\n/, <<'EOT_E' ];
/* XPM */
static char * emptycheckbox_xpm[] = {
"16 16 2 1",
" 	c None",
".	c Black",
"                ",
" .............. ",
" .            . ",
" .            . ",
" .            . ",
" .            . ",
" .            . ",
" .            . ",
" .            . ",
" .            . ",
" .            . ",
" .            . ",
" .            . ",
" .            . ",
" .............. ",
"                "};
EOT_E
    return $icon
}

sub _ticked_checkbox {
    my $icon = [ map { m/^"(.*)"/ ? ( $1 ) : () } split /\n/, <<'EOT_P' ];
/* XPM */
static char * tickedcheckbox_xpm[] = {
"16 16 3 1",
" 	c None",
".	c Black",
"o	c Gray20",
"                ",
" .............. ",
" .oooooooooooo. ",
" .oooooooooooo. ",
" .oooooooooooo. ",
" .oooooooooooo. ",
" .oooooooooooo. ",
" .oooooooooooo. ",
" .oooooooooooo. ",
" .oooooooooooo. ",
" .oooooooooooo. ",
" .oooooooooooo. ",
" .oooooooooooo. ",
" .oooooooooooo. ",
" .............. ",
"                "};
EOT_P
    return $icon

}

sub _grey_checkbox {
    my $self = shift;
    my @checkbox = @{_ticked_checkbox()};
    $checkbox[3] = 'o	c Gray60';
    return \@checkbox
}


1;

=pod

=head1 NAME

Wx::Perl::TreeChecker - Tree Control with checkbox functionality

=head1 SYNOPSIS

  use Wx::Perl::TreeChecker;
  my $tree = new Wx::Perl::TreeChecker( ... );
  $tree -> allow_multiple(0);
  $tree -> items_only(1);
  # use tree like a normal treectrl

  my $tree = new Wx::TreeCtrl();
  Wx::Perl::TreeChecker->Convert($tree, $options)

  my @selection = $tree->GetSelection();

=head1 DESCRIPTION

Wx::Perl::TreeChecker is a tree control with check boxes so users can select parts of the tree.

A typical use would be a file-selector for backup / archive.

=head1 EXPORTS

Exports C<TC_SELECTED> and C<TC_PART_SELECTED> which correspond to the status
returned by

  $tree -> IsSelected($item)

C<TC_SEL_FULL> and C<TC_SEL_COMPACT> are also exported. See
L<"GetSelection(STYLE)"> for more information.

You can export these constants with the ':status' import tag:

  use Wx::Perl::TreeChecker ':status';

=head1 METHODS

The methods listed here are only where there are syntactic differences to
C<Wx::TreeCtrl>

=over 4

=item new (@std_args, \%treechecker)

Where C<@std_args> are the regular arguments that you would pass to
C<Wx::TreeCtrl-E<gt>new()>.

C<%treechecker> is an optional hash of options that customise the way that
C<Wx::Perl::TreeChecker> behaves. Valid keys:

  allow_multiple      # can multiple selections be made (default: TRUE)
  containers_only     # user can only select containers (default: FALSE)
  items_only          # user can only select items      (default: FALSE)
  no_recurse          # no recursion when user selects node (default: FALSE)
  image_list          # Wx::ImageList to use for checkbox icons
                      #     (default provided)

=item Convert (Wx::TreeCtrl, HASHREF)

Converts a standard C<Wx::TreeCtrl> into a C<Wx::Perl::TreeChecker>

The first argument is a C<Wx::TreeCtrl>. The seconds argument is an optional
hashref as C<new()>.

=item AddRoot ($text, $data)

Add a root to the control. Returns root id.

As C<Wx::TextCtrl::AddRoot>, but image indices are removed

=item AppendItem ($parent, $text, $data)

Add an item to the control as the last child of C<$parent>. Returns item id.

As C<Wx::TextCtrl::AppendItem>, but image indices are removed

=item AppendContainer ($parent, $text, $data)

Add a container to the control as the last child of C<$parent>. This does the
same as C<AppendItem()> but marks the node as a container.

=item PrependItem ($parent, $text, $data)

Add an item to the control as the first child of C<$parent>. Returns item id.

=item PrependContainer ($parent, $text, $data)

Add a container to the control as the first child of C<$parent>.

=item InsertItem ($parent, $before | $previous, $text, $data)

Inserts an item after a given one (previous) or before one identified by
its position (before).

=item InsertContainer ($parent, $before | $previous, $text, $data)

See InsertItem().

=item GetSelection(STYLE)

Returns a list of selected C<Wx::TreeItemId>s. The behaviour can be controlled by the C<STYLE> and the behaviour of the object (C<containers_only>,
C<no_recurse>, etc).

Allowed styles are;

=over 4

=item C<TC_SEL_FULL>

The default if GetSelection is called without a C<STYLE>. It returns
all tree items that are checked (C<TC_SELECTED> and C<TC_PART_SELECTED>)

=item C<TC_SEL_COMPACT>

This returns a compact list. If a Container item is C<TC_SELECTED>, it
will be returned in place of it's child items. Containers that are
C<TC_PART_SELECTED> are not returned.

=back

=item IsSelected ($item)

returns the selection status of the item. See Exported flags.

=item IsContainer ($item)

returns TRUE if the item is a container

=item SelectItem ($item)

Select the item, returns TRUE if the item was selected.

=item UnSelectItem ($item)

Clear the selction of the item

=item UnselectAll()

Clear the selections on the tree

=item allow_multiple (BOOL)

see C<new()>

=item containers_only (BOOL)

see C<new()>

=item items_only (BOOL)

see C<new()>

=item no_recurse (BOOL)

see C<new()>

=back

=head1 XRC

See L<Wx::Perl::TreeChecker::XmlHandler>

=head1 CHECKBOX IMAGES

A default set of checkbox icons are included. You can override these by
supplying a C<Wx::ImageList> to the constructor or the C<SetImageList> method.

=over 4

=item std_icons()

This class method returns the three standard icons that you can mix with your
own icons.

  my ($empty, $ticked, $part_selected) = Wx::Perl::TreeChecker->std_icons();

=back

The Image list must contain 8 icons, 16 x 16 pixels:

  Image number             Image description
  ------------------------------------------------------------------------
      0                    The root icon
      1                    Selected root icon
      2                    Part-selected root icon
      3                    Container icon
      4                    Selected container icon
      5                    Part-selected container icon
      6                    Item icon
      7                    Selected item icon

=head1 EXAMPLES

See F<demo/treechecker.pl>

=head1 AUTHOR

Simon Flack E<lt>simonflk _AT_ cpan.orgE<gt>

=head1 BUGS

I can squash more bugs with your help. Please let me know if you spot something
that doesn't work as expected.

You can report bugs via the CPAN RT:
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Wx-Perl-TreeChecker>

If possible, please provide a diff against the test files or sample script that
demonstrates the bug(s).

=head1 SEE ALSO

wxWindows: wxTreeCtrl

wxPerl L<http://wxperl.sourceforge.net>

=head1 COPYRIGHT

Copyright (c) 2003, 2004, 2005  Simon Flack E<lt>simonflk _AT_ cpan.orgE<gt>.
All rights reserved

You may distribute under the terms of either the GNU General Public License or
the Artistic License, as specified in the Perl README file.

=cut
