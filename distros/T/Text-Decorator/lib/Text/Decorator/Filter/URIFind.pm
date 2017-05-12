package Text::Decorator::Filter::URIFind;

use strict;

use base 'Text::Decorator::Filter';

use Carp;
use Text::Decorator::Group;
use Text::Decorator::Node;

=head1 NAME

Text::Decorator::Filter::URIFind - Turn URLs into links

=head1 DESCRIPTION

=head2 filter_node 

This filter uses the L<URI::Find> module to mark up URLs as links. 
You can also pass a classname as an argument to this filter, if you
prefer using C<URI::Find::Schemeless> or whatever.

=cut

sub filter_node {
	my ($class, $args, $node) = @_;

	my $urifind = shift(@$args) || "URI::Find";
	$urifind->require or croak "Couldn't load $urifind";

	my $uriRe = sprintf '(?:%s|%s)', $urifind->uri_re,
		$urifind->schemeless_uri_re;

	my $orig = $node->format_as("html");
	return $node unless $orig =~ /$uriRe/;

	my $group = Text::Decorator::Group->new();
	$group->{representations}{text}{pre}  = $node->format_as("text");
	$group->{representations}{html}{pre}  = "";
	$group->{representations}{text}{post} = "";
	$urifind                              = $urifind->new(sub {});
	while ($orig =~ s{(.*?)(<$uriRe>|$uriRe)}{}sm) {
		my $orig_match = $urifind->decruft($2);
		$class->_add_text_node($group, $1 . $urifind->{start_cruft});
		if (my $uri = $urifind->_is_uri(\$orig_match)) {    # Its a URI.
			$class->_add_uri_group($group, $uri, $orig_match);
		} else {                                            # False alarm.
			$class->_add_text_node($group, $orig_match);
		}
		$class->_add_text_node($group, $urifind->{end_cruft})
			if $urifind->{end_cruft};
	}
	$class->_add_text_node($group, $orig);

	return $group;
}

sub _add_text_node {
	my ($class, $group, $text) = @_;
	my $node = Text::Decorator::Node->new("");

	# Text representation is provided by group
	$node->{representations}{html} = $text;
	push @{ $group->{nodes} }, $node;
}

sub _add_uri_group {
	my ($class, $group, $uri, $text) = @_;
	my $node = Text::Decorator::Node->new("");
	$node->{representations}{html} = $text;

	my $subgroup = Text::Decorator::Group->new($node);
	$subgroup->{representations}{html}{pre}  = "<a href=\"$uri\">";
	$subgroup->{representations}{html}{post} = "</a>";
	push @{ $group->{nodes} }, $subgroup;
}

1;
