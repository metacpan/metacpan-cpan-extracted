
package Tree::Visualize::ASCII::Layouts::Binary;

use strict;
use warnings;

our $VERSION = '0.01';

use base qw(Tree::Visualize::Layout::ILayout);

use Tree::Visualize::Exceptions;
use Tree::Visualize::ASCII::BoundingBox;
use Tree::Visualize::Node::Factory;

sub checkTree {
    my ($self, $tree) = @_;
    (defined($tree) && ref($tree) && 
        (UNIVERSAL::isa($tree, "Tree::Binary") || UNIVERSAL::isa($tree, "Tree::Binary::Search"))) 
            || throw Tree::Visualize::IncorrectObjectType 
                        "binary tree argument must be a Tree::Binary or a Tree::Binary::Search object"; 
    return $tree->getTree() if $tree->isa("Tree::Binary::Search");    
    return $tree;        
}

sub drawNode {
    my ($self, $tree) = @_;
    my $node = Tree::Visualize::Node::Factory->new()->get(output => 'ASCII', node_type => 'PlainBox', args => [ $tree ]);
    return Tree::Visualize::ASCII::BoundingBox->new($node->draw());    
}

sub drawChildren {
    my ($self, $tree) = @_;
    # ready the children
    my ($left, $right) = (undef, undef);
    # get the left node, if we have one
    $left = $self->draw($tree->getLeft()) if $tree->hasLeft();
    # get the right node, if we have one
    $right = $self->draw($tree->getRight()) if $tree->hasRight(); 
    # and now return the children
    # in our case we need to handle 
    # them postionally and let an
    # undef value exist
    return ($left, $right);  
}

1;

__END__

=head1 NAME

Tree::Visualize::ASCII::Layouts::Binary - A base class for Tree::Binary and Tree::Binary::Search layouts

=head1 SYNOPSIS

  use Tree::Visualize::ASCII::Layouts::Binary;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<checkTree>

=item B<drawChildren>

=item B<drawNode>

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

