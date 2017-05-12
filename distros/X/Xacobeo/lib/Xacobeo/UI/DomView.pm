package Xacobeo::UI::DomView;

=head1 NAME

Xacobeo::UI::DomView - DOM tree view

=head1 SYNOPSIS

	use Xacobeo::DomView;
	use Xacobeo::UI::SourceView;
	
	my $view = Xacobeo::UI::SourceView->new();
	$window->add($view);
	
	# Load a document
	my $document = Xacobeo::Document->new_from_file($file, $type);
	$view->set_document($document);
	$view->load_node($document->documentNode);

=head1 DESCRIPTION

The application's main window. This widget is a L<Gtk2::TreeView>.

=head1 PROPERTIES

The following properties are defined:

=head2 ui-manager

The UI Manager used by this widget.

=head2 action-group

The action group that provides the values in the context menu.

=head2 menu

The context menu of the widget.

=head2 document

The document being displayed.

=head2 namespaces

The namespaces registered in the document.

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
use Xacobeo::I18n;
use Xacobeo::XS;
use Xacobeo::Document;

use Xacobeo::GObject;

Xacobeo::GObject->register_package('Gtk2::TreeView' =>
	properties => [
		Glib::ParamSpec->object(
			'ui-manager',
			"UI Manager",
			"The UI Manager that provides the UI",
			'Gtk2::UIManager',
			['readable', 'writable'],
		),

		Glib::ParamSpec->object(
			'action-group',
			"Action Group",
			"The action group with context menu entries",
			'Gtk2::ActionGroup',
			['readable', 'writable'],
		),

		Glib::ParamSpec->object(
			'menu',
			"Context Menu",
			"The context menu for the tree items",
			'Gtk2::ActionGroup',
			['readable', 'writable'],
		),

		Glib::ParamSpec->object(
			'document',
			"Document",
			"The main document being displayed",
			'Xacobeo::Document',
			['readable', 'writable'],
		),

		# FIXME this property is redundant as we can use $self->document->namespaces
		Glib::ParamSpec->scalar(
			'namespaces',
			"Namespaces",
			"The namespaces in the main document",
			['readable', 'writable'],
		),
	],

	signals => {
		'node-selected' => {
			flags       => ['run-last'],
			# Parameters:   Node 
			param_types => ['Glib::Scalar'],
		},
	},
);


my $NODE_POS = 0;
my $NODE_DATA     = $NODE_POS++;
my $NODE_ICON     = $NODE_POS++;
my $NODE_NAME     = $NODE_POS++;
my $NODE_ID_NAME  = $NODE_POS++;
my $NODE_ID_VALUE = $NODE_POS++;


sub INIT_INSTANCE {
	my $self = shift;

	my $model = Gtk2::TreeStore->new(
		'Glib::Scalar', # A reference to the XML::LibXML::Node
		'Glib::String', # The icon to use (ex: 'gtk-directory')
		'Glib::String', # The name of the Element
		'Glib::String', # The name of the ID field
		'Glib::String', # The value of the ID field
	);
	$self->set_model($model);
	$self->set_fixed_height_mode(TRUE);

	my $column = $self->_add_text_column($NODE_NAME, __('Element'), 150);

	# Icon
	my $node_icon = Gtk2::CellRendererPixbuf->new();
	$column->pack_start($node_icon, FALSE);
	$column->set_attributes($node_icon, 'stock-id' => $NODE_ICON);

	# Node attribute name (ID attribute)
	$self->_add_text_column($NODE_ID_NAME, __('ID name'), 75);

	# Node attribute value (ID attribute)
	$self->_add_text_column($NODE_ID_VALUE, __('ID value'), 75);
	

	my $ui_manager = $self->_build_ui_manager();
	$self->ui_manager($ui_manager);

	my $menu = $ui_manager->get_widget('/DomViewPopup');
	$self->menu($menu);

	$self->signal_connect('row-activated' => \&callback_row_activated);
	$self->signal_connect('popup-menu' => \&callback_popup_menu);
	$self->signal_connect('button-press-event' => \&callback_button_press_event);
}


sub _build_ui_manager {
	my $self = shift;

	my $entries = [
		# Entries (name, stock id, label, accelerator, tooltip, callback)
		[
			'DomViewSelectNode',
			'gtk-jump-to',
			__("_Jump to"),
			undef,
			__("Show the node"),
			sub { $self->do_select_node() }
		],
		[
			'DomViewCopyXPath',
			'gtk-copy',
			__("_Copy XPath"),
			undef,
			__("Copy the node's XPath"),
			sub { $self->do_copy_xpath() }
		],
	];

	my $actions = Gtk2::ActionGroup->new("DomViewActions");
	$self->action_group($actions);
	$actions->add_actions($entries, undef);
	$actions->set_sensitive(FALSE);

	my $ui_manager = Gtk2::UIManager->new();
	$self->ui_manager($ui_manager);

	my $ui_string = <<'__XML__';
<ui>
	<popup name="DomViewPopup">
		<menuitem action='DomViewSelectNode'/>
		<placeholder name="DomViewPlaceholder_1"/>
		<separator/>
		<menuitem action='DomViewCopyXPath'/>
		<placeholder name="DomViewPlaceholder_2"/>
	</popup>
</ui>
__XML__
	$ui_manager->add_ui_from_string($ui_string);

	$ui_manager->insert_action_group($actions, 0);
	return $ui_manager;
}


#
# Transform the signal 'row-activated' into 'node-selected'.
#
sub callback_row_activated {
	my ($self, $path) = @_;

	my $model = $self->get_model;
	my $iter = $model->get_iter($path);
	my $node = $model->get($iter, $NODE_DATA);
	$self->signal_emit('node-selected' => $node);
}


sub do_copy_xpath {
	my $self = shift;

	my $node = $self->get_selected_node or return;
	my $xpath = Xacobeo::XS->get_node_path($node, $self->namespaces);

	foreach my $selection (qw(SELECTION_CLIPBOARD SELECTION_PRIMARY)) {
		my $clipboard = Gtk2::Clipboard->get(Gtk2::Gdk->$selection);
		$clipboard->set_text($xpath);
	}
}


sub do_select_node {
	my $self = shift;

	my $node = $self->get_selected_node or return;
	$self->signal_emit('node-selected' => $node);
}


sub get_selected_node {
	my $self = shift;
	# Get the selected node and find its xpath
	my $selection = $self->get_selection;
	my ($model, $iter) = $selection->get_selected or return;
	my $node = $model->get($iter, $NODE_DATA);
	return $node;
}


#
# Display a context menu for a given node when right clicking.
#
sub callback_button_press_event {
	my ($self, $event) = @_;

	return FALSE unless $event->button == 3;

	my $path = $self->get_path_at_pos($event->x, $event->y) or return FALSE;

	my $selection = $self->get_selection;
	$selection->unselect_all();
	$selection->select_path($path);

	$self->action_group->set_sensitive(TRUE);

	$self->menu->popup(undef, undef, undef, undef, $event->button, $event->time);

	return TRUE;
}


#
# Display a context menu for a given node when right clicking.
#
sub callback_popup_menu {
	my ($self) = @_;
	$self->menu->popup(undef, undef, undef, undef, 0, 0);
	return TRUE;
}


sub set_document {
	my $self = shift;
	my ($document) = @_;

	$self->document($document);
	$self->namespaces(
		$self->document ? $self->document->namespaces : undef
	);
}


=head2 load_node

Sets the tree view nodes hierarchy based on the given node. This is the method
that will actually add items to the widget.

Parameters:

=over

=item * $node

The node to be loaded into the tree widget; an instance of L<XML::LibXML::Node>.

=back

=cut


sub load_node {
	my $self = shift;
	my ($node) = @_;

	my $store = $self->get_model;

	$self->set_model(undef);
	if (defined $node and defined $store) {
		Xacobeo::XS->load_tree_store($store, $node, $self->namespaces);
	}
	elsif (defined $store) {
		$store->clear();
	}
	$self->set_model($store);

	# Expand the first level
	if (my $iter = $store->get_iter_first) {
		my $path = $store->get_path($iter);
		$self->expand_row($path, FALSE);
	}
}


#
# Adds a text column to the tree view
#
sub _add_text_column {
	my $self = shift;
	my ($field, $title, $width) = @_;

	my $cell = Gtk2::CellRendererText->new();
	my $column = Gtk2::TreeViewColumn->new();
	$column->pack_end($cell, TRUE);

	$column->set_title($title);
	$column->set_resizable(TRUE);
	$column->set_sizing('fixed');
	$column->set_fixed_width($width);
	$column->set_attributes($cell, text => $field);

	$self->append_column($column);

	return $column;
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

