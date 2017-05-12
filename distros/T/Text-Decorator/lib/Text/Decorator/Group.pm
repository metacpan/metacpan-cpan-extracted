package Text::Decorator::Group;

use strict;
use warnings;

use Carp;

=head1 NAME

Text::Decorator::Group - A (possibly nested) group of nodes

=head1 SYNOPSIS

	my $group = $self->new(@nodes);
	$self->format_as('html');
	$self->nodes

=head1 DESCRIPTION

A Group is a set of nodes that live together for some semantic reason -
paragraphs in a document, sentences in a paragraph, or whatever.

=head1 METHODS

=head2 new

	$self->new(@nodes);

Creates a new Text::Decorator::Group instance.

=cut

sub new {
	my $class = shift;
	return bless {
		nodes           => [@_],
		representations => {},
		notes           => {},     # What's this group all about, then?

	} => $class;
}

=head2 nodes

	@nodes = $self->nodes;

Returns the nodes which make up this group.

=cut

sub nodes { return @{ shift->{nodes} } }

=head2 format_as

	$self->format_as("html")

Descend into the group, formatting each node, stringing the pieces
together and returning the result, optionally adding some pre- and post-
representation-specific material.

=cut

sub format_as {
	my ($self, $format) = @_;
	my $gformat = $format;
	$gformat = "text" if not exists $self->{representations}{$format};
	no warnings;
	return $self->{representations}{$gformat}{pre}
		. join(
		$self->{representations}{$gformat}{inter},
		map $_->format_as($format),
		$self->nodes
		)
		. $self->{representations}{$gformat}{post};
}

1;

