package Text::Decorator::Filter::Quoted;

use strict;

use base 'Text::Decorator::Filter';

use Text::Decorator::Group;
use Text::Quoted;

=head1 NAME

Text::Decorator::Filter::Quoted - Mark up paragraphs of quoted text

=head1 SYNOPSIS

    $decorator->add_filter("Quoted", begin => '<div class="level%i">',
                                     end   => '</div>');

=head1 DESCRIPTION

=head2 filter_node 

This filter uses the L<Text::Quoted> module to add quoting-level style
tags on a HTML representation of piece of text. 

=cut

sub filter_node {
	my ($class, $args, $node) = @_;
	$args = { @{ $args || [] } };
	$args->{begin} ||= "<span class=\"quotedlevel%i\">";
	$args->{end}   ||= "</span>";

	# There's a slight bug here; this filter will obliterate all HTML
	# markup made so far, which is something this module was designed to
	# avoid! It shouldn't be that much of a deal, since most markup should
	# be in the group pre- and post- stuff, but this really needs
	# redesigned to preserve properties of existing nodes.
	my $structure = extract($node->format_as("text"));
	my @output;

	# Let's have a level one group
	my $group = $class->_new_group($args, 1);

	$group->{nodes} = [ $class->_traverse($args, $structure, 1) ];
	return $group, Text::Decorator::Node->new("\n")    # Swallowed somewhere
}

sub _traverse {
	my ($class, $args, $stuff, $level) = @_;
	my @output;
	for (@$stuff) {
		if (ref $_ eq "ARRAY") {

			# New group
			my $group = $class->_new_group($args, $level + 1);
			$group->{nodes} = [ $class->_traverse($args, $_, $level + 1) ];
			push @output, $group;
		} elsif (ref $_ eq "HASH") {
			push @output, Text::Decorator::Node->new($_->{raw} . "\n");
		}
	}
	return @output;
}

sub _new_group {
	my ($class, $args, $level) = @_;
	my $group = Text::Decorator::Group->new();
	$group->{notes}->{level} = $level;
	$group->{representations}{html}{pre}  = sprintf($args->{begin}, $level);
	$group->{representations}{html}{post} = sprintf($args->{end},   $level);
	return $group;
}

1;
