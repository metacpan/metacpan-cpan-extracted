package X11::Motif::URLChooser;

use Cwd;
use Net::Domain qw(hostfqdn);
use X11::Motif;

use strict;
use vars qw($VERSION @ISA);

$VERSION = 1.0;
@ISA = qw();

my %StorageTypes = ();

sub add_storage_type {
    my($type, $class) = @_;
    my $impl = {};

    bless $impl, $class;
    $StorageTypes{$type} = $impl;
}

sub new {
    my $self = shift;
    my $class = ref($self) || $self;
    my($location, $pattern) = @_;

    $self = {
	'hide_dots' => 1,
	'hide_emacs' => 1,
	'done' => 0,

	'glob' => undef,
	'filter' => undef,
	'selection' => undef,

	'host' => hostfqdn(),
	'dir' => getcwd(),

	'inactive_storage' => {},
	'storage' => undef,

	'active_pos' => 0,
	'visible_history' => [],
	'visible_file_list' => [],
	'filtered_file_list' => [],
	'visible_dir_list' => [],
	'filtered_dir_list' => [],

	'dialog_shell' => undef
    };

    bless $self, $class;

    $self->switch_to($location);
    $self->set_filter($pattern);
    $self->reload();

    $self;
}

sub popup {
    my $self = shift;
    my $shell = $self->{'dialog_shell'};

    if (!defined $shell) {
	my($toplevel, $dialog_title, $arg);

	while (defined($arg = shift)) {
	    if (X::Toolkit::Widget::IsWidget($arg)) {
		$toplevel = $arg;
	    }
	    else {
		$dialog_title = $arg;
	    }
	}

	$toplevel = X::Toolkit::toplevel() if (!defined $toplevel);
	$dialog_title = "Choose a File" if (!defined $dialog_title);

	my $dialog = $self->create_dialog($toplevel, $dialog_title);

	$dialog->ManageChild();
	$shell = $dialog->Parent();
    }

    $shell->Popup(X::Toolkit::GrabNonexclusive);
    $self->redisplay();

    $self->{'done'} = 0;

    $shell;
}

sub popdown {
    my $self = shift;
    my $shell = $self->{'dialog_shell'};

    if (defined $shell) {
	$shell->Popdown();
    }

    $self->{'done'} = -1;
}

sub destroy {
    my $self = shift;
    my $shell = $self->{'dialog_shell'};

    if (defined $shell) {
	$shell->DestroyWidget();
	$self->{'dialog_shell'} = undef;
    }

    $self->{'done'} = -1;
}

sub choose {
    my $self = shift;

    my $shell = $self->popup(@_);
    my $context = $shell->WidgetToApplicationContext();
    my $event;

    X::Motif::XmProcessTraversal($self->{'dialog_file'}, X::Motif::XmTRAVERSE_CURRENT);

    while ($self->{'done'} == 0) {
	$event = $context->AppNextEvent();
	X::Toolkit::DispatchEvent($event);
    }

    my $selection;

    if ($self->{'done'} > 0) {
	if ($self->{'done'} == 1) {
	    $selection = $self->{'storage'}->format($self);
	}
	$self->popdown();
    }

    $self->_shutdown();

    $selection;
}

sub _shutdown {
    my $self = shift;

    foreach my $storage (values %{$self->{'inactive_storage'}}) {
	$storage->shutdown($self);
    }
}

sub set_filter {
    my $self = shift;
    my($pattern) = @_;

    my $dialog_filter = $self->{'dialog_filter'};

    if (defined $dialog_filter) {
	if (!defined $pattern) {
	    $pattern = X::Motif::XmTextFieldGetString($dialog_filter);
	}
	else {
	    X::Motif::XmTextFieldSetString($dialog_filter, $pattern);
	    X::Motif::XmTextFieldSetString($self->{'dialog_file'}, '');
	}
    }

    $pattern = '*' if (!defined $pattern);

    $self->{'glob'} = $pattern;
    $self->{'filter'} = cvt_glob_to_regex($pattern);

    $self->filter();
}

sub filter {
    my $self = shift;

    my $dialog_file_list = $self->{'dialog_file_list'};

    if (defined $dialog_file_list) {
	my $hide_emacs = $self->{'hide_emacs'};
	my $hide_dots = $self->{'hide_dots'};
	my $filter = $self->{'filter'};

	my $row = 1;
	my @filtered_file_list = ();

	$dialog_file_list->Unmanage();
	X::Motif::XmListDeleteAllItems($dialog_file_list);

	my $i = 0;
	foreach my $item (@{$self->{'visible_file_list'}}) {
	    next if ($hide_emacs && ($item =~ /^\#/ || $item =~ /~$/));
	    next if ($hide_dots && $item =~ /^\./);

	    next if (!&{$filter}($item));

	    X::Motif::XmListAddItemUnselected($dialog_file_list, $item, $row);
	    push @filtered_file_list, $i;

	    ++$row;
	}
	continue {
	    ++$i;
	}

	X::Motif::XmListSetPos($dialog_file_list, 1);
	$dialog_file_list->Manage();

	@{$self->{'filtered_file_list'}} = @filtered_file_list;
    }
}

my %remembered_globs = ();

sub cvt_glob_to_regex {
    my($glob) = @_;

    $glob = '*' if (!defined $glob);
    my $regex = $remembered_globs{$glob};

    if (!defined $regex) {
	$regex = $glob;

	$regex =~ s|\\||g;
	$regex =~ s|^\s+||;
	$regex =~ s|\s+$||;

	$regex =~ s|([^\w\s-])|\\$1|g;
	$regex =~ s|\s+|\\s+|g;

	$regex =~ s|\\\001|.|g;
	$regex =~ s|\\\?|.|g;
	$regex =~ s|\\\*|.*|g;

	$regex .= '.*' if ($regex !~ m|\.\*|);

	$regex = "^".$regex."\$";

	$regex = eval qq(sub { \$_[0] =~ m\001$regex\001i });
	$remembered_globs{$glob} = $regex;
    }

    return $regex;
}

sub complete_partial_name {
    my $self = shift;
    my($partial, $w) = @_;

    if ($partial =~ m|(.*)/([^/]*)|) {
	my $dir = ($1 eq '') ? '/' : $1;
	$partial = $2;
	$self->switch_to_dir($dir);
	$self->reload();
    }

    if ($partial ne '') {
	my $dialog_dir_list = $self->{'dialog_dir_list'};
	my $dialog_file_list = $self->{'dialog_file_list'};

	my @matches = ();
	my $row;
	my $dir_row;
	my $file_row;

	$row = scalar(@{$self->{'visible_history'}}) + 1;
	foreach my $i (@{$self->{'filtered_dir_list'}}) {
	    my $item = $self->{'visible_dir_list'}[$i];
	    if ($item =~ /^\Q$partial\E/i) {
		push @matches, $item;
		if (!defined $dir_row) {
		    $dir_row = $row;
		}
	    }
	    ++$row;
	}

	$row = 1;
	foreach my $i (@{$self->{'filtered_file_list'}}) {
	    my $item = $self->{'visible_file_list'}[$i];
	    if ($item =~ /^\Q$partial\E/i) {
		push @matches, $item;
		if (!defined $file_row) {
		    $file_row = $row;
		}
	    }
	    ++$row;
	}

	if (@matches == 0) {
	    X::Bell($w->Display(), 100);
	}
	elsif (@matches == 1) {
	    $partial = $matches[0];
	    if (defined $dir_row) {
		$partial .= '/';
	    }
	}
	else {
	    my $start = length($partial);
	    my $test_start = $start;
	    my $test_match = pop @matches;
	    my $test_prefix;

	    undef $partial;

	    do {
		$test_prefix = substr($test_match, $test_start, 1);
		foreach (@matches) {
		    if (substr($_, $test_start, 1) ne $test_prefix) {
			$partial = substr($test_match, 0, $test_start);
			last;
		    }
		}
		++$test_start;
	    }
	    while (!defined $partial);
	}

	if (defined $dir_row) {
	    X::Motif::XmListSetPos($dialog_dir_list, $dir_row);
	}

	if (defined $file_row) {
	    X::Motif::XmListSetPos($dialog_file_list, $file_row);
	}
    }

    X::Motif::XmTextFieldSetString($w, $partial);
    X::Motif::XmTextFieldSetInsertionPosition($w, X::Motif::XmTextFieldGetLastPosition($w));
}

sub reload {
    my $self = shift;

    $self->{'storage'}->reload($self);
    $self->redisplay();
}

sub redisplay {
    my $self = shift;

    my $dialog_dir_list = $self->{'dialog_dir_list'};

    if (defined $dialog_dir_list) {
	$dialog_dir_list->Unmanage();
	X::Motif::XmListDeleteAllItems($dialog_dir_list);

	my $row = 1;

	foreach my $item (@{$self->{'visible_history'}}) {
	    my $visible_item = (' ' x ($row - 1)) . $item . "     ";
	    X::Motif::XmListAddItemUnselected($dialog_dir_list, $visible_item, $row);
	    ++$row;
	}

	my $selected_row = $row - 1 || $row;
	my $hide_dots = $self->{'hide_dots'};

	++$row;

	my $pad = ' ' x $row;
	my @filtered_dir_list = ();

	my $i = 0;
	foreach my $item (@{$self->{'visible_dir_list'}}) {
	    next if ($hide_dots && $item =~ /^\./);

	    X::Motif::XmListAddItemUnselected($dialog_dir_list, $pad . $item . "     ", $row);
	    push @filtered_dir_list, $i;

	    ++$row;
	}
	continue {
	    ++$i;
	}

	$self->{'active_pos'} = $selected_row - 1;
	@{$self->{'filtered_dir_list'}} = @filtered_dir_list;

	my $last_row = $selected_row + query $dialog_dir_list -visibleItemCount;

	while ($row <= $last_row) {
	    X::Motif::XmListAddItemUnselected($dialog_dir_list, '', $row);
	    ++$row;
	}

	X::Motif::XmListSelectPos($dialog_dir_list, $selected_row, X::False);
	X::Motif::XmListSetPos($dialog_dir_list, $selected_row - 1 || $selected_row);
	$dialog_dir_list->Manage();
    }

    my $dialog_dir = $self->{'dialog_dir'};

    if (defined $dialog_dir) {
	change $dialog_dir -text => $self->{'dir'};
    }

    my $dialog_host = $self->{'dialog_host'};

    if (defined $dialog_host) {
	X::Motif::XmTextFieldSetString($dialog_host, $self->{'host'});
    }

    $self->filter();
}

sub switch_to {
    my $self = shift;
    my($location) = @_;

    return if (!defined $location);

    my($def_type, $def_host, $def_port);

    if (!defined $self->{'storage'}) {
	$def_type = 'file';
    }

    if ($location =~ s|^(\w+):||) {
	if (defined $StorageTypes{$1}) {
	    $def_type = $1;
	}
    }

    if ($location =~ s|^//([^/]+)||) {
	$def_host = $1;
	if ($def_host =~ s|:(\d+)$||) {
	    $def_port = $1;
	}
    }

    $self->switch_to_storage($def_type) if (defined $def_type);
    $self->switch_to_host($def_host, $def_port) if (defined $def_host);
    $self->switch_to_dir($location);
}

sub switch_to_storage {
    my $self = shift;
    my($new_storage, $skip_update_display) = @_;

    if (defined $new_storage && defined $StorageTypes{$new_storage}) {
	my $storage = $self->{'storage'};

	if (defined $storage) {
	    $storage->deactivate($self);
	    $storage = $self->{'inactive_storage'}{$new_storage};

	    if (!defined $storage) {
		$StorageTypes{$new_storage}->new($self);
		$self->{'storage'}->switch_to_host($self);
		$self->{'storage'}->switch_to_dir($self);
	    }
	    else {
		$self->{'storage'} = $storage;
		$storage->activate($self);
	    }
	}
	else {
	    $StorageTypes{$new_storage}->new($self);
	}

	if (!defined $skip_update_display) {
	    my $dialog_storage = $self->{'dialog_storage'};
	    if (defined $dialog_storage) {
		change $dialog_storage -menuHistory => $self->{'storage_options'}{$new_storage};
	    }
	}
    }
}

sub switch_to_host {
    my $self = shift;
    my($new_host, $new_port) = @_;

    my $dialog_host = $self->{'dialog_host'};

    if (defined $dialog_host) {
	if (!defined $new_host) {
	    $new_host = X::Motif::XmTextFieldGetString($dialog_host);
	}
	else {
	    X::Motif::XmTextFieldSetString($dialog_host, $new_host);
	}
    }

    if (defined $new_host) {
	$self->{'storage'}->switch_to_host($self, $new_host, $new_port);
    }
}

sub switch_to_dir {
    my $self = shift;
    my($new_dir) = @_;

    if (defined $new_dir) {
	$self->{'storage'}->switch_to_dir($self, $new_dir);
    }
}

sub do_change_storage {
    my($w, $user, $call) = @_;
    $user->[0]->switch_to_storage($user->[1], 1);
    $user->[0]->reload();
}

sub do_change_host {
    my($w, $user, $call) = @_;
    $user->switch_to_host();
    $user->reload();
}

sub do_change_filter {
    my($w, $user, $call) = @_;
    $user->set_filter();
}

sub do_complete_partial_name {
    my($w, $user, $call) = @_;

    my $change = $call->text;

    if (defined $change && ref($call->event) eq 'X::Event::KeyEvent') {
	if ($change eq " ") {
	    $call->deny_change;
	    $user->complete_partial_name(X::Motif::XmTextFieldGetString($w), $w);
	}
    }
}

sub do_ok {
    my($w, $user, $call) = @_;

    $user->{'selection'} = X::Motif::XmTextFieldGetString($user->{'dialog_file'});
    $user->{'done'} = 1;
}

sub do_cancel {
    my($w, $user, $call) = @_;

    $user->{'done'} = 2;
}

sub do_choose_dir {
    my($w, $user, $call) = @_;

    my $pos = $call->item_position() - 1;
    my $active_pos = $user->{'active_pos'};

    if ($pos != $active_pos) {
	if ($pos < $active_pos) {
	    $user->{'storage'}->go_back($user, $pos);
	}
	else {
	    my $raw_pos = $user->{'filtered_dir_list'}[$pos - $active_pos - 1];
	    if (defined $raw_pos) {
		$user->{'storage'}->go_forward($user, $raw_pos);
	    }
	}

	$user->reload();
    }
}

sub do_choose_file {
    my($w, $user, $call) = @_;

    $user->{'selection'} = $call->item()->plain();
    $user->{'done'} = 1;
}

sub do_maybe_choose_file {
    my($w, $user, $call) = @_;

    my $file = $call->item()->plain();
    X::Motif::XmTextFieldSetString($user->{'dialog_file'}, $file);
}

sub create_dialog {
    my $self = shift;
    my($parent, $dialog_title) = @_;

    my $shell = give $parent -Transient,
			-resizable => X::True,
			-title => $dialog_title;

    my $form = give $shell -Form, -managed => X::False, -name => 'top_form',
			-resizePolicy => X::Motif::XmRESIZE_GROW,
			-horizontalSpacing => 5,
			-verticalSpacing => 5;

    my($storage, $menu) = give $form -OptionMenu,
			-traversalOn => X::False,
			-label => 'Storage System: ';

	my $storage_options = {};
	foreach (sort { $a->[1] cmp $b->[1] }
		 map { [$_->menu_name,
			$_->menu_order,
			$_->storage_name] } values %StorageTypes) {
	    $storage_options->{$_->[2]} = give $menu -Button, -text => $_->[0],
					    -command => [\&do_change_storage, [$self, $_->[2]]];
	}

    if (defined $self->{'storage'}) {
	change $storage -menuHistory => $storage_options->{$self->{'storage'}->storage_name()};
    }

    my $spacer_1 = give $form -Spacer;

    my $dir_form = give $form -Form, -name => 'dir_form',
			-resizePolicy => X::Motif::XmRESIZE_GROW,
			-verticalSpacing => 5;
	my $host_label = give $dir_form -Label, -text => 'Computer:';
	my $host = give $dir_form -Field, -text => $self->{'host'},
			-sensitive => X::True,
			-command => [\&do_change_host, $self];
	my $dir_list_label = give $dir_form -Label, -text => 'Folders:';
	my $dir_view = give $dir_form -ScrolledWindow;
	my $dir_list = give $dir_view -List,
			-traversalOn => X::False,
			-visibleItemCount => 7,
			-scrollBarDisplayPolicy => X::Motif::XmSTATIC,
			-selectionPolicy => X::Motif::XmBROWSE_SELECT,
			-listSizePolicy => X::Motif::XmVARIABLE;
	$dir_list->AddCallback(X::Motif::XmNdefaultActionCallback, \&do_choose_dir, $self);

	constrain $host_label -top => -form, -left => -form, -right => -form;
	constrain $host -top => $host_label, -left => -form, -right => -form;
	constrain $dir_list_label -top => $host, -left => -form, -right => -form;
	constrain $dir_view -top => $dir_list_label, -left => -form, -right => -form, -bottom => -form;

    my $file_form = give $form -Form, -name => 'file_form',
			-resizePolicy => X::Motif::XmRESIZE_GROW,
			-verticalSpacing => 5;
	my $filter_label = give $file_form -Label, -text => 'Show Files Like:';
	my $filter = give $file_form -Field, -text => $self->{'glob'};
	$filter->AddCallback(X::Motif::XmNvalueChangedCallback, \&do_change_filter, $self);
	my $file_list_label = give $file_form -Label, -text => 'Files:';
	my $file_view = give $file_form -ScrolledWindow;
	my $file_list = give $file_view -List,
			-visibleItemCount => 7,
			-scrollBarDisplayPolicy => X::Motif::XmSTATIC,
			-selectionPolicy => X::Motif::XmBROWSE_SELECT,
			-listSizePolicy => X::Motif::XmVARIABLE;
	$file_list->AddCallback(X::Motif::XmNdefaultActionCallback, \&do_choose_file, $self);
	$file_list->AddCallback(X::Motif::XmNbrowseSelectionCallback, \&do_maybe_choose_file, $self);

	constrain $filter_label -top => -form, -left => -form, -right => -form;
	constrain $filter -top => $filter_label, -left => -form, -right => -form;
	constrain $file_list_label -top => $filter, -left => -form, -right => -form;
	constrain $file_view -top => $file_list_label, -left => -form, -right => -form, -bottom => -form;

    my $dir_label = give $form -Label, -text => 'Folder: ',
			-alignment => X::Motif::XmALIGNMENT_END;
    my $dir = give $form -Label, -text => $self->{'dir'},
			-resizable => X::False;
    my $file_label = give $form -Label, -text => 'File: ',
			-alignment => X::Motif::XmALIGNMENT_END,
			-width => (query $dir_label -width);
    my $file = give $form -Field, -verifyBell => X::False;
    $file->AddCallback(X::Motif::XmNmodifyVerifyCallback, \&do_complete_partial_name, $self);
    $file->AddCallback(X::Motif::XmNactivateCallback, \&do_ok, $self);

    my $spacer_3 = give $form -Spacer;
    my $ok = give $form -Button, -text => 'OK', -command => [\&do_ok, $self];
    my $cancel = give $form -Button, -text => 'Cancel', -command => [\&do_cancel, $self];

    constrain $storage -top => -form, -left => -form;
    constrain $spacer_1 -left => $storage, -right => -form;
    constrain $dir_form -top => $storage, -left => -form, -bottom => $dir;
    constrain $file_form -top => $storage, -left => $dir_form, -right => -form, -bottom => $dir;
    constrain $dir_label -left => -form, -bottom => $file;
    constrain $dir -left => $dir_label, -right => -form, -bottom => $file;
    constrain $file_label -left => -form, -bottom => $cancel;
    constrain $file -left => $file_label, -right => -form, -bottom => $cancel;
    constrain $cancel -right => -form, -bottom => -form;
    constrain $ok -right => $cancel, -bottom => -form;
    constrain $spacer_3 -left => -form, -right => $ok;

    $self->{'dialog_shell'} = $shell;
    $self->{'dialog_form'} = $form;
    $self->{'dialog_dir'} = $dir;
    $self->{'dialog_file'} = $file;
    $self->{'dialog_host'} = $host;
    $self->{'dialog_storage'} = $storage;
    $self->{'dialog_filter'} = $filter;
    $self->{'dialog_dir_list'} = $dir_list;
    $self->{'dialog_file_list'} = $file_list;

    $self->{'storage_options'} = $storage_options;

    foreach my $w ($file, $filter, $file_list) {
	X::Motif::XmAddTabGroup($w);
    }

    return $form;
}

1;
