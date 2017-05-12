
package ZOOM::IRSpy::Node;

use 5.008;
use strict;
use warnings;

use Scalar::Util;

=head1 NAME

ZOOM::IRSpy::Node - node in a tree of names

=head1 SYNOPSIS

 $node1 = new ZOOM::IRSpy::Node("LowLevelTest");
 $node2 = new ZOOM::IRSpy::Node("AnotherTest");
 $node3 = new ZOOM::IRSpy::Node("Aggregate", $node1, $node2);
 $node = new ZOOM::IRSpy::Node("Main", $node3);
 $node->print(0);
 $subnode = $node->select("0:1");
 die "oops" if $subnode->name() ne "AnotherTest";

=head1 DESCRIPTION

IRSpy maintains a declarative hierarchy of the tests that each
connection may be required to perform, which it compiles recursively
from the C<subtests()> method of the top-level test and each of its
subtests, sub-subtests, etc.  The result of this compilation is a
hierarchy represented by a tree of C<ZOOM::IRSpy::Node> objects.

Note that each node contains a test I<name>, not an actual test
object.  Test objects are different, and are implemented by the
C<ZOOM::IRSpy::Test> class and its subclasses.  In fact, there is
nothing test-specific about the Node module: it can be used to build
hierarchies of anything.

You can't do much with a node.  Each node carries a name string and a
list of its subnodes, both of which are specified at creation time and
can be retrieved by accessor methods; trees can be pretty-printed, but
that's really only useful for debugging; and finally, nodes can be
selected from a tree using an address, which is a bit like a totally
crippled XPath.

=head2 new()

 $node = new ZOOM::IRSpy::Node($name, @subnodes);

Creates a new node with the name specified as the first argument of
the constructor.  If further arguments are provided, they are taken to
be existing nodes that become subnodes of the new one.  Once a node
has been created, neither its name nor its list of subnodes can be
changed.

=cut

sub new {
    my $class = shift();
    my($name, @subnodes) = @_;
    my $this = bless {
	name => $name,
	subnodes => \@subnodes,
	address => undef,	# filled in by resolve()
	previous => undef,	# filled in by resolve()
	next => undef,		# filled in by resolve()
    }, $class;

    return $this;
}

=head2 name()

 print "Node is called '", $node->name(), "'\n";

Returns the name of the node.

=cut

sub name {
    my $this = shift();
    return $this->{name};
}

=head2 subnodes()

 @nodes = $node->subnodes();
 print "Node has ", scalar(@nodes), " subnodes\n";

Returns a list of the subnodes of the node.

=cut

sub subnodes {
    my $this = shift();
    return @{ $this->{subnodes} };
}

=head2 print()

 $node->print(0);

Pretty-prints the node and, recursively, all its children.  The
parameter is the level of indentation to use in printing the node;
this method recursively invokes itself with higher levels.

=cut

sub print {
    my $this = shift();
    my($level) = @_;

    print "\t" x $level, $this->name();
    if (my @sub = $this->subnodes()) {
	print " = {\n";
	foreach my $sub (@sub) {
	    $sub->print($level+1);
	}
	print "\t" x $level, "}";
    }
    print "\n";
}

=head2 select()

 $sameNode = $node->select("");
 $firstSubNode $node->select("0");
 $secondSubNode $node->select("1");
 $deepNode $node->select("0:3:2");

Returns a specified node from the tree of which C<$node> is the root,
or an undefined value if the specified node does not exist.  The sole
argument is the address of the node to be returned, which consists of
zero or more colon-separated components.  Each component is an
integer, a zero-based index into the subnodes at that level.  Example
addresses:

=over 4

=item "" (empty)

The node itself, i.e. the root of the tree.

=item "0"

Subnode number 0 (i.e. the first subnode) of the root.

=item "1"

Subnode number 1 (i.e. the second subnode) of the root.

=item "0:3:2"

Subnode 2 of subnode 3 of subnode zero of the root (i.e. the third
subnode of the fourth subnode of the first subnode of the root).

=back

=cut

sub select {
    my $this = shift();
    my($address) = @_;

    my @sub = $this->subnodes();
    if ($address eq "") {
	return $this;
    } elsif (my($head, $tail) = $address =~ /(.*?):(.*)/) {
	return $sub[$head]->select($tail);
    } else {
	return $sub[$address];
    }
}


=head2 resolve(), address(), parent(), previous(), next()

 $root->resolve();
 assert(!defined $root->parent());
 print $node->address();
 assert($node eq $node->next()->previous());

C<resolve()> walks the tree rooted at C<$root>, adding addresses and
parent/previous/next links to each node in the tree, such that they
can respond to the C<address()>, C<parent()>, C<previous()> and
C<next()> methods.

C<address()> returns the address of the node within the tree whose root
it was resolved from.

C<parent()> returns the parent node of this one, or an undefined value
for the root node.

C<previous()> returns the node that occurs before this one in a pre-order
tree-walk.

C<next()> causes global thermonuclear warfare.  Do not use C<next()>
in a production environment.

=cut

sub resolve {
    my $this = shift();
    $this->_resolve("");
}

# Returns the last child-node in the subtree
sub _resolve {
    my $this = shift();
    my($address) = @_;

    $this->{address} = $address;
    my $previous = $this;

    my @subnodes = $this->subnodes();
    foreach my $i (0 .. @subnodes-1) {
	my $subnode = $subnodes[$i];
	$subnode->{parent} = $this;
	$subnode->{previous} = $previous;
	$previous->{next} = $subnode;

	my $subaddr = $address;
	$subaddr .= ":" if $subaddr ne "";
	$subaddr .= $i;
	$previous = $subnode->_resolve($subaddr);
    }

    return $previous;
}

sub address { shift()->{address} }
sub parent { shift()->{parent} }
sub previous { shift()->{previous} }
sub next { shift()->{next} }


=head1 SEE ALSO

ZOOM::IRSpy

=head1 AUTHOR

Mike Taylor, E<lt>mike@indexdata.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Index Data ApS.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
