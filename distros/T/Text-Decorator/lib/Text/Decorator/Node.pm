package Text::Decorator::Node;

use strict;
use warnings;

=head1 NAME

Text::Decorator::Node - A blob of text in a Text::Decorator decoration

=head1 SYNOPSIS

	my $node = Text::Decorator::Node->new($text);
	$node->format_as("html");

=head1 DESCRIPTION

This represents a piece of text which is going to undergo formatting
and decoration.

=head1 METHODS

=head2 new

	my $node = Text::Decorator::Node->new($text);

Creates a new Text::Decorator::Node instance with the specified text.

=cut

sub new {
	my ($class, $text) = @_;
	return bless {
		representations => { text => $text },
		notes           => {}     # So filters can pass messages to each other
	} => $class;
}

=head2 format_as

	$node->format_as($representation)

Returns this node in the specified representation, or plain text.

=cut

sub format_as {
	my ($self, $format) = @_;
	return $self->{representations}{$format}
		|| $self->{representations}{text};
}

1;

