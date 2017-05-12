
package Tree::Visualize::GraphViz::Layouts::Binary::Tree;

use strict;
use warnings;

use Tree::Visualize::Exceptions;

our $VERSION = '0.01';

use base qw(Tree::Visualize::Layout::ILayout);

sub draw {
    my ($self, $binary_tree) = @_;
    (defined($binary_tree) && ref($binary_tree) && 
        (UNIVERSAL::isa($binary_tree, "Tree::Binary") || UNIVERSAL::isa($binary_tree, "Tree::Binary::Search"))) 
            || throw Tree::Visualize::IncorrectObjectType "argument must be Tree::Binary or Tree::Binary::Search instance"; 
    # if its a binary search tree, 
    # we need to extract the binary 
    # tree in it
    $binary_tree = $binary_tree->getTree() if $binary_tree->isa("Tree::Binary::Search");
    # call our private method here
    $self->_draw($binary_tree);
}

sub _draw {
    my ($self, $tree) = @_;
    my $output = "digraph test {\n";
    $tree->traverse(sub {
        my ($tree) = @_;   
        my $tree_id = $tree->getUID();
        my $parent_id = $tree->getParent()->getUID() unless $tree->isRoot();
        $output .= "node_$tree_id [ label = \"" . $tree->getNodeValue() . "\" ];\n";
        $output .= "node_${parent_id} -> node_${tree_id};\n" if $parent_id;
    });
    return $output . "}\n";
}

1;

__END__

=head1 NAME

Tree::Visualize::GraphViz::Layouts::Binary::Tree - 

=head1 SYNOPSIS

  use Tree::Visualize::GraphViz::Layouts::Binary::Tree;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<draw>

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

See the B<CODE COVERAGE> section in L<Tree::Visualize> for more inforamtion.

=head1 SEE ALSO

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

