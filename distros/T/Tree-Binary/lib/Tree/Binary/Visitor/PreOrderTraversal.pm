
package Tree::Binary::Visitor::PreOrderTraversal;

use strict;
use warnings;

use Scalar::Util qw(blessed);

use Tree::Binary::Visitor::Base;

our $VERSION = '1.08';

our @ISA = qw(Tree::Binary::Visitor::Base);

# visit routine
sub visit {
	my ($self, $tree) = @_;
	(blessed($tree) && $tree->isa("Tree::Binary"))
		|| die "Insufficient Arguments : You must supply a valid Tree::Binary object";
    # get all things set up
	my @results;
	my $func;
    if ($self->{_filter_function}) {
        $func = sub { push @results => $self->{_filter_function}->(@_) };
    }
    else {
        $func = sub { push @results => $_[0]->getNodeValue() };
    }
	# then recursively to all its children
	# if the object is configured that way
	$tree->traverse($func);
    # now store the results we got
    $self->setResults(@results);
}


1;

__END__

=head1 NAME

Tree::Binary::Visitor::PreOrderTraversal - Visitor object for Tree::Binary objects

=head1 SYNOPSIS

For a complete example, see also L<Tree::Binary/SYNOPSIS>.

  use Tree::Binary;
  use Tree::Binary::Visitor::PreOrderTraversal;

  # create a visitor instance
  my $visitor = Tree::Binary::Visitor::PreOrderTraversal->new();

  # create a tree to visit
  # this is an expression tree
  # representing ((2 + 2) * (4 + 5))
  my $btree = Tree::Binary->new("*")
                    ->setLeft(Tree::Binary->new("+")
                                ->setLeft(Tree::Binary->new("2"))
                                ->setRight(Tree::Binary->new("2")))
                    ->setRight(Tree::Binary->new("+")
                                ->setLeft(Tree::Binary->new("4"))
                                ->setRight(Tree::Binary->new("5")));

  # by default this will collect all the
  # node values in depth-first order into
  # our results
  $tree->accept($visitor);

  # get our results and print them
  print join ", ", $visitor->getResults();  # prints "*, +, 2, 2, + 4, 5"

  # for more complex node objects, you can specify
  # a node filter which will be used to extract the
  # information desired from each node
  $visitor->setNodeFilter(sub {
                my ($t) = @_;
                return $t->getNodeValue()->description();
                });

=head1 DESCRIPTION

For the most part, this class is just a wrapper around the B<Tree::Binary> C<traverse> method.

=head1 METHODS

=over 4

=item B<new>

There are no arguments to the constructor the object will be in its default state. You can use the C<setNodeFilter> method to customize its behavior.

=item B<getNodeFilter>

This method returns the CODE reference set with C<setNodeFilter> argument.

=item B<clearNodeFilter>

This method clears node filter field.

=item B<setNodeFilter ($filter_function)>

This method accepts a CODE reference as its C<$filter_function> argument. This code reference is used to filter the tree nodes as they are collected. This can be used to customize output, or to gather specific information from a more complex tree node. The filter function should accept a single argument, which is the current Tree::Binary object.

=item B<getResults>

This method returns the accumulated results of the application of the node filter to the tree.

=item B<setResults>

This method should not really be used outside of this class, as it just would not make any sense to. It is included in this class and in this documenation to facilitate subclassing of this class for your own needs. If you desire to clear the results, then you can simply call C<setResults> with no argument.

=item B<visit ($tree)>

The C<visit> method accepts a Tree::Binary and applies the function set in C<new> or C<setNodeFilter> appropriately. The results of this application can be retrieved with C<getResults>

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it.

=head1 CODE COVERAGE

See the CODE COVERAGE section of Tree::Binary for details.

=head1 Repository

L<https://github.com/ronsavage/Tree-Binary>

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut