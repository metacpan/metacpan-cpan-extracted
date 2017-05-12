#!../xperl -w

use blib;

use strict;
use Sys::Hostname;
use IO::Handle;
use X11::Motif;
use X11::XRT;
use PDM;

require "./cpsc-tree.pl";

STDERR->autoflush(1);

my $session;

#if ($session = PDM::Login('kfox', 'kfox')) {
#    PDM::SetQueryScope($session, "-", qw(aec));
#}
#else {
#    die "Can't login to Metaphase\n";
#}

my $menu_font = '-*-helvetica-medium-o-*-*-*-180-*-*-*-*-*-*';
my $label_font = '-*-helvetica-medium-r-*-*-*-180-*-*-*-*-*-*';
my $input_font = '-*-courier-medium-r-*-*-*-180-*-*-*-*-*-*';

sub IS_FOLDER ()   {  1 }; # -flags -- item is a folder
sub IS_FILTERED () {  2 }; # -flags -- item is filtered out (not in the outline)
sub IS_OPENED ()   {  4 }; # -flags -- item is open (folder contents displayed)
sub IS_CACHED ()   {  8 }; # -flags -- item is cached in memory (loaded from external source)
sub IS_SELECTED () { 16 }; # -flags -- item is selected

my $toplevel = X::Toolkit::initialize('PTODataManager');
change $toplevel -title => 'PTO Data Manager';

$toplevel->set_inherited_resources("*fontList" => $label_font,
				   "*menubar*fontList" => $menu_font,
				   "*XmTextField.fontList" => $input_font);

my $form = give $toplevel -Form;

my $local_tree = load_initial_local_tree();
my @local_selection = ();

my $remote_tree = load_initial_remote_tree();
my @remote_selection = ();

load_startup();

my $menubar = give $form -MenuBar, -name => 'menubar';
my $menu;
my $submenu;

$menu = give $menubar -Menu, -name => 'File';
	$submenu = give $menu -Menu, -text => 'Create New';
		   give $submenu -Button, -text => 'Folder';
		   give $submenu -Button, -text => 'File';
		   give $submenu -Button, -text => 'Note';
		   give $submenu -Separator;
		   give $submenu -Button, -text => 'Analysis';
	give $menu -Separator;
	give $menu -Button, -text => 'Check In';
	give $menu -Button, -text => 'Check Out';
	give $menu -Button, -text => 'Delete';
	give $menu -Separator;
	give $menu -Button, -text => 'Switch Database';
	give $menu -Separator;
	give $menu -Button, -text => 'Print', -command => sub { print_opened_items($local_tree) };
	give $menu -Separator;
	give $menu -Button, -text => 'Exit', -command => \&do_exit;

$menu = give $menubar -Menu, -name => 'Options';
	give $menu -Button, -text => 'Data Filters ...', -command => \&do_filter;
	give $menu -Separator;
	give $menu -Button, -text => 'File Types ...';
	give $menu -Button, -text => 'Storage Locations ...';
	give $menu -Button, -text => 'Display ...';
	give $menu -Separator;
	give $menu -Button, -text => 'Save Current Options';

$menu = give $menubar -Menu, -name => 'Help';
	give $menu -Button, -text => 'Putting Files In';
	give $menu -Button, -text => 'Getting Files Out';
	give $menu -Button, -text => 'Sharing Files';
	give $menu -Separator;
	give $menu -Button, -text => 'Choosing What To View';
	give $menu -Separator;
	give $menu -Button, -text => 'About Metaphase';
	give $menu -Button, -text => 'About PTO Data Browser';

my $pane = give $form -Pane,
			-sashWidth => 16,
			-sashHeight => 8,
			-spacing => 12,
			-sashIndent => -20;

my $local_outline = give $pane -Outline,
			-name => 'local_outline',
			-xrtGearSelectionPolicy => X::XRT::XRTGEAR_SELECTION_POLICY_MULTIPLE_AUTO_UNSELECT,
			-xrtGearScrollBarVertDisplayPolicy => X::XRT::XRTGEAR_DISPLAY_ALWAYS,
			-xrtGearFolderStateCallback => [\&do_folder_state_changed, $local_tree],
			-xrtGearActivateCallback => \&do_item_activated,
			-xrtGearSelectionCallback => [\&do_item_selected, $local_tree];

my $remote_outline = give $pane -Outline,
			-name => 'remote_outline',
			-xrtGearSelectionPolicy => X::XRT::XRTGEAR_SELECTION_POLICY_MULTIPLE_AUTO_UNSELECT,
			-xrtGearScrollBarVertDisplayPolicy => X::XRT::XRTGEAR_DISPLAY_ALWAYS,
			-xrtGearFolderStateCallback => [\&do_folder_state_changed, $remote_tree],
			-xrtGearActivateCallback => \&do_item_activated,
			-xrtGearSelectionCallback => [\&do_item_selected, $remote_tree];

create_outline($local_outline, $local_tree);
create_outline($remote_outline, $remote_tree);

constrain $menubar -top => -form, -left => -form, -right => -form;
constrain $pane -top => $menubar, -bottom => -form, -left => -form, -right => -form;

handle $toplevel;

# --------------------------------------------------------------------------------

sub load_initial_local_tree {
    return { -label => 'TOP',
	     -flags => IS_FOLDER | IS_OPENED | IS_CACHED,
	     -children => [ { -label => 'Home Directory',
			      -path => $ENV{HOME},
			      -load => \&hook_load_path,
			      -flags => IS_FOLDER },
			    { -label => 'System '.Sys::Hostname::hostname(),
			      -path => '/',
			      -load => \&hook_load_path,
			      -flags => IS_FOLDER | IS_FILTERED } ] };
}

sub load_initial_remote_tree {
    return { -label => 'TOP',
	     -flags => IS_FOLDER | IS_OPENED | IS_CACHED,
	     -children => [ { -label => 'CPSC Systems',
			      -children => load_cpsc_nodes(),
			      -load => \&hook_load_cpsc,
			      -flags => IS_FOLDER | IS_OPENED | IS_CACHED },
			    { -label => 'CAE Chunks',
			      -load => \&hook_load_chunks,
			      -flags => IS_FOLDER },
			    { -label => 'Personal Storage',
			      -load => \&hook_load_users,
			      -flags => IS_FOLDER } ] };
}

sub load_startup() {
}

# --------------------------------------------------------------------------------

sub hook_load_path {
    my($element) = @_;
    my $path = $element->{-path};

    return unless chdir($path);

    if (opendir(DIR, '.')) {
	my @dirs = ();
	my @files = ();
	foreach (readdir(DIR)) {
	    next if ($_ eq '.' or $_ eq '..');
	    if (-d $_) {
		push @dirs, $_;
	    }
	    else {
		push @files, $_;
	    }
	}
	closedir(DIR);
	foreach (sort @dirs) {
	    add_child_element($element,
			      { -label => $_,
				-path => "$path/$_",
				-flags => IS_FOLDER });
	}
	foreach (sort @files) {
	    add_child_element($element,
			      { -label => $_,
				-path => "$path/$_",
				-flags => 0 });
	}
    }
}

sub hook_load_cpsc {
    print "hook_load_cpsc\n";
}

sub hook_load_chunks {
    print "hook_load_chunks\n";
}

sub hook_load_users {
    print "hook_load_users\n";
}

# --------------------------------------------------------------------------------

my $_traversal_flags;
my $_traversal_sub;
my $_traversal_not;
my $_traversal_continue;
my $_traversal_always_descend;

sub _traverse_tree {
    my($parent, $parent_return) = @_;

    my $sibling_return;
    my $child_id = 0;

    foreach my $child (@{$parent->{-children}}) {
	if (!defined($_traversal_flags) or ($_traversal_not xor $child->{-flags} & $_traversal_flags)) {
	    $_traversal_continue = 1;

	    $sibling_return = &{$_traversal_sub}($parent, $child, $child_id,
						 $parent_return, $sibling_return);

	    if ($_traversal_continue && ($child->{-flags} & IS_FOLDER)) {
		_traverse_tree($child, $sibling_return);
	    }
	}
	elsif ($_traversal_always_descend) {
	    if ($child->{-flags} & IS_FOLDER) {
		_traverse_tree($child, $parent_return);
	    }
	}

	++$child_id;
    }
}

sub traverse_tree {
    my($parent, $sub, $flags, $parent_return) = @_;

    $_traversal_flags = $flags;
    $_traversal_sub = $sub;
    $_traversal_not = 0;
    $_traversal_always_descend = 1;

    _traverse_tree($parent, $parent_return);
}

sub traverse_tree_not {
    my($parent, $sub, $flags, $parent_return) = @_;

    $_traversal_flags = $flags;
    $_traversal_sub = $sub;
    $_traversal_not = 1;
    $_traversal_always_descend = 1;

    _traverse_tree($parent, $parent_return);
}

sub traverse_pruned_tree {
    my($parent, $sub, $flags, $parent_return) = @_;

    $_traversal_flags = $flags;
    $_traversal_sub = $sub;
    $_traversal_not = 0;
    $_traversal_always_descend = 0;

    _traverse_tree($parent, $parent_return);
}

sub traverse_pruned_tree_not {
    my($parent, $sub, $flags, $parent_return) = @_;

    $_traversal_flags = $flags;
    $_traversal_sub = $sub;
    $_traversal_not = 1;
    $_traversal_always_descend = 0;

    _traverse_tree($parent, $parent_return);
}

# --------------------------------------------------------------------------------

sub _create_outline {
    my($parent, $child, $child_id, $parent_return, $sibling_return) = @_;

    my $node;

    if ($child->{-flags} & IS_FOLDER) {
	print STDERR "adding folder $child->{-label}\n";
	$node = give $parent_return -OutlineFolder,
			-userData => $child_id,
			-xrtGearLabel => $child->{-label},
			-xrtGearFolderState => opened_state_of_element($child);
    }
    else {
	print STDERR "adding node $child->{-label}\n";
	$node = give $parent_return -OutlineNode,
			-userData => $child_id,
			-xrtGearLabel => $child->{-label};
    }

    $node;
}

sub create_outline {
    my($outline, $tree) = @_;

    my $w = X::XRT::XrtGearNodeGetWidgetParent($outline);

    print STDERR "create_outline w = $w (", $w->XtName, "--", $w->XtClass->name, ")\n";

    change $w -xrtGearRepaint => 0;
    print STDERR "  repaint turned off\n";
    traverse_pruned_tree_not($tree, \&_create_outline, IS_FILTERED, $outline);
    print STDERR "  outliner node widgets created\n";
    change $w -xrtGearRepaint => 1;
    print STDERR "  repaint turned on\n";
}

sub _print_opened_items {
    my($parent, $child) = @_;

    print "node $child->{-label} is open\n";
}

sub print_opened_items {
    my($tree) = @_;

    traverse_pruned_tree($tree, \&_print_opened_items, IS_OPENED);
}

# --------------------------------------------------------------------------------

sub opened_state_of_element {
    my($element) = @_;

    ($element->{-flags} & IS_OPENED) ?
	X::XRT::XRTGEAR_FOLDERSTATE_OPEN_ALL :
	X::XRT::XRTGEAR_FOLDERSTATE_CLOSED;
}

sub add_child_element {
    my($tree, $child) = @_;

    push @{$tree->{-children}}, $child;
}

sub get_tree_element {
    my $tree = shift;

    if (wantarray) {
	my $hook_load;
	foreach my $i (@_) {
	    $tree = $tree->{-children}[$i];
	    $hook_load = $tree->{-load} if (defined $tree->{-load});
	}
	return ($tree, $hook_load);
    }
    else {
	foreach my $i (@_) {
	    $tree = $tree->{-children}[$i];
	}
	return $tree;
    }
}

sub get_path_to_node {
    my($w) = @_;
    my @path = ();

    while (X::XRT::XmIsXrtNode($w)) {
	unshift @path, query $w -userData;
	$w = $w->XtParent;
    }

    @path;
}

# --------------------------------------------------------------------------------

sub do_folder_state_changed {
    my($w, $client, $call) = @_;

    return if ($call->reason != X::XRT::XRTGEAR_REASON_FOLDER_CHANGE_BEGIN);

    my($element, $hook_load) = get_tree_element($client, get_path_to_node($call->node));

    print "tree = $element->{-label}\n";

    if ($call->new_state == X::XRT::XRTGEAR_FOLDERSTATE_OPEN_ALL) {
	if (!($element->{-flags} & IS_CACHED)) {
	    print "  *** loading contents dynamically ***\n";

	    &{$hook_load}($element);
	    create_outline($call->node, $element);

	    $element->{-flags} |= IS_CACHED;
	}

	$element->{-flags} |= IS_OPENED;
    }
    else {
	$element->{-flags} &= ~IS_OPENED;
    }
}

sub do_item_activated {
    my($w, $client, $call) = @_;
}

sub do_item_selected {
    my($w, $client, $call) = @_;

    return if ($call->reason == X::XRT::XRTGEAR_REASON_SELECT_END ||
	       $call->reason == X::XRT::XRTGEAR_REASON_UNSELECT_END);

    my $element = get_tree_element($client, get_path_to_node($call->node));
    my $state;

    if ($call->reason == X::XRT::XRTGEAR_REASON_SELECT_BEGIN) {
	$state = 1;
	if (query {$call->node} -xrtGearSelected) {
	    change {$call->node} -xrtGearSelected => 0;
	    $state = 0;
	}
    }
    else {
	$state = 0;
    }

    if ($state) {
	print "select node = $element->{-label}\n";
	$element->{-flags} |= IS_SELECTED;
    }
    else {
	print "un-select node = $element->{-label}\n";
	$element->{-flags} &= ~IS_SELECTED;
    }
}

# --------------------------------------------------------------------------------

sub do_exit {
    my($w) = @_;

    #PDM::Logout($session);
    exit;
}

# --------------------------------------------------------------------------------

my @_selected_items;

sub _push_selected_items {
    my($parent, $child, $child_id) = @_;
    push @_selected_items, $child;
}

sub get_selected_items {
    my($tree) = @_;
    @_selected_items = ();
    traverse_tree($tree, \&_push_selected_items, IS_SELECTED);
    @_selected_items;
}

sub get_selected_items_or_root {
    my($tree) = @_;
    @_selected_items = ();
    traverse_tree($tree, \&_push_selected_items, IS_SELECTED);
    return @_selected_items if (@_selected_items);
    $tree;
}

# --------------------------------------------------------------------------------

sub _filter_items {
    my($parent, $child) = @_;

    my $path = $child->{-path};
    my $label = $child->{-label};

    if (defined $path && ($label =~ /^\./ || $label =~ /^#/)) {
	$child->{-flags} |= IS_FILTERED;
    }

    $child->{-flags} &= ~IS_SELECTED;
}

sub do_filter {
    traverse_tree($local_tree, \&_filter_items);
    traverse_tree($remote_tree, \&_filter_items);

    change $local_outline -xrtGearRepaint => 0;
    change $remote_outline -xrtGearRepaint => 0;

    foreach (@{query $local_outline -xrtGearNodeChildList},
	     @{query $remote_outline -xrtGearNodeChildList})
    {
	print STDERR "destroying $_\n";
	$_->XtDestroyWidget();
    }

    print STDERR "done destroying. now creating.\n";

    create_outline($local_outline, $local_tree);
    create_outline($remote_outline, $remote_tree);

    print STDERR "done.\n";
}
