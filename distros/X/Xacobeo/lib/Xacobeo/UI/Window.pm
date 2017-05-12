package Xacobeo::UI::Window;

=head1 NAME

Xacobeo::UI::Window - Main window of Xacobeo.

=head1 SYNOPSIS

	use Gtk2 qw(-init);
	use Xacobeo::UI::Window;
	
	my $xacobeo = Xacobeo::UI::Window->new();
	$xacobeo->signal_connect(destroy => sub { Gtk2->main_quit(); });
	$xacobeo->show_all();
	Gtk2->main();

=head1 DESCRIPTION

The application's main window. This widget is a L<Gtk2::Window>.

=head1 PROPERTIES

The following properties are defined:

=head2 source-view

The source view where the document's content is displayed.

=head2 dom-view

The widget displaying the results of a search

=head2 results-view

The UI Manager used by this widget.

=head2 namespaces-view

The widget displaying the namespaces of the current document.

=head2 xpath-entry

The entry where the XPath expression will be edited.

=head2 statusbar

The window's statusbar.

=head2 notebook

The notbook widget at the bottom of the window.

=head2 evaluate-button

The button starting a search.

=head2 conf

A reference to the main configuration singleton.

=head2 ui-manager

The UI Manager used by this widget.

=head1 METHODS

The following methods are available:

=head2 new

Creates a new instance. This is simply the parent's constructor.

=cut

use strict;
use warnings;

use Data::Dumper;

use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::SimpleList;
use Carp;

use Xacobeo;
use Xacobeo::UI::SourceView;
use Xacobeo::UI::DomView;
use Xacobeo::UI::Statusbar;
use Xacobeo::UI::XPathEntry;
use Xacobeo::Document;
use Xacobeo::GObject;
use Xacobeo::I18n;
use Xacobeo::Timer;
use Xacobeo::Error;
use Xacobeo::Utils qw{
	isa_dom_nodelist
	escape_xml_text
	scrollify
};


Xacobeo::GObject->register_package('Gtk2::Window' =>
	properties => [
		Glib::ParamSpec->object(
			'source-view',
			"Source View",
			"The source view where the document content is displayed",
			'Xacobeo::UI::SourceView',
			['readable', 'writable'],
		),

		Glib::ParamSpec->object(
			'dom-view',
			"DOM View",
			"The DOM tree view where the document nodes are displayed",
			'Xacobeo::UI::DomView',
			['readable', 'writable'],
		),

		Glib::ParamSpec->object(
			'results-view',
			"Results View",
			"The widget displaying the results of a search",
			'Xacobeo::UI::SourceView',
			['readable', 'writable'],
		),

		Glib::ParamSpec->scalar(
			'namespaces-view',
			"Namespaces View",
			"The widget displaying the namespaces of the current document",
			['readable', 'writable'],
		),

		Glib::ParamSpec->object(
			'xpath-entry',
			"XPath Entry",
			"The entry where the XPath expresion will be edited",
			'Xacobeo::UI::XPathEntry',
			['readable', 'writable'],
		),

		Glib::ParamSpec->object(
			'statusbar',
			"Statusbar",
			"The window's statusbar",
			'Xacobeo::UI::Statusbar',
			['readable', 'writable'],
		),

		Glib::ParamSpec->object(
			'ui-manager',
			"UI Manager",
			"The UI Manager that provides the UI",
			'Gtk2::UIManager',
			['readable', 'writable'],
		),

		Glib::ParamSpec->object(
			'notebook',
			"Notebook",
			"The notbook widget at the bottom of the window",
			'Gtk2::Notebook',
			['readable', 'writable'],
		),

		Glib::ParamSpec->object(
			'evaluate-button',
			"Evaluate Button",
			"The button starting a search",
			'Gtk2::Button',
			['readable', 'writable'],
		),

		Glib::ParamSpec->object(
			'conf',
			"Configuration",
			"A reference to the main configuration singleton",
			'Xacobeo::Conf',
			['readable', 'writable', 'construct-only'],
		),
	],
);


sub new {
	my $class = shift;

	my $conf = Xacobeo::Conf->get_conf;
	my $self = $class->SUPER::new(conf => $conf);

	# Pimp a bit the window (title, icon, size)
	$self->set_title(__("No document"));
	$self->set_icon(
		Gtk2::Gdk::Pixbuf->new_from_file(
			$conf->share_file('pixmaps', 'xacobeo.png')
		)
	);
	$self->set_size_request(800, 600);

	my $ui_manager = $self->_create_ui_manager();
	$self->ui_manager($ui_manager);


	# Build the window's widgets
	my $vbox = Gtk2::VBox->new(FALSE, 0);
	$self->add($vbox);

	my $menu = $self->ui_manager->get_widget('/MenuBar');
	$vbox->pack_start($menu, FALSE, FALSE, 0);
	$vbox->pack_start($self->_create_search_bar, FALSE, TRUE, 0);
	$vbox->pack_start($self->_create_main_content, TRUE, TRUE, 0);

	my $statusbar = Xacobeo::UI::Statusbar->new();
	$self->statusbar($statusbar);
	$vbox->pack_start($statusbar, FALSE, TRUE, 0);


	# Connect the signals
	$self->auto_connect(dom_view => 'node-selected');
	$self->auto_connect(xpath_entry => 'xpath-changed');

	$self->auto_connect(xpath_entry => 'activate', \&callback_execute_xpath);
	$self->auto_connect(evaluate_button => 'activate', \&callback_execute_xpath);
	$self->auto_connect(evaluate_button => 'clicked', \&callback_execute_xpath);

	return $self;
}


#
# Helper for connecting signals easily.
#
# Args:
#   $object:   the name of object that will fire the signal
#   $signal:   the name of the signal
#   $callback: the callback to connect, if no callback is provided then
#              "callback_$signal" will be used instead (Optional).
#
sub auto_connect {
	my $self = shift;
	my ($object, $signal, $callback) = @_;

	if (! $callback) {
		# Build the callback's name based on the signal name
		my $name = "callback_$signal";
		$name =~ tr/-/_/;
		$callback = $self->can($name) or croak "Can't find callback: $name";
	}


	$self->{$object}->signal_connect($signal => sub { $self->$callback(@_); });
}


#
# Display the selected node in the source view and in the results view. The
# selection is made from the tree view and we receive selected node that has to
# be displayed.
#
sub callback_node_selected {
	my $self = shift;
	my ($view, $node) = @_;

	$self->source_view->show_node($node);
	$self->display_results($node);
}


#
# Enable/Disable the evaluate button based on the validity of the XPath
# expression.
#
sub callback_xpath_changed {
	my $self = shift;
	my ($entry, $xpath, $is_valid) = @_;

	$self->evaluate_button->set_sensitive($is_valid);
}


#
# Execute the XPath expression on the current document.
#
sub callback_execute_xpath {
	my $self = shift;

	return unless $self->xpath_entry->is_valid;

	my $xpath = $self->xpath_entry->get_text();
	my $document = $self->source_view->document or return;

	my $timer = Xacobeo::Timer->start();
	my $result;
	my $find_successful = eval {
		$result = $document->find($xpath);
		1;
	};
	my $error = $@;
	$timer->stop();

	if ($find_successful) {
		my $count = isa_dom_nodelist($result) ? $result->size : 1;
		my $format = __n("Found %d result in %0.3fs", "Found %d results in %0.3fs", $count);
		$self->statusbar->displayf($format, $count, $timer->elapsed);
	}
	else {
		$result = Xacobeo::Error->new(xpath => $error);
		$self->statusbar->display(__("XPath query issued an error"));
	}

	# Display the results
	$self->display_results($result);

}


sub display_results {
	my $self = shift;
	my ($node) = @_;

	# Since the results view shows only the current node we use load_node instead
	# of show_node().
	$self->results_view->load_node($node);
	$self->notebook->set_current_page(0);
}


=head2 load_file

Load a new file into the application. The new document will be parsed and
displayed in the window.

Parameters:

=over

=item * $file

The file to load.

=item * $type

The type of document to load: I<xml> or I<html>. Defaults to I<xml> if no value
is provided.

=back

=cut

sub load_file {
	# Arguments
	my ($self, $file, $type) = @_;
	$type ||= 'xml';

	my $timer = Xacobeo::Timer->start();

	# Parse the content
	my $t_load = Xacobeo::Timer->start(__('Load document'));
	my $document;
	eval {
		$document = Xacobeo::Document->new_from_file($file, $type);
		1;
	} or do {
		my $error = $@;
		$self->statusbar->display(
			__x("Can't read {file}: {error}", file => $file, error => $error)
		);
		return;
	};
	undef $t_load;


	# Fill the widgets
	$self->set_title($file);
	$self->load_document($document);


	# Show the timers
	$timer->stop();
	if ($document) {
		my $format = __n(
			"Document loaded in %.3f second",
			"Document loaded in %.3f seconds",
			int($timer->elapsed),
		);
		$self->statusbar->displayf($format, $timer->elapsed);
	}
	else {
		# Invoke the time elapsed this way the value is not printed to the console
		$timer->elapsed;
	}
}


=head2 load_document

Load a new document into the application. The document will be parsed and
displayed in the window.

Parameters:

=over

=item * $document

The document to load.

=back

=cut

sub load_document {
	# Arguments
	my ($self, $document) = @_;

	my ($node, $namespaces) = $document ? ($document->documentNode, $document->namespaces) : (undef, {});
	
	# Update the text widget
	my $t_syntax = Xacobeo::Timer->start(__('Syntax Highlight'));
	$self->source_view->set_document($document);
	$self->source_view->load_node($node);
	undef $t_syntax;

	# Clear the previous results
	$self->results_view->set_document($document);

	# Populate the DOM view tree
	my $t_dom = Xacobeo::Timer->start(__('DOM Tree'));
	$self->dom_view->set_document($document);
	$self->dom_view->load_node($node);
	undef $t_dom;

	# The XPath entry needs the document since it has the namespaces that are
	# available to the current XPath expression
	$self->xpath_entry->set_document($document);

	# Populate the namespaces view
	my @namespaces;
	while (my ($uri, $prefix) = each %{ $namespaces }) {
		push @namespaces, [$prefix, $uri];
	}
	@{ $self->namespaces_view->{data} } = @namespaces;
}



sub set_title {
	my $self = shift;
	my ($short) = @_;
	
	my $title = $self->conf->app_name;
	if ($short) {
		$title .= ' - ' . $short;
	}
	
	$self->SUPER::set_title($title);
}



=head2 set_xpath

Set the XPath expression to display in the XPath text area. The expression is
not evaluated.

Parameters:

=over

=item * $xpath

The XPath expression to set

=back

=cut

sub set_xpath {
	my ($self, $xpath) = @_;
	croak 'Usage: $window->set_xpath($xpath)' unless defined $xpath;

	$self->xpath_entry->set_text($xpath);
}


#
# Called when a new file has to be loaded
#
sub do_show_file_open_dialog {
	my $self = shift;

	my $dialog = Gtk2::FileChooserDialog->new(
		__("Open file..."),
		$self, # parent window
		'open',
		'gtk-cancel' => 'cancel',
		'gtk-ok'     => 'ok',
	);

	$dialog->signal_connect(response => sub {
		my ($dialog, $response) = @_;

		if ($response eq 'ok') {
			my $file = $dialog->get_filename;
			print "File is $file\n";
			return if -d $file;
			$self->load_file($file, 'xml');
		}

		$dialog->destroy();
	});

	$dialog->run();
}


#
# Called when the window has to be closed
#
sub do_quit {
	my $self = shift;
	$self->destroy();
	return;
}


#
# Called when the about dialog has to be shown
#
sub do_show_about_dialog {
	my $self = shift;

	my $name = $self->conf->app_name;

	my $dialog = Gtk2::AboutDialog->new();
	$dialog->set_title(__x("About {name}", name => $name));
	$dialog->set_program_name($self->conf->app_name);
	$dialog->set_logo($self->get_icon);
	$dialog->set_version($Xacobeo::VERSION);

	$dialog->set_authors('Emmanuel Rodriguez <potyl@cpan.org>');
	$dialog->set_copyright("Copyright (C) 2008-2009 by Emmanuel Rodriguez.");
	$dialog->set_translator_credits(join "\n",
		'Emmanuel Rodriguez <potyl@cpan.org>',
		'Lars Dieckow <daxim@cpan.org>',
	);

	$dialog->set_website('http://code.google.com/p/xacobeo/');
	$dialog->set_website_label($name);

	$dialog->set_comments(__("Simple XPath viewer"));
	$dialog->signal_connect(response => sub {
		my ($dialog, $response) = @_;
		$dialog->destroy();
	});
	$dialog->show();
}


sub _create_ui_manager {
	my $self = shift;

	# This entries are always active
	my $active_entries = [
		# Top level
		[ 'FileMenu',  undef, __("_File") ],
		[ 'HelpMenu',  undef, __("_Help") ],


		# Entries (name, stock id, label, accelerator, tooltip, callback)
		[
			'FileOpen',
			'gtk-open',
			__("_Open"),
			'<control>O',
			__("Open a file"),
			sub { $self->do_show_file_open_dialog(@_) }
		],
		[
			'FileQuit',
			'gtk-quit',
			__("_Quit"),
			"<control>Q",
			__("Quit"),
			sub { $self->do_quit() }
		],


		[
			'HelpAbout',
			'gtk-about',
			__("_About"),
			undef,
			__("About"),
			sub { $self->do_show_about_dialog(@_) }
		],
	];


	my $ui_manager = Gtk2::UIManager->new();
	my $ui_string = <<'__XML__';
<ui>
	<menubar name='MenuBar'>

		<menu action='FileMenu'>
			<menuitem action='FileOpen'/>
			<placeholder name="FilePlaceholder_1"/>

			<separator/>

			<placeholder name="FilePlaceholder_2"/>
			<menuitem action='FileQuit'/>
		</menu>


		<placeholder name="ExtraMenu"/>


		<menu action='HelpMenu'>
			<menuitem action='HelpAbout'/>
		</menu>

	</menubar>
</ui>
__XML__
	$ui_manager->add_ui_from_string($ui_string);

	my $actions = Gtk2::ActionGroup->new("Actions");
	$actions->add_actions($active_entries, undef);

	$ui_manager->insert_action_group($actions, 0);
	$self->add_accel_group($ui_manager->get_accel_group);

	return $ui_manager;
}


sub _create_search_bar {
	my $self = shift;
	my $hbox = Gtk2::HBox->new();
	
	my $label = Gtk2::Label->new(__("XPath:"));
	$hbox->pack_start($label, FALSE, TRUE, 0);
	
	my $entry = Xacobeo::UI::XPathEntry->new();
	$self->xpath_entry($entry);
	my $markup = sprintf '<span color="grey" size="smaller">%s</span>',
		escape_xml_text(__("XPath Expression..."))
	;
	$entry->set_empty_markup($markup);
	$hbox->pack_start($entry, TRUE, TRUE, 0);
	
	my $button = Gtk2::Button->new(__("Evaluate"));
	$self->evaluate_button($button);
	$button->set_sensitive(FALSE);
	$hbox->pack_start($button, FALSE, TRUE, 0);
	
	return $hbox;
}


sub _create_main_content {
	my $self = shift;

	my $hpaned = Gtk2::HPaned->new();

	# Left part - Tree view
	my $dom_view = Xacobeo::UI::DomView->new();
	$self->dom_view($dom_view);
	$hpaned->pack1(scrollify($dom_view, 200), FALSE, TRUE);


	# Rigth part - VPaned [Source view | Notebook(Results, Namespaces)]
	my $vpaned = Gtk2::VPaned->new();
	$hpaned->pack2($vpaned, TRUE, TRUE);

	my $source_view = Xacobeo::UI::SourceView->new();
	$self->source_view($source_view);
	$source_view->set_show_line_numbers(TRUE);
	$source_view->set_highlight_current_line(TRUE);
	$vpaned->pack1(scrollify($source_view, -1, 400), FALSE, TRUE);
	
	
	# Notebook with the results view and the namespaces view
	my $notebook = Gtk2::Notebook->new();
	$self->notebook($notebook);
	$vpaned->pack2($notebook, TRUE, TRUE);

	my $results_view = Xacobeo::UI::SourceView->new();
	$self->results_view($results_view);
	$notebook->append_page(
		scrollify($results_view),
		Gtk2::Label->new(__("Results"))
	);
	
	my $namespaces_view = Gtk2::SimpleList->new(
		__('Prefix') => 'text',
		__('URI')    => 'text',
	);
	$self->namespaces_view($namespaces_view);
	$notebook->append_page(
		scrollify($namespaces_view),
		Gtk2::Label->new(__("Namespaces"))
	);
	
	return $hpaned;
}


# A true value
1;


=head1 AUTHORS

Emmanuel Rodriguez E<lt>potyl@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008,2009 by Emmanuel Rodriguez.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
