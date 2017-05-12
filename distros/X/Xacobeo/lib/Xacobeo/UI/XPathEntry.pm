package Xacobeo::UI::XPathEntry;

=head1 NAME

Xacobeo::UI::XPathEntry - XPath text entry

=head1 SYNOPSIS

	use Xacobeo::UI::XPathEntry;
	
	my $entry = Xacobeo::UI::XPathEntry->new();
	my $markup = sprintf '<span color="grey" size="smaller">%s</span>',
		escape_xml_text(__("XPath Expression..."))
	;
	$entry->set_empty_markup($markup);
	
	# Must set a document in order to find the namespaces that are allowed
	$entry->set_document($document);
	
	if ($entry->is_valid) {
		my $xpath = $entry->get_text
		my $node = $document->find($xpath);
		$result_view->load_node($node);
	}

=head1 DESCRIPTION

A text entry that validates XPath expressions. This widget is a
L<Gtk2::Ex::Entry::Pango>.

The widget validates the text in realtime. In order to support validation for
namespaces a document has to be set first.

=head1 PROPERTIES

The following properties are defined:

=head2 document

The document being displayed.

=head2 valid

Indicates if the XPath expression beind displayed is valid based on the current
document.

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
use Gtk2::Ex::Entry::Pango;

use Xacobeo::GObject;

Xacobeo::GObject->register_package('Gtk2::Ex::Entry::Pango' =>
	properties => [
		Glib::ParamSpec->object(
			'document',
			"Document",
			"The main document being displayed",
			'Xacobeo::Document',
			['readable', 'writable'],
		),

		Glib::ParamSpec->boolean(
			'valid',
			"Valid XPath",
			"Indicates if the XPath expression is valid",
			FALSE,
			['readable', 'writable'],
		),
	],

	# FIXME perhaps this signal should be removed and the caller shoud connect to notify::is-valid
	signals => {
		'xpath-changed' => {
			flags       => ['run-last'],
			# Parameters:   XPath expression,  isValid
			param_types => ['Glib::String',    'Glib::Boolean'],
		},
	},
);


sub INIT_INSTANCE {
	my $self = shift;

	$self->signal_connect('changed' => \&callback_changed);
	$self->set_sensitive(FALSE);
}


=head2 set_document

Sets a the widget's document. A document is needed in order to provide the
namespaces that allowed in the XPath expression.

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
	$self->set_sensitive($document ? TRUE : FALSE);
	# FIXME changing the document has to trigger a revalidation of the xpath expression
}


sub callback_changed {
	my ($self) = @_;

	my $xpath = $self->get_text;
	my $document = $self->document;

	my $is_valid = FALSE;
	if ($document && $xpath) {
		$is_valid = $document->validate($xpath);
		if (! $is_valid) {
			# Mark the XPath expression as wrong
			my $escaped = Glib::Markup::escape_text($xpath);
			my $markup = "<span underline='error' underline_color='red'>$escaped</span>";
			$self->set_markup($markup);
			$self->signal_stop_emission_by_name('changed');
		}
	}

	$self->valid($is_valid);
	$self->signal_emit('xpath-changed' => $xpath, $is_valid);
}


=head2 is_valid

Returns C<TRUE> if the current XPath expression is valid.

=cut

sub is_valid {
	my $self = shift;
	return $self->valid;
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

