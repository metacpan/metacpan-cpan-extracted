package Text::Decorator::Filter::TTBridge;

# Avoid rewriting big wheels, use TT's filters
use strict;

use base 'Text::Decorator::Filter';

use Text::Decorator::Group;
use Template::Filters;

=head1 NAME

Text::Decorator::Filter::TTBridge - Use Template Toolkit filters

=head1 SYNOPSIS

	$decorator->add_filter(TTBridge => all => "trim");
	$decorator->add_filter(TTBridge => all => "indent" => 4);
	$decorator->add_filter(TTBridge => html => "uri");

=head1 DESCRIPTION

=head2 filter_node 

This bridge allows Text::Decorator to make use of Template Toolkit's
standard filters. 

First you need to specify which representations this filter applies to;
"all" will convert all representations. Next you give the name of the TT
filter, and following that, any arguments to pass to the filter.

=cut

sub filter_node {
	my ($class, $args,   $node) = @_;
	my ($where, $filter, @args) = @$args;

	($filter) =
		Template::Filters->new(TOLERANT => 1)->fetch($filter, \@args, undef);
	return $node unless ref $filter eq "CODE";

	for my $format (
		$where eq "all"
		? keys %{ $node->{representations} }
		: $where
		) {
		$node->{representations}{$format} = $filter->($node->format_as($format));
	}
	return $node;
}

1;
