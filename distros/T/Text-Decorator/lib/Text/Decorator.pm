package Text::Decorator;

use 5.006;

use strict;
use warnings;

use Carp;
use UNIVERSAL::require;

our $VERSION = '1.65';

=head1 NAME

Text::Decorator -  Apply a chain of filters to text

=head1 SYNOPSIS

	$self->new(...);
	$self->format_as(...);

=head1 DESCRIPTION

Text::Decorator is a framework for marking up plain text into various
formats by applying a chain of filters. For instance, you might apply
a filter which will cause URIs in text to be presented as links if the
text is exported as HTML.

=head1 METHODS

=head2 new

	$self->new($text)

Creates a new Text::Decorator instance.

=head2 nodeclass

The class we will use for our nodes. This defaults to
L<Text::Decorator::Node>, but if you want to subclass that to change
its behaviour, then you need to override this.

=cut

sub nodeclass { "Text::Decorator::Node" }

sub new {
	my ($class, $text) = @_;
	$class->nodeclass->require;
	return bless {
		nodes   => [ $class->nodeclass->new($text) ],
		filters => [],
	} => $class;
}

=head2 add_filter

	$self->add_filter("EscapeHTML" => @arguments);

This adds a new filter onto the queue of filters which will be applied
to this decorator; returns the decorator object.

=cut

sub add_filter {
	my ($self, $filter, @args) = @_;
	$filter = "Text::Decorator::Filter::$filter" unless $filter =~ /::/;
	$filter->require or croak "Can't use filter $filter";
	push @{ $self->{filters} }, { filter => $filter, args => [@args] };
	return $self;
}

=head2 format_as

	$self->format_as("html")

Apply all the filters and return the text in the specified
representation. If the representation is unknown, plain text will be
returned.

=cut

sub format_as {
	my ($self, $format) = @_;

	# Do the formatting stage; since we pull stuff off the stack, this
	# is only done once.
	while (my $filter = shift @{ $self->{filters} }) {
		my ($filterclass, $args) = @{$filter}{qw(filter args)};
		@{ $self->{nodes} } = $filterclass->filter($args, @{ $self->{nodes} });
	}
	return join "", map $_->format_as($format), @{ $self->{nodes} };
}

=head1 AUTHOR

Original author: Simon Cozens

Current maintainer: Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Text-Decorator@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

	Copyright (C) 2003-4 Simon Cozens, 2004-6 Tony Bowden 

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License; either version 2 of the License,
  or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

L<Text::Decorator::Filter>, L<Text::Decorator::Node>,
L<Text::Decorator::Group>

=cut

1;
