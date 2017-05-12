package Outline;

use strict;
use X11::Motif;

sub IS_SELECTED () {  1 }; # -flags -- item is selected
sub IS_OPENED ()   {  2 }; # -flags -- item is open (folder contents displayed)
sub IS_FILTERED () {  4 }; # -flags -- item is filtered out (not in the outline)
sub IS_CACHED ()   {  8 }; # -flags -- item is cached in memory (loaded from external source)
sub IS_FOLDER ()   { 16 }; # -flags -- item is a folder
sub IS_ANCHOR ()   { 32 }; # -flags -- item is an anchor point for determining relative paths
sub IS_KEPT ()     { 64 }; # -flags -- item is kept even when throwning out the cache

sub new {
    my $class = shift;
    my $parent = shift;

    my $outline = [ ];
    my $self = {
	-tree => { -label => 'TOP',
		   -flags => IS_FOLDER | IS_OPENED | IS_CACHED,
		   -children => [ ] },
	-currentitem => undef,
	-outline => $outline,
	-widget => undef,
	-menu => undef,
	-lastpick => undef,
	-selection => [ ]
    };

    bless $self, $class;

    if (defined $parent) {
	my $scrolled_window = $parent->give(-ScrolledWindow);
	my $columns = shift;
	my $lined_area = $scrolled_window->give(-XpLinedArea, @_);
	my $i = 0;

	foreach my $col (@{$columns}) {
	    $lined_area->XpLinedAreaInsertOutlineColumn($i, $col, $self, \&Outline::handle_event);
	    ++$i;
	}

	$self->{-widget} = $lined_area;
    }

    $self;
}

sub import {
    my $module = shift;

    foreach my $sym (@_) {
	if ($sym eq ':flags') {
	    X11::Lib::export_pattern(\%Outline::, '^IS_');
	}
	else {
	    X11::Lib::export_symbol(\%Outline::, $sym);
	}
    }
}

sub canvas () {
    my $self = shift;

    $self->{-widget};
}

sub window () {
    my $self = shift;

    $self->{-widget}->XtParent;
}

sub register_popup_menu {
    my($self, $menu) = @_;

    $self->{-menu} = $menu;
}

sub redraw {
    my($self) = @_;

    my $w = $self->{-widget};
    if (defined $w) {
	$w->XpLinedAreaRedraw;
    }
}

# --------------------------------------------------------------------------------

my $_traversal_flags;
my $_traversal_sub;
my $_traversal_not;
my $_traversal_continue;
my $_traversal_always_descend;
my $_traversal_level;

sub _traverse_tree {
    my($parent, $parent_return) = @_;

    my $sibling_return;
    my $child_id = 0;

    foreach my $child (@{$parent->{-children}}) {
	if (!defined($_traversal_flags) or ($_traversal_not xor ($child->{-flags} & $_traversal_flags))) {
	    $_traversal_continue = 1;

	    $sibling_return = &{$_traversal_sub}($parent, $child, $child_id,
						 $parent_return, $sibling_return);

	    if ($_traversal_continue && ($child->{-flags} & IS_FOLDER)) {
		++$_traversal_level;
		_traverse_tree($child, $sibling_return);
		--$_traversal_level;
	    }
	}
	elsif ($_traversal_always_descend) {
	    if ($child->{-flags} & IS_FOLDER) {
		++$_traversal_level;
		_traverse_tree($child, $parent_return);
		--$_traversal_level;
	    }
	}

	++$child_id;
    }
}

sub _fast_traverse_tree {
    my($parent) = @_;

    foreach my $child (@{$parent->{-children}}) {
	&{$_traversal_sub}($parent, $child);
	if ($child->{-flags} & IS_FOLDER) {
	    _fast_traverse_tree($child);
	}
    }
}

sub traverse {
    my($self, $sub, $flags, $parent_return) = @_;

    $_traversal_flags = $flags;
    $_traversal_sub = $sub;
    $_traversal_not = 0;
    $_traversal_always_descend = 1;
    $_traversal_level = 0;

    _traverse_tree($self->{-tree}, $parent_return);
}

sub fast_traverse {
    my($tree, $sub) = @_;

    $_traversal_sub = $sub;

    _fast_traverse_tree($tree);
}

sub traverse_not {
    my($self, $sub, $flags, $parent_return) = @_;

    $_traversal_flags = $flags;
    $_traversal_sub = $sub;
    $_traversal_not = 1;
    $_traversal_always_descend = 1;
    $_traversal_level = 0;

    _traverse_tree($self->{-tree}, $parent_return);
}

sub traverse_pruned {
    my($self, $sub, $flags, $parent_return) = @_;

    $_traversal_flags = $flags;
    $_traversal_sub = $sub;
    $_traversal_not = 0;
    $_traversal_always_descend = 0;
    $_traversal_level = 0;

    _traverse_tree($self->{-tree}, $parent_return);
}

sub traverse_pruned_not {
    my($self, $sub, $flags, $parent_return) = @_;

    $_traversal_flags = $flags;
    $_traversal_sub = $sub;
    $_traversal_not = 1;
    $_traversal_always_descend = 0;
    $_traversal_level = 0;

    _traverse_tree($self->{-tree}, $parent_return);
}

# --------------------------------------------------------------------------------

sub add_toplevel {
    my $self = shift;

    foreach my $child (@_) {
	$self->add_child($self->{-tree}, $child);
    }
}

my $_reformat_outline;

sub _reformat {
    my($parent, $child) = @_;

    $child->{-indent} = $_traversal_level;
    $child->{-parent} = $parent;
    $child->{-row} = @{$_reformat_outline};

    push @{$_reformat_outline}, $child;

    if (!($child->{-flags} & IS_OPENED)) {
	$_traversal_continue = 0;
    }
}

sub reformat {
    my($self, $child) = @_;
    my $outline = $self->{-outline};
    my $widget = $self->{-widget};

    @{$outline} = ();
    $_reformat_outline = $outline;

    $self->traverse_pruned_not(\&_reformat, IS_FILTERED);

    if (defined $widget) {
	$widget->XpLinedAreaSetRows(0, scalar @{$outline});
	if ($child) {
	    $widget->XpLinedAreaScrollToRow($child->{-row} - 1);
	}
    }
}

sub _reparent {
    my($parent, $child) = @_;

    $child->{-parent} = $parent;
}

sub reparent {
    my($self, $tree) = @_;

    fast_traverse($tree, \&_reparent);
}

# --------------------------------------------------------------------------------

sub get_hooks {
    my($item) = @_;

    my $hook_load;
    my $hook_autosel;
    my $found = 0;

    while (defined $item) {
	if (!defined($hook_load) && defined($item->{-load})) {
	    $hook_load = $item->{-load};
	    ++$found;
	}
	if (!defined($hook_autosel) && defined($item->{-autosel})) {
	    $hook_autosel = $item->{-autosel};
	    ++$found;
	}
	last if ($found == 2);
	$item = $item->{-parent};
    }

    return ($hook_load, $hook_autosel);
}

sub get_row {
    my($self, $row) = @_;
    return $self->{-outline}[$row];
}

sub add_child {
    my($self, $tree, $child) = @_;

    $child->{-parent} = $tree;
    push @{$tree->{-children}}, $child;

    if (exists $child->{-children}) {
	$self->reparent($child);
    }
}

sub _forget_cache {
    my($parent, $child) = @_;

    my @new_grandchildren = ();
    if ($child->{-flags} & IS_CACHED) {
	$child->{-flags} &= ~IS_CACHED;
	if (exists $child->{-children}) {
	    foreach my $grandchild (@{$child->{-children}}) {
		if ($grandchild->{-flags} & IS_KEPT) {
		    push @new_grandchildren, $grandchild;
		}
	    }

	    # This could (will?) cause a memory leak because
	    # children have references to their parent, i.e. this
	    # is a cyclic structure.  Perl won't garbage collect
	    # the children even though they've been taken out of
	    # the tree.

	    @{$child->{-children}} = @new_grandchildren;
	}
    }
}

sub forget_cache {
    my($self, $child) = @_;

    if (!defined $child) {
	_forget_cache($child->{-parent}, $self->{-tree});
	fast_traverse($self->{-tree}, \&_forget_cache);
	$self->{-tree}{-flags} |= IS_CACHED;
    }
    else {
	_forget_cache($child->{-parent}, $child);
	fast_traverse($child, \&_forget_cache);
    }
}

sub open_child {
    my($self, $child, $keep_open) = @_;

    $self->{-currentitem} = $child;

    my $flags = $child->{-flags};
    my($hook_load, $hook_autosel) = get_hooks($child);

    $flags &= ~IS_FILTERED;

    if ($flags & IS_FOLDER) {
	if (($flags & IS_OPENED) && !$keep_open) {
	    $child->{-flags} &= ~IS_OPENED;
	}
	else {
	    $flags |= IS_OPENED;

	    if (!($flags & IS_CACHED)) {
		&{$hook_load}($self, $child);
		$flags |= IS_CACHED;
	    }

	    $child->{-flags} = $flags;

	    if ($hook_autosel) {
		&{$hook_autosel}($self, $child);
	    }
	}
    }
}

sub do_by_name {
    my($self, $name, $sub) = @_;

    my $current_item = $self->{-currentitem};

    if (defined $current_item) {
	foreach my $child (@{$current_item->{-children}}) {
	    if ($child->{-label} =~ /^$name/) {
		&{$sub}($self, $child);
		return $child;
	    }
	}
    }

    0;
}

sub _open_child_by_name {
    my($self, $child) = @_;

    $self->open_child($child, 1);
}

sub open_child_by_name {
    my($self, $name) = @_;

    return $self->do_by_name($name, \&_open_child_by_name);
}

sub open_path_from_root {
    my $self = shift;

    $self->{-currentitem} = $self->{-tree};

    foreach my $name (@_) {
	return if (!$self->open_child_by_name($name));
    }

    $self->{-currentitem};
}

sub select_child {
    my($self, $child, $bit) = @_;

    $bit ||= IS_SELECTED;
    $child->{-flags} |= $bit;
}

sub _select_child_by_name {
    my($self, $child) = @_;

    $self->select_child($child);
}

sub select_child_by_name {
    my($self, $name) = @_;

    return $self->do_by_name($name, \&_select_child_by_name);
}

# --------------------------------------------------------------------------------

sub activate_row {
    my($self, $row) = @_;
    my $child = $self->get_row($row);

    if (defined $child) {
	$self->open_child($child);
	$self->reformat();
    }
}

# --------------------------------------------------------------------------------

my $_selected_bit;

sub _clear_bit {
    my($parent, $child) = @_;
    $child->{-flags} &= ~$_selected_bit;
}

sub clear_deep_selection {
    my($self, $bit) = @_;
    $_selected_bit = $bit || IS_SELECTED;
    $self->traverse(\&_clear_bit);
}

sub clear_selection {
    my($self, $bit) = @_;

    $bit ||= IS_SELECTED;
    foreach my $element (@{$self->{-outline}}) {
	$element->{-flags} &= ~$bit;
    }
}

sub row_is_selected {
    my($self, $row, $bit) = @_;
    my $element = $self->{-outline}[$row];

    if (defined $element) {
	$bit ||= IS_SELECTED;
	$element->{-flags} & $bit;
    }
}

sub select_row {
    my($self, $row, $bit) = @_;
    my $element = $self->{-outline}[$row];

    if (defined $element) {
	$bit ||= IS_SELECTED;
	$element->{-flags} |= $bit;
    }
}

sub clear_row {
    my($self, $row, $bit) = @_;
    my $element = $self->{-outline}[$row];

    if (defined $element) {
	$bit ||= IS_SELECTED;
	$element->{-flags} &= ~$bit;
    }
}

sub toggle_row {
    my($self, $row, $bit) = @_;
    my $element = $self->{-outline}[$row];

    if (defined $element) {
	my $flags = $element->{-flags};
	$bit ||= IS_SELECTED;

	if ($flags & $bit) {
	    $flags &= ~$bit;
	}
	else {
	    $flags |= $bit;
	}

	$element->{-flags} = $flags;
    }
}

sub selection {
    my($self, $bit) = @_;
    my @selected_items = ();

    $bit ||= IS_SELECTED;
    foreach my $element (@{$self->{-outline}}) {
	if ($element->{-flags} & $bit) {
	    push @selected_items, $element;
	}
    }
    @selected_items;
}

# --------------------------------------------------------------------------------

sub handle_event {
    my($w, $self, $event, $click, $row, $col) = @_;
    my $type = $event->type;
    my $redraw = 4;

    if ($type == X::ButtonRelease) {
	my $button = $event->button;
	my $state = $event->state;
	my $lastpick = $self->{-lastpick};

	if ($button == 1) {
	    if ($state & X::ShiftMask) {
		if (defined $lastpick) {
		    if (!($state & X::ControlMask)) {
			$self->clear_selection();
		    }
		    if ($row < $lastpick) {
			while ($row <= $lastpick) {
			    $self->select_row($row);
			    ++$row;
			}
		    }
		    else {
			while ($row >= $lastpick) {
			    $self->select_row($row);
			    --$row;
			}
		    }
		    $redraw = 2;
		}
	    }
	    elsif ($state & X::ControlMask) {
		$self->toggle_row($row);
		$self->{-lastpick} = $row;
		$redraw = 1;
	    }
	    else {
		# optimize the selection redraw quite a bit -- have the
		# clear_selection routine return the rows cleared and then only
		# redraw those rows. -- FIXME

		if ($event->time->delta($self->{-lasttime}) < 400) {
		    $self->activate_row($row);
		}
		else {
		    $self->clear_selection();
		    $self->select_row($row);
		}

		$self->{-lastpick} = $row;
		$self->{-lasttime} = $event->time;
		$redraw = 2;
	    }
	}
    }
    elsif ($type == X::ButtonPress) {
	my $button = $event->button;

	if ($button == 3) {
	    my $menu = $self->{-menu};

	    if (defined $menu) {
		X::Motif::XmMenuPosition($menu, $event);
		$menu->Manage();
	    }
	}
    }

    $redraw;
}

1;
