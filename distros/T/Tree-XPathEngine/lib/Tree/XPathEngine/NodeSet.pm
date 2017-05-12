# $Id: /tree-xpathengine/trunk/lib/Tree/XPathEngine/NodeSet.pm 17 2006-02-12T08:00:01.814064Z mrodrigu  $

package Tree::XPathEngine::NodeSet;
use strict;

use Tree::XPathEngine::Boolean;

use overload 
		'""' => \&xpath_to_literal,
    'bool' => \&xpath_to_boolean,
        ;

sub new {
	my $class = shift;
	bless [], $class;
}

sub sort {
    my $self = CORE::shift;
    @$self = CORE::sort { $a->xpath_cmp( $b) } @$self; 
    return $self;
}

sub remove_duplicates {
    my $self = CORE::shift;
		my @unique;
		my $last_node=0;
		foreach my $node (@$self) { 
				push @unique, $node unless( $node == $last_node);
				$last_node= $node;
		}
		@$self= @unique; 
		return $self;
}


sub pop {
	my $self = CORE::shift;
	CORE::pop @$self;
}

sub push {
	my $self = CORE::shift;
	my (@nodes) = @_;
	CORE::push @$self, @nodes;
}

sub append {
	my $self = CORE::shift;
	my ($nodeset) = @_;
	CORE::push @$self, $nodeset->get_nodelist;
}

sub shift {
	my $self = CORE::shift;
	CORE::shift @$self;
}

sub unshift {
	my $self = CORE::shift;
	my (@nodes) = @_;
	CORE::unshift @$self, @nodes;
}

sub prepend {
	my $self = CORE::shift;
	my ($nodeset) = @_;
	CORE::unshift @$self, $nodeset->get_nodelist;
}

sub size {
	my $self = CORE::shift;
	scalar @$self;
}

sub get_node { # uses array index starting at 1, not 0
	my $self = CORE::shift;
	my ($pos) = @_;
	$self->[$pos - 1];
}

sub xpath_get_root_node {
    my $self = CORE::shift;
    return $self->[0]->xpath_get_root_node;
}

sub get_nodelist {
	my $self = CORE::shift;
	@$self;
}

sub xpath_to_boolean {
	my $self = CORE::shift;
	return (@$self > 0) ? Tree::XPathEngine::Boolean->_true : Tree::XPathEngine::Boolean->_false;
}

sub xpath_string_value {
	my $self = CORE::shift;
	return '' unless @$self;
	return $self->[0]->xpath_string_value;
}

sub xpath_to_literal {
	my $self = CORE::shift;
	return Tree::XPathEngine::Literal->new(
			join('', map { $_->xpath_string_value } @$self)
			);
}

sub xpath_to_number {
	my $self = CORE::shift;
	return Tree::XPathEngine::Number->new(
			$self->xpath_to_literal
			);
}

1;
__END__

=head1 NAME

Tree::XPathEngine::NodeSet - a list of XML document nodes

=head1 DESCRIPTION

An Tree::XPathEngine::NodeSet object contains an ordered list of nodes. The nodes
each take the same format as described in L<Tree::XPathEngine::XMLParser>.

=head1 SYNOPSIS

	my $results = $xp->find('//someelement');
	if (!$results->isa('Tree::XPathEngine::NodeSet')) {
		print "Found $results\n";
		exit;
	}
	foreach my $context ($results->get_nodelist) {
		my $newresults = $xp->find('./other/element', $context);
		...
	}

=head1 API

=head2 new()

You will almost never have to create a new NodeSet object, as it is all
done for you by XPath.

=head2 get_nodelist()

Returns a list of nodes. See L<Tree::XPathEngine::XMLParser> for the format of
the nodes.

=head2 xpath_string_value()

Returns the string-value of the first node in the list.
See the XPath specification for what "string-value" means.

=head2 xpath_to_literal()

Returns the concatenation of all the string-values of all
the nodes in the list.

=head2 get_node($pos)

Returns the node at $pos. The node position in XPath is based at 1, not 0.

=head2 size()

Returns the number of nodes in the NodeSet.

=head2 pop()

Equivalent to perl's pop function.

=head2 push(@nodes)

Equivalent to perl's push function.

=head2 append($nodeset)

Given a nodeset, appends the list of nodes in $nodeset to the end of the
current list.

=head2 shift()

Equivalent to perl's shift function.

=head2 unshift(@nodes)

Equivalent to perl's unshift function.

=head2 prepend($nodeset)

Given a nodeset, prepends the list of nodes in $nodeset to the front of
the current list.

=head2 xpath_get_root_node

Returns the root node of the first node in the set

=head2 sort

Returns a sorted nodeset using the C<cmp> method on nodes

=head2 remove_duplicates

Returns a sorted nodeset of unique nodes. The input nodeset MUST be sorted

=head2 xpath_to_boolean

Returns true if the nodeset is not empty

=head2 xpath_to_number

Returns the concatenation of all the string-values of all
the nodes in the list as a Tree::XPathEngine::Number object;

=cut
