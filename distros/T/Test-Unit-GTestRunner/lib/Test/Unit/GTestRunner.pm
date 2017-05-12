#! /bin/false

# $Id: GTestRunner.pm.in,v 1.70 2006/05/12 12:42:14 guido Exp $

# Copyright (C) 2004-2006 Guido Flohr <guido@imperia.net>,
# all rights reserved.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.

# You should have received a copy of the GNU General Public License 
# along with this program; if not, write to the Free Software Foundation, 
# Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

package Test::Unit::GTestRunner;

use strict;

use constant DEBUG => 0;

use vars qw ($VERSION $PERL @MY_INC);
$VERSION = '0.04';

package Test::Unit::GTestRunner::Node;

use strict;

sub new {
	my ($class, %args) = @_;

	my $self = {
		__path => $args{path},
		__name => $args{name},
		__is_test => $args{is_test},
		__output => '',
		__result => '',
	};

	bless $self, $class;
}

sub addOutput {
	my ($self, $text) = @_;

	$self->{__output} .= $text;

	return 1;
}

sub setOutput {
	my ($self, $text) = @_;

	$self->{__output} = $text;

	return 1;
}

sub getOutput {
	shift->{__output};
}

sub getStockID {
	my ($self) = @_;

	my $stock_id = '';

	$stock_id = 'gtk-dialog-question' 
		if $self->isTest;
	$stock_id = 'gtk-dialog-warning'
		if length $self->getOutput;
	$stock_id = 'gtk-dialog-error'
		if ($self->isError || $self->isFailure);

	return $stock_id;
}

sub getName {
	shift->{__name};
}

sub getPath {
	shift->{__path};
}

sub isError {
	shift->{__error};
}

sub setError {
	my ($self) = @_;

	$self->{__errror} = 1;
}

sub isTest {
	shift->{__is_test};
}

sub isFailure {
	shift->{__failure};
}

sub setFailure {
	my ($self) = @_;

	$self->{__failure} = 1;
}

sub isSuccess {
	my $self = shift;

	return (!$self->isError && !$self->isFailure);
}

sub setSuccess {
	my ($self) = shift;

	delete $self->{__error};
	delete $self->{__failure};
	$self->{__result} = '';

	return;
}

sub getResult {
	shift->{__result};
}

sub setResult {
	my ($self, $result) = @_;

	$self->{__result} = $result;
}

sub getFailurePath {
	shift->{__failure_path};
}

sub setFailurePath {
	my ($self, $path) = @_;

	$self->{__failure_path} = $path;
}

sub unsetFailurePath {
	delete shift->{__failure_path};
}

package Test::Unit::GTestRunner;

use English qw (-no_match_vars);
BEGIN {
	$PERL = $EXECUTABLE_NAME; # Aka $^X.
	@MY_INC = @INC;
}

use Locale::TextDomain qw (Test-Unit-GTestRunner);
use Locale::Messages qw (bind_textdomain_filter bind_textdomain_codeset
						 turn_utf_8_on);
BEGIN {
	bind_textdomain_filter 'Test-Unit-GTestRunner', \&turn_utf_8_on;
	bind_textdomain_codeset 'Test-Unit-GTestRunner', 'utf-8';
}

use MIME::Base64 qw (decode_base64);
use Test::Unit::GTestRunner::Worker;
use Config;
use Gtk2;
use Gtk2::GladeXML;
use Storable qw (thaw);

use constant GUI_STATES => {
	initial => {
		run_menu_item => 0,
		run_button => 0,
		run_selected_menu_item => 0,
		run_selected_button => 0,
		open_menu_item => 1,
		open_button => 1,
		cancel_menu_item => 0,
		cancel_button => 0,
		refresh_menu_item => 0,
		refresh_button => 0,
	},
	loaded => {
		run_menu_item => 1,
		run_button => 1,
		run_selected_menu_item => 0,
		run_selected_button => 0,
		open_menu_item => 1,
		open_button => 1,
		cancel_menu_item => 0,
		cancel_button => 0,
		refresh_menu_item => 1,
		refresh_button => 1,
	},
	loaded_selected => {
		run_menu_item => 1,
		run_button => 1,
		run_selected_menu_item => 1,
		run_selected_button => 1,
		open_menu_item => 1,
		open_button => 1,
		cancel_menu_item => 0,
		cancel_button => 0,
		refresh_menu_item => 1,
		refresh_button => 1,
	},
	running => {
		run_menu_item => 0,
		run_button => 0,
		run_selected_menu_item => 0,
		run_selected_button => 0,
		open_menu_item => 0,
		open_button => 0,
		cancel_menu_item => 1,
		cancel_button => 1,
		refresh_menu_item => 0,
		refresh_button => 0,
	}
};

sub new {
	my $class = shift;

	my $self = {
		__counter => 0,
		__errors => 0,
		__pid => 0,
		__kill_signals => [],
		__last_signal => undef,
		__failures => [],
		__new_file_chooser => 0,
	};

	# Should we make sure that init is called only once?
	Gtk2->init;

	local $/;
	my $data = <DATA>;

	# It seems that libglade does not consider our call to
	# bind_textdomain().  We therefore roll our own version.
	my $gettext = $__;
	$data =~ s{
		[ ]translatable="yes">([^<]+)</
		}{
			my $string = $1;
			$string =~ s/&quot;/\"/g;
			$string =~ s/&apos;/\'/g;
			$string =~ s/&lt;/</g;
			$string =~ s/&gt;/>/g;
			$string =~ s/&amp;/&/g;
			$string = $gettext->{$string};
			$string =~ s/&/&amp;/g;
			$string =~ s/>/&gt;/g;
			$string =~ s/</&lt;/g;
			$string =~ s/\'/&apos;/g;
			$string =~ s/\"/&quot;/g;
			qq{ translatable="no">$string</};
	}gex;

	my $gladexml = Gtk2::GladeXML->new_from_buffer ($data);

	bless $self, $class;

	$gladexml->signal_autoconnect_from_package ($self);

	$self->{__gladexml} = $gladexml;

	my $statusbar = $self->{__statusbar} = 
		$gladexml->get_widget ('statusbar1');
	my $context_id = $self->{__context_id} =
		$statusbar->get_context_id (__PACKAGE__);
	$statusbar->push ($context_id, ' ' . __"Starting GTestRunner.");

	my $error_textview = $self->{__error_textview} =
		$gladexml->get_widget ('errortextview');
	my $error_textbuffer = Gtk2::TextBuffer->new;
	my $tag = $error_textbuffer->create_tag (
		'error', 
		foreground => 'red',
		'foreground-set' => 1,
		weight => 600,
	);

	$error_textview->set_buffer ($error_textbuffer);
	$error_textview->set_wrap_mode ('word');
	$self->{__error_textbuffer} = $error_textbuffer;

	my $progress_bar = $self->{__progress_bar} = 
		$gladexml->get_widget ('progressbar');
	my $progress_image = $self->{__progress_image} =
		$gladexml->get_widget ('progressimage');

	$self->{__green} = Gtk2::Gdk::Color->new (0, 65535, 0);
	$self->{__red} = Gtk2::Gdk::Color->new (65535, 0, 0);

	my $failure_view = $gladexml->get_widget ('failure_treeview');
	my $failure_store = Gtk2::ListStore->new ('Glib::String',
											  'Glib::String', 
											  'Glib::String', 
											  'Glib::String');
	$failure_view->set_model ($failure_store);
	$failure_view->get_selection->set_mode ('multiple');
	$self->{__failure_store} = $failure_store;
	$self->{__failure_view} = $failure_view;

	my $column = Gtk2::TreeViewColumn->new;
	$column->set_title (__"Test");
	$failure_view->append_column ($column);

	my $count = 0;
	my $pixbuf_renderer = Gtk2::CellRendererPixbuf->new;
	$column->pack_start ($pixbuf_renderer, 0);
	$column->add_attribute ($pixbuf_renderer, 'stock-id' => $count++);

	my $text_renderer = Gtk2::CellRendererText->new;
	$column->pack_start ($text_renderer, 1);
	$column->add_attribute ($text_renderer, text => $count++);

	for my $header (__"Test Case", __"Source") {
		my $renderer = Gtk2::CellRendererText->new;
		$column = 
			Gtk2::TreeViewColumn->new_with_attributes ($header, $renderer,
													   text => $count++);
		$column->set_resizable (1);
		$column->set_expand (1);
		$failure_view->append_column ($column);
	}

	$failure_view->signal_connect (cursor_changed => 
								   sub {
									   $self->__onFailureChange (@_);
								   });

	my $hierarchy_view = $gladexml->get_widget ('hierarchy_treeview');
	my $hierarchy_store = Gtk2::TreeStore->new ('Glib::String', 
												'Glib::String');
	$hierarchy_view->get_selection->set_mode ('multiple');
	$hierarchy_view->set_model ($hierarchy_store);
	$self->{__hierarchy_store} = $hierarchy_store;
	$self->{__hierarchy_view} = $hierarchy_view;

	$hierarchy_view->signal_connect (
		cursor_changed => 
		sub {
			$self->__onHierarchyChange (@_);
		});

	$hierarchy_view->signal_connect (
		row_activated => 
		sub {
			$self->__onHierarchyActivated (@_);
		});

	$column = Gtk2::TreeViewColumn->new;
	$column->set_title (__"Test");
	$hierarchy_view->append_column ($column);

	$pixbuf_renderer = Gtk2::CellRendererPixbuf->new;
	$column->pack_start ($pixbuf_renderer, 0);
	$column->add_attribute ($pixbuf_renderer, 'stock-id' => 1);

	$text_renderer = Gtk2::CellRendererText->new;
	$column->pack_start ($text_renderer, 1);
	$column->add_attribute ($text_renderer, text => 0);

	# It would be sufficient to set this up only once, but we want
	# to avoid both a global and complication.
	$self->{__kill_signals} = [];
	if ($Config{sig_name}) {
		my $i = 0;
		my %signo = ();
		foreach my $name (split / +/, $Config{sig_name}) {
			$signo{$name} = $i if ($name eq 'TERM'
								   || $name eq 'QUIT'
								   || $name eq 'KILL');
			++$i;
		}
		my @killers;
		push @killers, [ TERM => $signo{TERM} ] if $signo{TERM};
		push @killers, [ QUIT => $signo{QUIT} ] if $signo{QUIT};
		push @killers, [ KILL => $signo{KILL} ] if $signo{KILL};
		$self->{__kill_signals} = \@killers;
	}

	my $notebook = $gladexml->get_widget ('notebook');
	$notebook->signal_connect (switch_page => 
								   sub {
									   $self->__onSwitchPage (@_);
								   });

	my $check = $gladexml->get_widget ('always_refresh_checkbutton');
	$check->set_active (1);
	$self->__refreshSuitesBeforeEveryRun ($check);

	# Otherwise a zero kill will report on Zombies.
	$SIG{CHLD} = 'IGNORE' if exists $SIG{CHLD};

	return $self;
}

sub start {
    my ($self, @args) = @_;

    $self->{__suites} = [@args];
	$self->__loadSuite if @args;

    if (@args) {
		$self->__setGUIState ('loaded');
    } else {
		$self->__setGUIState ('initial');
    }
    
    Gtk2->main;

    return 1;
}

sub main {
    Test::Unit::GTestRunner->new->start (@_);
}

sub __runTests {
	my ($self, $suites) = @_;

	Glib::Source->remove ($self->{__timeout_id}) if $self->{__timeout_id};

	$self->__setGUIState ('running');

	$self->__setErrorTextBuffer ('');
	$self->{__progress_bar}->set_fraction (0);
	$self->{__failure_store}->clear;
	$self->{__failures} = [];
	$self->{__error_count} = 0;
	$self->{__failure_count} = 0;
	$self->{__counter} = 0;
	$self->{__num_planned} = @{$self->{__planned}};
	$self->{__progress_image}->set_from_stock ('gtk-dialog-question',
											   'button');

	foreach my $node (@{$self->{__planned}}) {
		$node->setOutput ('');
		$node->setResult ('');
	}

	foreach my $node (@{$self->{__nodes}}) {
		$node->unsetFailurePath;
	}

	my @suites = $suites ? @{$suites} : @{$self->{__suites}};

	my $arg = join ', ', map {'"' . $_ . '"'} @suites;
	my @local_inc = map { '-I' . $_ } @MY_INC;
	local *CMD;
	my @cmd = ($PERL, 
			   @local_inc,
			   '-MTest::Unit::GTestRunner::Worker',
			   #'-d:ptkdb',
			   '-e', 
			   "Test::Unit::GTestRunner::Worker->new->start ($arg)",
			   );

	unless (open CMD, '-|', @cmd) {
		my $cmd = pop @cmd;

		foreach my $part (@cmd) {
			my $arg = quotemeta $part;
			$cmd .= " $part";
		}

		my $msg = __x ("Test cannot be started: {cmd}: {err}.",
			       cmd => $cmd, err => $!);
		$self->__setErrorTextBuffer ($msg);
		return;
	}
	$self->{__cmd_fileno} = fileno CMD;
	$self->{__cmd_fh} = *CMD;

	$self->__setStatusBar (__"Running ...");

	$self->{__timeout_id} = Glib::Timeout->add (40, sub {
	    $self->__handleReply;
	    return 1;
	});

	return 1;
}

sub __runAllTests {
	my ($self) = @_;

	$self->__loadSuite if $self->{__always_refresh};

	my @planned;
	foreach my $node (@{$self->{__nodes}}) {
		push @planned, $node if $node->isTest;
	}

	$self->{__planned} = \@planned;

	return $self->__runTests;
}

sub __runSelectedTests {
	my $self = shift;
	my $dirty;

	$self->__loadSuite (\$dirty) if $self->{__always_refresh};	
	if ($dirty) {
		my $message = __<<EOF;
The test suite you want to run has changed.  Please make a new
selection, and run again.
EOF
        my $main_window = $self->{__gladexml}->get_widget ('GTestRunner');
		my $dialog = Gtk2::MessageDialog->new ($main_window,
											   'destroy-with-parent',
											   'error',
											   'ok',
											   $message);
		$dialog->run;
		$dialog->destroy;
		return;
	}

	my $hierarchy_view = $self->{__hierarchy_view};
	my $failure_view = $self->{__failure_view};

	my $hierarchy_paths = [$hierarchy_view->get_selection->get_selected_rows];
	my $failure_paths = [$failure_view->get_selection->get_selected_rows];

	if ($failure_paths) {
		# Convert them into hierarchy_paths.
		for (my $i = 0; $i < @$failure_paths; $i++) {
			my $index = $failure_paths->[$i]->to_string;
			my $node = $self->{__failures}->[0 + $index];

			$failure_paths->[$i] = 
				Gtk2::TreePath->new_from_string ($node->getPath);	
		}
	}

	my $paths = $failure_paths ?
		@$hierarchy_paths > @$failure_paths 
			? $hierarchy_paths
			: $failure_paths
		: $hierarchy_paths;

	my @modules;
	my @planned;
	my %planned;
	foreach my $path (@$paths) {
		my $path_str = $path->to_string;

		my $node = $self->{__nodes_by_path}->{$path_str};

		my $module;
		my $store = $self->{__hierarchy_store};
		my $iterator = $store->get_iter ($path);
		
		if ($node->isTest) {
			$path_str =~ /:([0-9]+)$/;
			my $testno = $1;
			$path->up;
			
			($module) = $store->get ($store->get_iter ($path));
			# The number serves as the identifier for our worker thread 
			# here.  Remember that Perl module names cannot start with
			# a number.
			$module .= "::$testno";
		} else {
			($module) = $store->get ($store->get_iter ($path));
		}
		push @modules, $module;

		my $path_len = length $path_str;
		foreach my $node (@{$self->{__nodes}}) {
			my $node_path = $node->getPath;

			if ($path_str eq substr $node_path, 0, $path_len) {
				# If a subnode of an already selected node is also
				# selected, we have to avoid to run tests twice.
				next if $planned{$node_path};

				# Skip entities which aren't tests.
				next unless $node->{__is_test};
				
				push @planned, $node;
				$planned{$node_path} = 1;
			}
		}
	}

	$self->{__planned} = \@planned;
	return $self->__runTests (\@modules);
}

sub __terminateTests {
	my ($self, $message) = @_;

	$self->__setStatusBar ($message) if defined $message;

	$self->__sendKill;

	return 1;
}

sub __cancelTests {
	shift->__terminateTests (__"Waiting for test to terminate ...");
}

sub __refreshSuite {
	my $self = shift;
	
	$self->__setStatusBar (__"Refreshing the test suite.");
	$self->__loadSuite;
}

sub __refreshSuitesBeforeEveryRun {
	my ($self, $check) = @_;
	
	my $gladexml = $self->{__gladexml};

    my $active = $self->{__always_refresh} = $check->get_active;

	$gladexml->get_widget ('always_refresh_checkbutton')->set_active ($active);
	$gladexml->get_widget ('always_refresh_menuitem')->set_active ($active);

	return 1;
}

sub __loadSuite {
	my ($self, $dirty_flag) = @_;

	$self->{__failure_store}->clear;

	my $store = Gtk2::TreeStore->new ('Glib::String', 
									  'Glib::String');
	my $old_store = $self->{__hierarchy_store};

	$self->__setErrorTextBuffer ('');

	my @suites = @{$self->{__suites}};

	foreach my $suite (@suites) {
		$suite =~ s/\'/\\\'/g;
		$suite = "'$suite'";
	}

	my $arg = join ', ', @suites;
	my @local_inc = map { '-I' . $_ } @MY_INC;
	local *CMD;
	my @cmd = ($PERL, 
			   @local_inc,
			   '-MTest::Unit::GTestRunner::Lister',
			   # '-d:ptkdb',
			   '-e', 
			   "Test::Unit::GTestRunner::Lister->new->list ($arg)",
			   );

	unless (open CMD, '-|', @cmd) {
		my $cmd = pop @cmd;

		foreach my $part (@cmd) {
			my $arg = quotemeta $part;
			$cmd .= " $part";
		}

		my $msg = __x ("Testsuite cannot be listed: {cmd}: {err}.",
			       cmd => $cmd, err => $!);
		$self->__setErrorTextBuffer ($msg);
		return;
	}

	my @lines = <CMD>;
	my $status = shift @lines;
	unless (defined $status && $status eq "SUCCESS\n") {
		$self->__setErrorTextBuffer (join "\n", @lines);
		$self->__resetGUI;
		return;
	}
	# (void)
	close CMD;

	my @indices;
	my $dirty;
	my @nodes;
	foreach my $line (@lines) {
		chomp $line;

		unless ($line =~ /^( *)([-+])([A-Za-z0-9_:]+)$/) {
			$self->__setErrorTextBuffer (__x ("Corrupt test listing: {line}\n",
											  line => $line));
			$self->__resetGUI;
			return;
		}

		my ($spaces, $type, $name) = ($1, $2, $3);
		my $depth = length $spaces;
		
		unless ($depth <= (1 + @indices)) {
			my $old_depth = @indices;
			my $message = 
				__x ("Invalid change in test depth ({old} to {new}).",
					 old => $old_depth, new => $depth);
			$self->__setErrorTextBuffer ($message);
			$self->__resetGUI;
			return;
		}

		$#indices = $depth;
		$indices[$depth] = defined $indices[$depth] ? $indices[$depth] + 1 : 0;

		my $hpath_str = join ':', @indices;
		my $hpath = Gtk2::TreePath->new_from_indices (@indices);

		my %args = (path => $hpath_str,
					name => $name);

		$args{is_test} = 1 if '-' eq $type;

		my $node = Test::Unit::GTestRunner::Node->new (%args);
		push @nodes, $node;

		$hpath->up;
		my $parent = $depth ? $store->get_iter ($hpath) : undef;
		my $iterator = $store->append ($parent);
		$store->set ($iterator,
					 0 => $node->getName,
					 1 => $node->getStockID);

		unless ($dirty) {
			my $new_path = $store->get_path ($iterator);
			my $new_path_str = $new_path->to_string;
			my $old_iter = $old_store->get_iter_from_string ($new_path_str);

			unless ($old_iter) {
				$dirty = 1;
				next;

			}

			my $old_name = $old_store->get ($old_iter, 0);
			$dirty = !defined $old_name || $old_name ne $name;
		}
	}

	if ($dirty) {
		$self->{__nodes} = \@nodes;
		$self->{__hierarchy_view}->set_model ($store);
		$self->{__hierarchy_store} = $store;

		$self->{__nodes_by_path} = {};
		foreach my $node (@nodes) {
			$self->{__nodes_by_path}->{$node->getPath} = $node;
		}
	}

	$$dirty_flag = $dirty if $dirty_flag;

	$self->__setGUIState ('loaded');

	return 1;
}

sub __selectTestCase {
	my ($self, $path_string) = @_;

	my $node = $self->{__nodes_by_path}->{$path_string};
	
	my $hierarchy_view = $self->{__hierarchy_view};
	my $failure_view = $self->{__failure_view};

	my $hierarchy_paths = [$hierarchy_view->get_selection->get_selected_rows];
	my $failure_paths = [$failure_view->get_selection->get_selected_rows];

	if  ((@$hierarchy_paths || @$failure_paths) && !$self->{__pid}) {
		$self->__setGUIState ('loaded_selected');
	}

	unless ($node->isTest) {
		# This is an inner node of the tree.
		$self->__setErrorTextBuffer ('');

		my $tree_selection = $failure_view->get_selection;
		$tree_selection->unselect_all;

		return 1;
	}

	# This is a leaf, and we have a corresponding test case.
	$self->__setErrorTextBuffer ($node->getResult, $node->getOutput);
	my $hierarchy_path = Gtk2::TreePath->new_from_string ($path_string);

	if ($hierarchy_path) {
		my ($old_path, undef) = $hierarchy_view->get_cursor;
		
		if (!defined $old_path || $old_path->compare ($hierarchy_path)) {
			$hierarchy_view->expand_to_path ($hierarchy_path);
			$hierarchy_view->scroll_to_cell ($hierarchy_path);
			$hierarchy_view->get_selection->select_path ($hierarchy_path);
			$hierarchy_view->set_cursor ($hierarchy_path);
		}
	}

	my $failure_index = $node->getFailurePath;

	if (defined $failure_index) {
		my $failure_path = Gtk2::TreePath->new_from_string ($failure_index);

		if ($failure_path) {
			my ($old_path, undef) = $failure_view->get_cursor;

			if (!defined $old_path || $old_path->compare ($failure_path)) {
				$failure_view->expand_to_path ($failure_path);
				$failure_view->scroll_to_cell ($failure_path);
				$failure_view->get_selection->select_path ($failure_path);
				$failure_view->set_cursor ($failure_path);
			}
		}
	} else {
		# Unselect.
		my $tree_selection = $failure_view->get_selection;
		$tree_selection->unselect_all;
	}

	return 1;
}

sub __setStatusBar {
	my ($self, $msg) = @_;

	my $statusbar = $self->{__statusbar};
	my $context_id = $self->{__context_id};

	$statusbar->pop ($context_id);

	$context_id = $self->{__context_id} =
		$statusbar->get_context_id (__PACKAGE__);

	$statusbar->push ($context_id, ' ' . $msg);

	return 1;
}

sub __onHierarchyChange {
	my ($self, $view) = @_;

	my ($path, $focus_column) = $view->get_cursor;

	if ($path) {
		my $str_path = $path->to_string;

		return $self->__selectTestCase ($str_path);
	}

	$self->__setErrorTextBuffer ('');

	return 1;
}

sub __onFailureChange {
	my ($self, $view) = @_;

	my ($path, $focus_column) = $view->get_cursor;

	if ($path) {
		my $index = $path->to_string;
		my $node = $self->{__failures}->[0 + $index];

		unless ($self->{__pid}) {
			$self->__setGUIState ('loaded_selected');
		}

		return $self->__selectTestCase ($node->getPath);
	}

	$self->__setErrorTextBuffer ('');

	return 1;
}

sub __onHierarchyActivated {
	my ($self, $view, $path) = @_;

	my $str_path = $path->to_string;

	if ($self->{__tests_by_path}->{$str_path}) {
		my $record = $self->{__tests_by_path}->{$str_path};
		
		return 1 unless defined $record->{failure_path};

		# Currently selected or not?
		my $selection = $self->{__hierarchy_view}->get_selection;
		my $selected = $selection->path_is_selected ($path);
		$self->__selectAllFailures ($selected);
	} else {
		$view->row_expanded ($path) ? 
			$view->collapse_row ($path) : $view->expand_row ($path, 1);
	}

	return 1;
}

sub __onSwitchPage {
	my ($self, $notebook, undef, $current_page) = @_;

	return 1 unless @{$self->{__suites}};

	my $view = $current_page == 0 ?
		$self->{__failure_view} : $self->{__hierarchy_view};

	my $selection = $view->get_selection;

	my $selected = $selection->count_selected_rows;

	unless ($self->{__pid}) {
		if ($selected) {
			$self->__setGUIState ('loaded_selected');
		} else {
			$self->__setGUIState ('loaded');
		}
	}
		
	return 1;
}

sub __quitApplication {
	Gtk2->main_quit;
}

sub __showAboutDialog {
	my ($self) = @_;

	my $viktor = "\x{412}\x{438}\x{43a}\x{442}\x{43e}\x{440} "
		. "\x{41a}\x{43e}\x{436}\x{443}\x{445}\x{430}\x{440}\x{43e}\x{432} "
		. "<Viktor.Kojouharov\@imperia.net>";

	my $main_window = $self->{__gladexml}->get_widget ('GTestRunner');
	Gtk2->show_about_dialog ($main_window,
							 name => 'GTestRunner',
							 version => $VERSION,
							 authors => [ 'Guido Flohr <guido@imperia.net>',
										  $viktor],
							 translator_credits => 
							 # TRANSLATORS: Replace this string with your
							 # own names and e-mail addresses, one name
							 # per line.
							 __"translator-credits"
							 );
}

sub __showFileSelection {
	my ($self) = @_;

	$self->{__new_file_chooser} = 1 if exists $ENV{GFC};

	if ($self->{__new_file_chooser}) {
		my $dialog = Gtk2::FileChooserDialog->new (
			__"Select a test suite or test case to run!",
			undef,
			'open',
			'gtk-cancel' => 'GTK_RESPONSE_CANCEL',
			'gtk-open' => 'GTK_RESPONSE_OK',
		);

		$dialog->set_select_multiple (1);
		$dialog->set_current_folder ($self->{__current_dir}) 
			if $self->{__current_dir};
		
		my $result = $dialog->run;
		$self->{__suites} = [$dialog->get_filenames] if 'ok' eq $result;
		$self->{__current_dir} = $dialog->get_current_folder;
		$dialog->destroy;
	} else {
		require File::Basename;
		my $dialog = Gtk2::FileSelection->new (__("Select a test suite or " .
												  "test case to run!"));

		$dialog->set_select_multiple (1);
		$dialog->set_filename ($self->{__current_dir}) 
			if $self->{__current_dir};
		
		my $result = $dialog->run;
		
		$self->{__suites} = [$dialog->get_selections] if 'ok' eq $result;
		$self->{__current_dir} = 
			File::Basename::dirname ($dialog->get_filename) . '/';
		$dialog->destroy;
	}
	$self->__loadSuite if @{$self->{__suites}};

	return 1;
}

sub __handleReply {
	my ($self) = @_;

	my $rin = '';
	vec ($rin, $self->{__cmd_fileno}, 1) = 1;

	my $win = my $ein = '';
	my $nfound = select $rin, $win, $ein, 0;
	return $self->__terminateTests (__x ("Select on pipe to child process "
										 . "failed: {err}.", err => $!))
		if $nfound < 0;

	return unless $nfound;

	my $num_bytes;
	my $bytes = sysread $self->{__cmd_fh}, $num_bytes, 9;
	return $self->__terminateTests (__("Unexpected end of file while reading "
									   . "from child process.")) unless $bytes;

	return $self->__terminateTests (__x ("Read from pipe to child process "
									. "failed: {err}.", err => $!))
		if $bytes < 0;

	chop $num_bytes;
	$num_bytes = hex $num_bytes;
	return $self->__terminateTests (__("Unexpected end of file while reading "
									   . "from child process.")) 
		if $bytes <= 0;

	my $reply = '';
	my $chunk;
    my $bytes_to_read = $num_bytes;

	while ($bytes_to_read > 0) {
		$bytes = sysread $self->{__cmd_fh}, $chunk, $bytes_to_read;
		return $self->__terminateTests (__("Unexpected end of file while "
										   . "reading from child process.")) 
			unless $bytes;
		return $self->__terminateTests (__x ("Read from pipe to child process "
											 . "failed: {err}.", err => $!))
			if $bytes < 0;

		$bytes_to_read -= $bytes;

		chop $chunk;
		$reply .= $chunk;
	}

	warn "<<< REPLY: $reply\n" if DEBUG;

	my ($cmd, $args) = split / +/, $reply, 2;

	my $method = '__handleReply' . ucfirst $cmd;

	warn "+++ REPLY: $reply\n" if DEBUG;
	$self->$method ($args);

	return 1;
}

sub __handleReplyPrint {
	my ($self, $message) = @_;

	my $cleartext = decode_base64 $message;

	my $index = $self->{__counter};

	my $node = $self->{__planned}->[$index];	

	$node->addOutput ($cleartext);

	$self->__setErrorTextBuffer ($node->getResult, $node->getOutput);

	# We have been here before.
	return 1 if defined $node->getFailurePath;

	my $hpath_str = $node->getPath;
	$self->__selectTestCase ($hpath_str);

	my $hstore = $self->{__hierarchy_store};
	my $iterator = $hstore->get_iter_from_string ($hpath_str);

	my $test = $hstore->get ($iterator, 0);
	$hstore->set ($iterator, 1 => 'gtk-dialog-warning');

	my $package = '';
	my $hpath = Gtk2::TreePath->new_from_string ($hpath_str);
	if ($hpath->up) {
		$iterator = $hstore->get_iter ($hpath);
		$package = $hstore->get ($iterator, 0);
	}

	my $fstore = $self->{__failure_store};

	$iterator = $fstore->append;
	$fstore->set ($iterator,
				  0 => 'gtk-dialog-warning',
				  1 => $test,
				  2 => $package);

	my $fpath = $fstore->get_path ($iterator);

	$node->setFailurePath ($fpath->to_string);

	push @{$self->{__failures}}, $node;

	$self->__selectTestCase ($node->getPath);
	
	return 1;
}

sub __handleReplyPid {
	my ($self, $pid) = @_;

	$self->{__pid} = $pid;

	return 1;
}

sub __resetGUI {
    my $self = shift;

    my $gladexml = $self->{__gladexml};

    if (@{$self->{__suites}}) {
		my $notebook = $gladexml->get_widget ('notebook');
		my $current_page = $notebook->get_current_page;
		my $view = $current_page == 0 ? 
			$self->{__failure_view} : $self->{__hierarchy_view};
		my $selected = $view->get_selection->count_selected_rows;

		my $state = $selected ? 'loaded_selected' : 'loaded';

		$self->__setGUIState ($state);

    } else {
		$self->__setGUIState ('initial');
    }
    
    Glib::Source->remove ($self->{__timeout_id}) if $self->{__timeout_id};
    $self->{__pid} = 0;
	undef $self->{__last_signal};

	return 1;
}

sub __handleReplyTerminated {
    my $self = shift;
	$self->__resetGUI;
    $self->__setStatusBar (__"Test terminated.");

    return 1;
}

sub __handleReplyStart {
    my ($self, $test) = @_;

    $self->__setStatusBar (__x"Running: {test}", test => $test);

	my $num_tests = $self->{__counter};

	my $num_errors = $self->{__error_count};
	my $num_failures = $self->{__failure_count} - $num_errors;
	my $message = __nx ("one test, ", "{num_tests} tests, ", $num_tests,
						num_tests => $num_tests);
	$message .= __nx ("one error, ", "{num_errors} errors, ", $num_errors,
						num_errors => $num_errors);
	$message .= __nx ("one failure", "{num_failures} failures", $num_failures,
						num_failures => $num_failures);

	$self->{__progress_bar}->set_text ($message);

	my $index = $num_tests;
	my $node = $self->{__planned}->[$index];

	my $store = $self->{__hierarchy_store};

	my $hpath = Gtk2::TreePath->new_from_string ($node->getPath);
	my $iterator = $store->get_iter ($hpath);

	my $icon = $store->get ($iterator, 1);
	$store->set ($iterator, 1 => 'gtk-apply');

    return 1;
}

sub __handleReplyEnd {
    my ($self, $test) = @_;

	++$self->{__counter};

	my $num_tests = $self->{__counter};
	my $fraction = $self->{__num_planned} ? 
		($num_tests / $self->{__num_planned}) : 1;
	$self->{__progress_bar}->set_fraction ($fraction);

	my $num_errors = $self->{__error_count};
	my $num_failures = $self->{__failure_count} - $num_errors;
	my $message = __nx ("one test, ", "{num_tests} tests, ", $num_tests,
						num_tests => $num_tests);
	$message .= __nx ("one error, ", "{num_errors} errors, ", $num_errors,
						num_errors => $num_errors);
	$message .= __nx ("one failure", "{num_failures} failures", $num_failures,
						num_failures => $num_failures);

	$self->{__progress_bar}->set_text ($message);

	if ($num_failures == 0 && $num_errors == 0) {
		$self->{__progress_bar}->modify_bg ('normal', $self->{__green}); 
		$self->{__progress_image}->set_from_stock ('gtk-apply', 'button');
	}

    return 1;
}

sub __handleReplySuccess {
    my ($self, $reply) = @_;

    my ($test) = split / +/, $reply, 1;

    $self->__setStatusBar (__x"Success: {test}", test => $test);

	my $index = $self->{__counter};

	my $node = $self->{__planned}->[$index];

	my $store = $self->{__hierarchy_store};

	my $hpath = Gtk2::TreePath->new_from_string ($node->getPath);
	my $iterator = $store->get_iter ($hpath);

	my $icon = $store->get ($iterator, 1);
	$store->set ($iterator, 1 => 'gtk-apply')
		unless $icon eq 'gtk-dialog-warning';

    return 1;
}

sub __handleReplyFailure {
    my ($self, $reply) = @_;

	++$self->{__failure_count};

    my ($test, $obj) = split / +/, $reply, 2;

    $self->__setStatusBar (__x"Failure: {test}", test => $test);

    my $failure = thaw decode_base64 $obj;

	my $package = $failure->{package};
	my $file = $failure->{file};
	my $line = $failure->{line};
	my $text = $failure->{text};

	my $index = $self->{__counter};
	my $node = $self->{__planned}->[$index];
	$node->setFailure;

	my $failure_store = $self->{__failure_store};

	my $iterator;
	if (defined $node->getFailurePath) {
		my $fpath = Gtk2::TreePath->new_from_string ($node->getFailurePath);
		$iterator = $failure_store->get_iter ($fpath);
	} else {
		$iterator = $failure_store->append;
		my $fpath = $failure_store->get_path ($iterator);
		$node->setFailurePath ($fpath->to_string);
		
		push @{$self->{__failures}}, $node;
	}

	$failure_store->set ($iterator,
						 0 => $node->getStockID,
						 1 => $test,
						 2 => $package,
						 3 => "$file:$line");

	$node->setResult ($text);

    $self->__setErrorTextBuffer ($text, $node->getOutput);

	$self->{__progress_image}->set_from_stock ($node->getStockID, 
											   'button');
	$self->{__progress_bar}->modify_bg ('normal', $self->{__red});

	my $store = $self->{__hierarchy_store};

	my $hpath = Gtk2::TreePath->new_from_string ($node->getPath);
	$iterator = $store->get_iter ($hpath);
	$store->set ($iterator, 1 => $node->getStockID);

	$self->__selectTestCase ($node->getPath);
	
    return 1;
}

sub __handleReplyError {
    my ($self, $reply) = @_;

	++$self->{__error_count};

	my $node = $self->{__planned}->[$self->{__counter}];
	$node->setError;

	$self->__handleReplyFailure ($reply);
}

# FIXME! What should happen here?
sub __handleReplyWarning {
	my ($self, $warning) = @_;

	warn "$warning\n";

	return 1;
}

sub __setErrorTextBuffer {
	my ($self, $text, $output) = @_;

	my $buffer = $self->{__error_textbuffer};
	
	$text = '' unless defined $text;

	$buffer->set_text ($text);

	my ($start, $end) = $buffer->get_bounds;
	
	$buffer->apply_tag_by_name ('error', $start, $end);
	$buffer->insert ($start, $output) if defined $output;

	return 1;
}

sub __handleReplyAbort {
	my ($self, $message) = @_;

	$self->__setErrorTextBuffer ($message);
	$self->__handleReplyTerminated;
	$self->__setStatusBar (__"Test aborted.");

	return 1;
}

sub __sendKill {
	my ($self) = @_;

	Glib::Source->remove ($self->{__timeout_id}) if $self->{__timeout_id};
	return 1 unless $self->{__pid};

	# Still alive?
	my $alive = kill 0 => $self->{__pid};
	unless ($alive) {
		$self->__resetGUI;
		$self->__setStatusBar (__"Test process terminated.");
		return 1;
	}

	$self->{__last_signal} = -1 unless defined $self->{__last_signal};
	
	++$self->{__last_signal};

	unless (defined $self->{__kill_signals}->[$self->{__last_signal}]) {
		$self->__resetGUI;
		$self->__setStatusBar 
		    (__"Child process cannot be terminated.");
		return 1;
	}

	my ($signame, $signo) = 
		@{$self->{__kill_signals}->[$self->{__last_signal}]};

	$self->__setStatusBar (__x ("Child process signaled with SIG{NAME}.",
								NAME => $signame));
	kill $signo => $self->{__pid};
	
	$self->{__timeout_id} = Glib::Timeout->add (1500, sub {
	    $self->__sendKill;
	    return 1;
	});

	return 1;
}

sub __setGUIState {
	my ($self, $state) = @_;
	
	my $record = GUI_STATES->{$state};

	unless ($record) {
		my $message = __x (<<EOF, state => $state);
Internal error: Unrecognized error state "{state}".  This should
not happen.
EOF

        my $main_window = $self->{__gladexml}->get_widget ('GTestRunner');
		my $dialog = Gtk2::MessageDialog->new ($main_window,
											   'destroy-with-parent',
											   'error',
											   'ok',
											   $message,
											   );
		$dialog->run;
		Gtk2->main_quit;
		exit 1;
	}

	$self->{__gui_state} = $state;

	my $gladexml = $self->{__gladexml};
	while (my ($key, $value) = each %$record) {
		$gladexml->get_widget ($key)->set_sensitive ($value);
	}

	return 1;
}

sub __selectAllFailures {
	my ($self) = @_;

	my $hstore = $self->{__hierarchy_store};
	my $hview = $self->{__hierarchy_view};
	my $hselection = $hview->get_selection;
	$hselection->unselect_all;

	my $fstore = $self->{__failure_store};
	my $fview = $self->{__failure_view};
	my $fselection = $fview->get_selection;
	$fselection->unselect_all;
	
	my $records = $self->{__tests_by_path};
	foreach my $str_hpath (keys %$records) {
		my $str_fpath = $records->{$str_hpath}->{failure_path};
		next unless defined $str_fpath;

		my $hpath = Gtk2::TreePath->new_from_string ($str_hpath);
		$hselection->select_path ($hpath);

		my $fpath = Gtk2::TreePath->new_from_string ($str_fpath);
		$fselection->select_path ($fpath);
	}

	if (!$self->{__pid}) {
		my $new_state = 'loaded';
		$new_state .= '_selected' if $hselection->count_selected_rows;
	}
}

1;

=head1 NAME

Test::Unit::GTestRunner - Unit testing framework helper class

=head1 SYNOPSIS

 use Test::Unit::GTestRunner;

 Test::Unit::GTestRunner->new->start ($my_testcase_class);

 Test::Unit::GTestRunner::main ($my_testcase_class);

=head1 DESCRIPTION

If you just want to run a unit test (suite), try it like this:

    gtestrunner "MyTestSuite.pm"

Try "perldoc gtestrunner" or "man gtestrunner" for more information.

This class is a GUI test runner using the Gimp Toolkit Gtk+ (which
is called Gtk2 in Perl).  You can use it if you want to integrate
the testing framework into your own application.

For a description of the graphical user interface, please see
gtestrunner(1).

=head1 EXAMPLE

You will usually invoke it from a runner script like this:

    #! /usr/local/bin/perl -w

    use strict;
  
    require Test::Unit::GTestRunner;

    Test::Unit::GTestRunner::main (@ARGV) or exit 1;

See Test::Unit::TestRunner (3) for details.

An internationalized version would go like this:

    #!/usr/bin/perl -w

    use strict;

    use Test::Unit::GTestRunner;
    use POSIX;
    use Locale::Messages qw (LC_ALL);

    POSIX::setlocale (LC_ALL, "");

    Test::Unit::GTestRunner::main (@ARGV) or exit (1);

=head1 CONSTRUCTOR

=over 4

=item B<new>

The constructor takes no arguments.  It will throw an exception in
case of failure.

=back

=head1 METHODS

=over 4

=item B<start [SUITE]...>

The method fires up the graphical user interface and will never
return.

The optional arguments B<SUITE> can either be the name of a file
containing a test suite (see Test::Unit::TestSuite(3pm)), for
example "TS_MySuite.pm", or the name of a Perl module, for example
"Tests::TS_MySuite".  Multiple suites passed as arguments to 
the method are assembled into one virtual top-level suite that is
hidden from the display.

=back

=head1 FUNCTIONS

=over 4

=item B<main [SUITE]...>

If you prefer a functional interface, you can also start a test
session with

    Test::Unit::GTestRunner::main ($suite_name);

The optional argument B<SUITE> is interpreted as described above
for the method start().

=back

=head1 AUTHOR

Copyright (C) 2004-2006, Guido Flohr E<lt>guido@imperia.netE<gt>, all
rights reserved.  See the source code for details.

This software is contributed to the Perl community by Imperia 
 (L<http://www.imperia.net/>).

=head1 ENVIRONMENT

The package is internationalized with libintl-perl, hence the 
environment variables "LANGUAGE", "LANG", "LC_MESSAGES", and
"LC_ALL" will influence the language in which the GUI and 
messages are presented.

=head1 SEE ALSO

gtestrunner(1), Test::Unit::TestRunner(3pm), Test::Unit(3pm), 
Locale::Messages(3pm), perl(1)

=cut

#Local Variables:
#mode: perl
#perl-indent-level: 4
#perl-continued-statement-offset: 4
#perl-continued-brace-offset: 0
#perl-brace-offset: -4
#perl-brace-imaginary-offset: 0
#perl-label-offset: -4
#cperl-indent-level: 4
#cperl-continued-statement-offset: 2
#tab-width: 4
#End:

__DATA__
<?xml version="1.0" standalone="no"?> <!--*- mode: xml -*-->
<!DOCTYPE glade-interface SYSTEM "http://glade.gnome.org/glade-2.0.dtd">

<glade-interface>

<widget class="GtkWindow" id="GTestRunner">
  <property name="visible">True</property>
  <property name="title" translatable="yes">GTestRunner</property>
  <property name="type">GTK_WINDOW_TOPLEVEL</property>
  <property name="window_position">GTK_WIN_POS_NONE</property>
  <property name="modal">False</property>
  <property name="default_width">512</property>
  <property name="default_height">480</property>
  <property name="resizable">True</property>
  <property name="destroy_with_parent">False</property>
  <property name="decorated">True</property>
  <property name="skip_taskbar_hint">False</property>
  <property name="skip_pager_hint">False</property>
  <property name="type_hint">GDK_WINDOW_TYPE_HINT_NORMAL</property>
  <property name="gravity">GDK_GRAVITY_NORTH_WEST</property>
  <property name="focus_on_map">True</property>
  <signal name="delete_event" handler="__quitApplication" last_modification_time="Fri, 23 Sep 2005 12:30:11 GMT"/>

  <child>
    <widget class="GtkVBox" id="vbox1">
      <property name="visible">True</property>
      <property name="homogeneous">False</property>
      <property name="spacing">0</property>

      <child>
	<widget class="GtkMenuBar" id="menubar1">
	  <property name="visible">True</property>

	  <child>
	    <widget class="GtkMenuItem" id="menuitem1">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">_File</property>
	      <property name="use_underline">True</property>

	      <child>
		<widget class="GtkMenu" id="menuitem1_menu">

		  <child>
		    <widget class="GtkImageMenuItem" id="open_menu_item">
		      <property name="visible">True</property>
		      <property name="label">gtk-open</property>
		      <property name="use_stock">True</property>
		      <signal name="activate" handler="__showFileSelection" last_modification_time="Wed, 05 Oct 2005 20:15:40 GMT"/>
		    </widget>
		  </child>

		  <child>
		    <widget class="GtkSeparatorMenuItem" id="separatormenuitem1">
		      <property name="visible">True</property>
		    </widget>
		  </child>

		  <child>
		    <widget class="GtkImageMenuItem" id="quit1">
		      <property name="visible">True</property>
		      <property name="label">gtk-quit</property>
		      <property name="use_stock">True</property>
		      <signal name="activate" handler="__quitApplication" last_modification_time="Fri, 23 Sep 2005 12:22:23 GMT"/>
		    </widget>
		  </child>
		</widget>
	      </child>
	    </widget>
	  </child>

	  <child>
	    <widget class="GtkMenuItem" id="menuitem2">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">_Tests</property>
	      <property name="use_underline">True</property>

	      <child>
		<widget class="GtkMenu" id="menuitem2_menu">

		  <child>
		    <widget class="GtkImageMenuItem" id="run_menu_item">
		      <property name="visible">True</property>
		      <property name="label" translatable="yes">_Run</property>
		      <property name="use_underline">True</property>
		      <signal name="activate" handler="__runAllTests" last_modification_time="Fri, 23 Sep 2005 12:22:23 GMT"/>
		      <accelerator key="F9" modifiers="0" signal="activate"/>

		      <child internal-child="image">
			<widget class="GtkImage" id="image16">
			  <property name="visible">True</property>
			  <property name="stock">gtk-execute</property>
			  <property name="icon_size">1</property>
			  <property name="xalign">0.5</property>
			  <property name="yalign">0.5</property>
			  <property name="xpad">0</property>
			  <property name="ypad">0</property>
			</widget>
		      </child>
		    </widget>
		  </child>

		  <child>
		    <widget class="GtkImageMenuItem" id="run_selected_menu_item">
		      <property name="visible">True</property>
		      <property name="label" translatable="yes">Run _Selected</property>
		      <property name="use_underline">True</property>
		      <signal name="activate" handler="__runSelectedTests" last_modification_time="Tue, 25 Oct 2005 16:30:42 GMT"/>
		      <accelerator key="F9" modifiers="GDK_SHIFT_MASK" signal="activate"/>

		      <child internal-child="image">
			<widget class="GtkImage" id="image17">
			  <property name="visible">True</property>
			  <property name="stock">gtk-execute</property>
			  <property name="icon_size">1</property>
			  <property name="xalign">0.5</property>
			  <property name="yalign">0.5</property>
			  <property name="xpad">0</property>
			  <property name="ypad">0</property>
			</widget>
		      </child>
		    </widget>
		  </child>

		  <child>
		    <widget class="GtkImageMenuItem" id="cancel_menu_item">
		      <property name="visible">True</property>
		      <property name="label">gtk-cancel</property>
		      <property name="use_stock">True</property>
		      <signal name="activate" handler="__cancelTests" last_modification_time="Fri, 23 Sep 2005 12:22:23 GMT"/>
		      <accelerator key="Escape" modifiers="0" signal="activate"/>
		    </widget>
		  </child>

		  <child>
		    <widget class="GtkImageMenuItem" id="refresh_menu_item">
		      <property name="visible">True</property>
		      <property name="label">gtk-refresh</property>
		      <property name="use_stock">True</property>
		      <signal name="activate" handler="__refreshSuite" last_modification_time="Tue, 01 Nov 2005 13:07:02 GMT"/>
		      <accelerator key="r" modifiers="GDK_SHIFT_MASK" signal="activate"/>
		    </widget>
		  </child>
		</widget>
	      </child>
	    </widget>
	  </child>

	  <child>
	    <widget class="GtkMenuItem" id="settings1">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">_Settings</property>
	      <property name="use_underline">True</property>

	      <child>
		<widget class="GtkMenu" id="settings1_menu">

		  <child>
		    <widget class="GtkCheckMenuItem" id="always_refresh_menuitem">
		      <property name="visible">True</property>
		      <property name="label" translatable="yes">_Refresh suites before every run</property>
		      <property name="use_underline">True</property>
		      <property name="active">True</property>
		      <signal name="activate" handler="__refreshSuitesBeforeEveryRun" last_modification_time="Tue, 01 Nov 2005 13:52:20 GMT"/>
		    </widget>
		  </child>
		</widget>
	      </child>
	    </widget>
	  </child>

	  <child>
	    <widget class="GtkMenuItem" id="menuitem4">
	      <property name="visible">True</property>
	      <property name="label" translatable="yes">_Help</property>
	      <property name="use_underline">True</property>

	      <child>
		<widget class="GtkMenu" id="menuitem4_menu">

		  <child>
		    <widget class="GtkMenuItem" id="about1">
		      <property name="visible">True</property>
		      <property name="label" translatable="yes">_About</property>
		      <property name="use_underline">True</property>
		      <signal name="activate" handler="__showAboutDialog" last_modification_time="Wed, 05 Oct 2005 19:44:37 GMT"/>
		    </widget>
		  </child>
		</widget>
	      </child>
	    </widget>
	  </child>
	</widget>
	<packing>
	  <property name="padding">0</property>
	  <property name="expand">False</property>
	  <property name="fill">False</property>
	</packing>
      </child>

      <child>
	<widget class="GtkVBox" id="vbox2">
	  <property name="visible">True</property>
	  <property name="homogeneous">False</property>
	  <property name="spacing">0</property>

	  <child>
	    <widget class="GtkToolbar" id="toolbar1">
	      <property name="visible">True</property>
	      <property name="orientation">GTK_ORIENTATION_HORIZONTAL</property>
	      <property name="toolbar_style">GTK_TOOLBAR_BOTH</property>
	      <property name="tooltips">True</property>
	      <property name="show_arrow">False</property>

	      <child>
		<widget class="GtkToolButton" id="open_button">
		  <property name="visible">True</property>
		  <property name="stock_id">gtk-open</property>
		  <property name="visible_horizontal">True</property>
		  <property name="visible_vertical">True</property>
		  <property name="is_important">False</property>
		  <signal name="clicked" handler="__showFileSelection" last_modification_time="Wed, 05 Oct 2005 20:26:18 GMT"/>
		</widget>
		<packing>
		  <property name="expand">False</property>
		  <property name="homogeneous">True</property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkSeparatorToolItem" id="separatortoolitem1">
		  <property name="visible">True</property>
		  <property name="draw">True</property>
		  <property name="visible_horizontal">True</property>
		  <property name="visible_vertical">True</property>
		</widget>
		<packing>
		  <property name="expand">False</property>
		  <property name="homogeneous">False</property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkToolButton" id="run_button">
		  <property name="visible">True</property>
		  <property name="sensitive">False</property>
		  <property name="label" translatable="yes">Run</property>
		  <property name="use_underline">True</property>
		  <property name="stock_id">gtk-execute</property>
		  <property name="visible_horizontal">True</property>
		  <property name="visible_vertical">True</property>
		  <property name="is_important">False</property>
		  <signal name="clicked" handler="__runAllTests" last_modification_time="Fri, 23 Sep 2005 12:22:49 GMT"/>
		</widget>
		<packing>
		  <property name="expand">False</property>
		  <property name="homogeneous">True</property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkToolButton" id="run_selected_button">
		  <property name="visible">True</property>
		  <property name="sensitive">False</property>
		  <property name="label" translatable="yes">Selected</property>
		  <property name="use_underline">True</property>
		  <property name="stock_id">gtk-execute</property>
		  <property name="visible_horizontal">True</property>
		  <property name="visible_vertical">True</property>
		  <property name="is_important">False</property>
		  <signal name="clicked" handler="__runSelectedTests" last_modification_time="Wed, 26 Oct 2005 09:56:48 GMT"/>
		</widget>
		<packing>
		  <property name="expand">False</property>
		  <property name="homogeneous">True</property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkToolButton" id="cancel_button">
		  <property name="visible">True</property>
		  <property name="sensitive">False</property>
		  <property name="stock_id">gtk-cancel</property>
		  <property name="visible_horizontal">True</property>
		  <property name="visible_vertical">True</property>
		  <property name="is_important">False</property>
		  <signal name="clicked" handler="__cancelTests" last_modification_time="Fri, 23 Sep 2005 12:23:12 GMT"/>
		</widget>
		<packing>
		  <property name="expand">False</property>
		  <property name="homogeneous">True</property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkToolButton" id="refresh_button">
		  <property name="visible">True</property>
		  <property name="sensitive">False</property>
		  <property name="tooltip" translatable="yes">Refresh the test suite</property>
		  <property name="stock_id">gtk-refresh</property>
		  <property name="visible_horizontal">True</property>
		  <property name="visible_vertical">True</property>
		  <property name="is_important">False</property>
		  <signal name="clicked" handler="__refreshSuite" last_modification_time="Mon, 31 Oct 2005 08:55:50 GMT"/>
		</widget>
		<packing>
		  <property name="expand">False</property>
		  <property name="homogeneous">True</property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkSeparatorToolItem" id="separatortoolitem2">
		  <property name="visible">True</property>
		  <property name="draw">True</property>
		  <property name="visible_horizontal">True</property>
		  <property name="visible_vertical">True</property>
		</widget>
		<packing>
		  <property name="expand">False</property>
		  <property name="homogeneous">False</property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkToolItem" id="toolitem1">
		  <property name="visible">True</property>
		  <property name="visible_horizontal">True</property>
		  <property name="visible_vertical">True</property>
		  <property name="is_important">False</property>

		  <child>
		    <widget class="GtkCheckButton" id="always_refresh_checkbutton">
		      <property name="visible">True</property>
		      <property name="can_focus">True</property>
		      <property name="label" translatable="yes">Refresh suites before every run</property>
		      <property name="use_underline">True</property>
		      <property name="relief">GTK_RELIEF_NORMAL</property>
		      <property name="focus_on_click">True</property>
		      <property name="active">True</property>
		      <property name="inconsistent">False</property>
		      <property name="draw_indicator">True</property>
		      <signal name="toggled" handler="__refreshSuitesBeforeEveryRun" last_modification_time="Tue, 01 Nov 2005 13:52:46 GMT"/>
		    </widget>
		  </child>
		</widget>
		<packing>
		  <property name="expand">False</property>
		  <property name="homogeneous">False</property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkSeparatorToolItem" id="separatortoolitem3">
		  <property name="visible">True</property>
		  <property name="draw">True</property>
		  <property name="visible_horizontal">True</property>
		  <property name="visible_vertical">True</property>
		</widget>
		<packing>
		  <property name="expand">False</property>
		  <property name="homogeneous">False</property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkToolButton" id="toolbutton5">
		  <property name="visible">True</property>
		  <property name="label" translatable="yes">Quit</property>
		  <property name="use_underline">True</property>
		  <property name="stock_id">gtk-quit</property>
		  <property name="visible_horizontal">True</property>
		  <property name="visible_vertical">True</property>
		  <property name="is_important">False</property>
		  <signal name="clicked" handler="__quitApplication" last_modification_time="Tue, 25 Oct 2005 16:32:29 GMT"/>
		</widget>
		<packing>
		  <property name="expand">False</property>
		  <property name="homogeneous">True</property>
		</packing>
	      </child>
	    </widget>
	    <packing>
	      <property name="padding">0</property>
	      <property name="expand">False</property>
	      <property name="fill">True</property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkHBox" id="hbox1">
	      <property name="visible">True</property>
	      <property name="homogeneous">False</property>
	      <property name="spacing">0</property>

	      <child>
		<widget class="GtkImage" id="progressimage">
		  <property name="visible">True</property>
		  <property name="icon_size">4</property>
		  <property name="icon_name">gtk-dialog-question</property>
		  <property name="xalign">0.5</property>
		  <property name="yalign">0.5</property>
		  <property name="xpad">0</property>
		  <property name="ypad">0</property>
		</widget>
		<packing>
		  <property name="padding">0</property>
		  <property name="expand">False</property>
		  <property name="fill">False</property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkProgressBar" id="progressbar">
		  <property name="visible">True</property>
		  <property name="orientation">GTK_PROGRESS_LEFT_TO_RIGHT</property>
		  <property name="fraction">0</property>
		  <property name="pulse_step">0.10000000149</property>
		  <property name="ellipsize">PANGO_ELLIPSIZE_NONE</property>
		</widget>
		<packing>
		  <property name="padding">0</property>
		  <property name="expand">True</property>
		  <property name="fill">True</property>
		</packing>
	      </child>
	    </widget>
	    <packing>
	      <property name="padding">0</property>
	      <property name="expand">False</property>
	      <property name="fill">False</property>
	    </packing>
	  </child>

	  <child>
	    <widget class="GtkVPaned" id="vpaned1">
	      <property name="visible">True</property>
	      <property name="can_focus">True</property>

	      <child>
		<widget class="GtkNotebook" id="notebook">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="show_tabs">True</property>
		  <property name="show_border">True</property>
		  <property name="tab_pos">GTK_POS_TOP</property>
		  <property name="scrollable">False</property>
		  <property name="enable_popup">False</property>

		  <child>
		    <widget class="GtkScrolledWindow" id="scrolledwindow4">
		      <property name="height_request">140</property>
		      <property name="visible">True</property>
		      <property name="can_focus">True</property>
		      <property name="hscrollbar_policy">GTK_POLICY_AUTOMATIC</property>
		      <property name="vscrollbar_policy">GTK_POLICY_ALWAYS</property>
		      <property name="shadow_type">GTK_SHADOW_IN</property>
		      <property name="window_placement">GTK_CORNER_TOP_LEFT</property>

		      <child>
			<widget class="GtkTreeView" id="failure_treeview">
			  <property name="border_width">4</property>
			  <property name="height_request">120</property>
			  <property name="visible">True</property>
			  <property name="can_focus">True</property>
			  <property name="headers_visible">True</property>
			  <property name="rules_hint">True</property>
			  <property name="reorderable">False</property>
			  <property name="enable_search">True</property>
			  <property name="fixed_height_mode">False</property>
			  <property name="hover_selection">False</property>
			  <property name="hover_expand">False</property>
			</widget>
		      </child>
		    </widget>
		    <packing>
		      <property name="tab_expand">False</property>
		      <property name="tab_fill">True</property>
		    </packing>
		  </child>

		  <child>
		    <widget class="GtkLabel" id="label1">
		      <property name="visible">True</property>
		      <property name="label" translatable="yes">Failures</property>
		      <property name="use_underline">False</property>
		      <property name="use_markup">False</property>
		      <property name="justify">GTK_JUSTIFY_LEFT</property>
		      <property name="wrap">False</property>
		      <property name="selectable">False</property>
		      <property name="xalign">0.5</property>
		      <property name="yalign">0.5</property>
		      <property name="xpad">0</property>
		      <property name="ypad">0</property>
		      <property name="ellipsize">PANGO_ELLIPSIZE_NONE</property>
		      <property name="width_chars">-1</property>
		      <property name="single_line_mode">False</property>
		      <property name="angle">0</property>
		    </widget>
		    <packing>
		      <property name="type">tab</property>
		    </packing>
		  </child>

		  <child>
		    <widget class="GtkScrolledWindow" id="scrolledwindow3">
		      <property name="visible">True</property>
		      <property name="can_focus">True</property>
		      <property name="hscrollbar_policy">GTK_POLICY_AUTOMATIC</property>
		      <property name="vscrollbar_policy">GTK_POLICY_ALWAYS</property>
		      <property name="shadow_type">GTK_SHADOW_IN</property>
		      <property name="window_placement">GTK_CORNER_TOP_LEFT</property>

		      <child>
			<widget class="GtkTreeView" id="hierarchy_treeview">
			  <property name="height_request">140</property>
			  <property name="visible">True</property>
			  <property name="can_focus">True</property>
			  <property name="headers_visible">True</property>
			  <property name="rules_hint">False</property>
			  <property name="reorderable">False</property>
			  <property name="enable_search">True</property>
			  <property name="fixed_height_mode">False</property>
			  <property name="hover_selection">False</property>
			  <property name="hover_expand">False</property>
			</widget>
		      </child>
		    </widget>
		    <packing>
		      <property name="tab_expand">False</property>
		      <property name="tab_fill">True</property>
		    </packing>
		  </child>

		  <child>
		    <widget class="GtkLabel" id="label2">
		      <property name="visible">True</property>
		      <property name="label" translatable="yes">Test Hierarchy</property>
		      <property name="use_underline">False</property>
		      <property name="use_markup">False</property>
		      <property name="justify">GTK_JUSTIFY_LEFT</property>
		      <property name="wrap">False</property>
		      <property name="selectable">False</property>
		      <property name="xalign">0.5</property>
		      <property name="yalign">0.5</property>
		      <property name="xpad">0</property>
		      <property name="ypad">0</property>
		      <property name="ellipsize">PANGO_ELLIPSIZE_NONE</property>
		      <property name="width_chars">-1</property>
		      <property name="single_line_mode">False</property>
		      <property name="angle">0</property>
		    </widget>
		    <packing>
		      <property name="type">tab</property>
		    </packing>
		  </child>
		</widget>
		<packing>
		  <property name="shrink">True</property>
		  <property name="resize">False</property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkScrolledWindow" id="scrolledwindow1">
		  <property name="height_request">120</property>
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="hscrollbar_policy">GTK_POLICY_AUTOMATIC</property>
		  <property name="vscrollbar_policy">GTK_POLICY_AUTOMATIC</property>
		  <property name="shadow_type">GTK_SHADOW_IN</property>
		  <property name="window_placement">GTK_CORNER_TOP_LEFT</property>

		  <child>
		    <widget class="GtkTextView" id="errortextview">
		      <property name="visible">True</property>
		      <property name="can_focus">True</property>
		      <property name="editable">False</property>
		      <property name="overwrite">False</property>
		      <property name="accepts_tab">True</property>
		      <property name="justification">GTK_JUSTIFY_LEFT</property>
		      <property name="wrap_mode">GTK_WRAP_NONE</property>
		      <property name="cursor_visible">True</property>
		      <property name="pixels_above_lines">0</property>
		      <property name="pixels_below_lines">0</property>
		      <property name="pixels_inside_wrap">0</property>
		      <property name="left_margin">0</property>
		      <property name="right_margin">0</property>
		      <property name="indent">0</property>
		      <property name="text" translatable="yes"></property>
		    </widget>
		  </child>
		</widget>
		<packing>
		  <property name="shrink">True</property>
		  <property name="resize">True</property>
		</packing>
	      </child>
	    </widget>
	    <packing>
	      <property name="padding">0</property>
	      <property name="expand">True</property>
	      <property name="fill">True</property>
	    </packing>
	  </child>
	</widget>
	<packing>
	  <property name="padding">0</property>
	  <property name="expand">True</property>
	  <property name="fill">True</property>
	</packing>
      </child>

      <child>
	<widget class="GtkStatusbar" id="statusbar1">
	  <property name="visible">True</property>
	  <property name="has_resize_grip">True</property>
	</widget>
	<packing>
	  <property name="padding">0</property>
	  <property name="expand">False</property>
	  <property name="fill">False</property>
	</packing>
      </child>
    </widget>
  </child>
</widget>

</glade-interface>
