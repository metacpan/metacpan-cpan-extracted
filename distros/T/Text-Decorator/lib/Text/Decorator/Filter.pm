package Text::Decorator::Filter;

use strict;
use warnings;

use Carp "confess";

=head1 NAME

Text::Decorator::Filter - Base class for text decorator filters

=head1 DESCRIPTION

This is the base class that all filters should inherit from. 

=head1 METHODS 

=head2 filter 

This base class provides the all-important C<filter> method that you
really don't want to implement yourself. Instead, you should provide
one of these methods:

=head2 filter_text

This should simply modify C<$_>. It's called once for each
representation, with the representation as the first parameter to the
method.

=head2 filter_node

This gets called as

	$class->filter_node($args, $node)

for every textual node, and is expected to return one or more modified
node objects.

There's also C<filter_group> which you may want to provide, which does
the same but for C<Group> objects.

=head2 filter_anynode

This is the same, but gets called for both Group and Node objects.

=cut

sub filter {
	my ($class, $args, @nodelist) = @_;
	my @newnodes;
	for my $node (@nodelist) {
		confess "Dead node in nodelist!" unless $node;
		if ($node->isa("Text::Decorator::Group")) {
			$node->{nodes} = [ $class->filter($args, $node->nodes) ];
		}
		push @newnodes, $class->_do_filter($args, $node);
	}
	return @newnodes;
}

sub _do_filter {
	my ($class, $args, $node) = @_;

	# We're prepared to do it all!
	return $class->filter_anynode($args, $node)
		if $class->can("filter_anynode");

	# Taking short-cuts
	if ($class->can("filter_text") and $node->isa("Text::Decorator::Node")) {
		for my $format (keys %{ $node->{representations} }) {
			local $_ = $node->{representations}->{$format};
			$class->filter_text($format);
			$node->{representations}->{$format} = $_;
		}
		return $node;
	}

	if ($class->can("filter_group") and $node->isa("Text::Decorator::Group")) {
		return $class->filter_group($args, $node);
	}

	if ($class->can("filter_node") and $node->isa("Text::Decorator::Node")) {
		return $class->filter_node($args, $node);
	}

	return $node;
}

1;
