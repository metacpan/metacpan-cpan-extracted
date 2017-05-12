package Xacobeo::UI::SourceView;

=head1 NAME

Xacobeo::UI::SourceView - Text editor that displays XML.

=head1 SYNOPSIS

	use Xacobeo::Document;
	use Xacobeo::UI::SourceView;
	
	my $view = Xacobeo::UI::SourceView->new();
	$view->set_show_line_numbers(TRUE);
	$window->add($view);
	
	# Load a document
	my $document = Xacobeo::Document->new_from_file($file, $type);
	$view->set_document($document);
	$view->load_node($document->documentNode);

=head1 DESCRIPTION

The text editor widget that's used for displaying XML. This widget is a
L<Gtk2::SourceView2::View>.

=head1 PROPERTIES

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
use Gtk2::Pango qw(PANGO_WEIGHT_LIGHT PANGO_WEIGHT_BOLD);
use Gtk2::SourceView2;

use Xacobeo::Utils qw(
	isa_dom_nodelist
	isa_dom_boolean
	isa_dom_number
	isa_dom_literal
	isa_dom_namespace
	escape_xml_attribute
);
use Xacobeo::XS;
use Xacobeo::I18n;
use Xacobeo::Document;
use Xacobeo::GObject;


Xacobeo::GObject->register_package('Gtk2::SourceView2::View' =>
	properties => [
		Glib::ParamSpec->object(
			'document',
			"Document",
			"The main document being displayed.",
			'Xacobeo::Document',
			['readable', 'writable'],
		),

		# FIXME this property is redundant as we can use $self->document->namespaces
		Glib::ParamSpec->scalar(
			'namespaces',
			"Namespaces",
			"The namespaces in the main document.",
			['readable', 'writable'],
		),
	],
);


# The tag table shared by all editors
my $TAG_TABLE = _create_tag_table(Gtk2::TextTagTable->new());


sub INIT_INSTANCE {
	my $self = shift;
	my $buffer = _create_buffer();
	$self->set_buffer($buffer);
	$self->set_editable(FALSE);
}


=head2 set_document

Sets a new document. This method only registers the document with the view, to
display the document use the method load_node and pass the root node.

Parameters:

=over

=item * $document

The main document; an instance of L<Xacobeo::Document>.

=back

=cut

sub set_document {
	my $self = shift;
	my ($document) = @_;

	$self->document($document);
	$self->namespaces(
		$self->document ? $self->document->namespaces : undef
	);
	$self->clear();
}


=head2 show_node

Scrolls the text so that the given node is displayed.

Parameters:

=over

=item * $node

The node to show; an instance of L<XML::LibXML::Node>.

=back

=cut

sub show_node {
	my $self = shift;
	my ($node) = @_;

	my $mark_name = Xacobeo::XS::->get_node_mark($node);
	my $buffer = $self->get_buffer;

	# Clear any previous selection
	if (my $marks = delete $self->{selected}) {
		my @iters = map { $buffer->get_iter_at_mark($_) } @{ $marks };
		$buffer->remove_tag_by_name('selected', @iters);
	}

	# Scroll to the right place in the source view
	my $mark_start = $buffer->get_mark("$mark_name|start");
	if ($mark_start) {
		my $iter_start = $buffer->get_iter_at_mark($mark_start);
		$buffer->place_cursor($iter_start);

		my $mark_end = $buffer->get_mark("$mark_name|end");
		my $iter_end = $buffer->get_iter_at_mark($mark_end);

		$buffer->apply_tag_by_name('selected', $iter_start, $iter_end);
		$self->scroll_to_mark($mark_start, 0.25, FALSE, 0.0, 0.5);

		$self->{selected} = [$mark_start, $mark_end];
	}
	else {
		print "Got no mark at $mark_name!\n";
	}
}


=head2 load_node

Sets the editor's text according to the text representation of the given node.
This is the method that will actually add text to the widget.

Parameters:

=over

=item * $node

The node to be loaded into the editor; an instance of L<XML::LibXML::Node>.

=back

=cut

sub load_node {
	my $self = shift;
	my ($node) = @_;

	# It's faster to disconnect the buffer from the view and to reconnect it back
	my $buffer = $self->get_buffer;
	$self->set_buffer(Gtk2::SourceView2::Buffer->new(undef));
	$buffer->delete($buffer->get_start_iter, $buffer->get_end_iter);


	# A NodeList
	if (! defined $node) {
		_buffer_add($buffer, error => __("Node is undef"));
	}
	elsif ($node->isa('Xacobeo::Error')) {
		_buffer_add($buffer, error => $node->message);
	}
	elsif (isa_dom_nodelist($node)) {
		my @children = $node->get_nodelist;
		my $count = scalar @children;

		# Formatting using to indicate which result is being displayed
		my $i = 0;
		my $format = sprintf ' %%%dd. ', length $count;

		foreach my $child (@children) {
			# Add the result count
			my $result = sprintf $format, ++$i;
			_buffer_add($buffer, result_count => $result);

			if (isa_dom_namespace($child)) {
				# The namespaces nodes are an invention of XML::LibXML and they don't
				# work with the XS code, we deal with them manually.
				_buffer_add($buffer, syntax => ' ');
				_buffer_add($buffer, namespace_name => $child->nodeName);
				_buffer_add($buffer, syntax => '="');

				my $uri = escape_xml_attribute($child->getData);
				_buffer_add($buffer, namespace_uri => $uri);

				_buffer_add($buffer, syntax => '"');
			}
			else {
				Xacobeo::XS->load_text_buffer($buffer, $child, $self->namespaces);
			}

			_buffer_add($buffer, syntax => "\n") if --$count;
		}
	}

	# A Boolean value ex: true() or false()
	elsif (isa_dom_boolean($node)) {
		_buffer_add($buffer, boolean => $node->to_literal);
	}

	# A Number ex: 2 + 5
	elsif (isa_dom_number($node)) {
		_buffer_add($buffer, number => $node->to_literal);
	}

	# A Literal (a single text string) ex: "hello"
	elsif (isa_dom_literal($node)) {
		_buffer_add($buffer, literal => $node->to_literal);
	}

	else {
		# Any kind of XML node
		Xacobeo::XS->load_text_buffer($buffer, $node, $self->namespaces);
	}


	# Add the buffer back into into the text view
	$self->set_buffer($buffer);

	# Scroll to the beginning
	$self->scroll_to_iter($buffer->get_start_iter, 0.0, FALSE, 0.0, 0.0);
}


sub clear {
	my $self = shift;
	$self->get_buffer->set_text('');
}


#
# Adds the given text at the end of the buffer. The text is added with a tag
# which can be used for performing syntax highlighting.
#
sub _buffer_add {
	my ($buffer, $tag, $string) = @_;
	$buffer->insert_with_tags_by_name($buffer->get_end_iter, $string, $tag);
	return;
}


sub _create_buffer {
	my $buffer = Gtk2::SourceView2::Buffer->new($TAG_TABLE);
	$buffer->set_highlight_syntax(undef);

	# This will disable the undo/redo forever
	$buffer->begin_not_undoable_action();
	
	return $buffer;
}


#
# Creates the text tag table shared by all source views.
#
sub _create_tag_table {
	my $tag_table = Gtk2::TextTagTable->new();

	_add_tag($tag_table, result_count =>
		family     => 'Courier 10 Pitch',
		background => '#EDE9E3',
		foreground => 'black',
		style      => 'italic',
		weight     => PANGO_WEIGHT_LIGHT
	);

	# Make the boolean and number look a like
	foreach my $name (qw(boolean number)) {
		_add_tag($tag_table, $name =>
			family     => 'Courier 10 Pitch',
			foreground => 'black',
			weight     => PANGO_WEIGHT_BOLD
		);
	}

	_add_tag($tag_table, attribute_name =>
		foreground => 'red',
	);

	_add_tag($tag_table, attribute_value =>
		foreground => 'blue',
	);

	_add_tag($tag_table, comment =>
		foreground => '#008000',
		style      => 'italic',
		weight     => PANGO_WEIGHT_LIGHT,
	);

	_add_tag($tag_table, dtd =>
		foreground => '#558CBA',
		style      => 'italic',
	);

	_add_tag($tag_table, element =>
		foreground => '#800080',
		weight     => PANGO_WEIGHT_BOLD,
	);

	_add_tag($tag_table, pi =>
		foreground => '#558CBA',
		style      => 'italic',
	);

	_add_tag($tag_table, pi_data =>
		foreground => 'red',
		style      => 'italic',
	);

	_add_tag($tag_table, syntax =>
		foreground => 'black',
		weight     => PANGO_WEIGHT_BOLD,
	);

	_add_tag($tag_table, literal =>
		foreground => 'black',
	);

	_add_tag($tag_table, cdata =>
		foreground => 'red',
		weight     => PANGO_WEIGHT_BOLD
	);

	_add_tag($tag_table, cdata_content =>
		foreground => 'purple',
		weight     => PANGO_WEIGHT_LIGHT,
		style      => 'italic',
	);

	_add_tag($tag_table, namespace_name =>
		foreground => 'red',
		style      => 'italic',
		weight     => PANGO_WEIGHT_LIGHT,
	);

	_add_tag($tag_table, namespace_uri =>
		foreground => 'blue',
		style      => 'italic',
		weight     => PANGO_WEIGHT_LIGHT,
	);

	_add_tag($tag_table, entity_ref =>
		foreground => 'red',
		style      => 'italic',
		weight     => PANGO_WEIGHT_BOLD,
	);

	_add_tag($tag_table, error =>
		foreground => 'red',
	);

	_add_tag($tag_table, selected =>
		background => 'yellow',
	);

	return $tag_table;
}


#
# Creates a text tag (Gtk2::TextTag) with the given name and properties and adds
# it to the given tag table.
#
sub _add_tag {
	my ($tag_table, $name, @properties) = @_;
	my $tag = Gtk2::TextTag->new($name);
	$tag->set(@properties);
	$tag_table->add($tag);
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

