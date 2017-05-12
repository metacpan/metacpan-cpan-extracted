
package Tree::Visualize::ASCII::Layouts::Simple;

use strict;
use warnings;

our $VERSION = '0.01';

use base qw(Tree::Visualize::Layout::ILayout);

use Tree::Visualize::Exceptions;
use Tree::Visualize::ASCII::BoundingBox;
use Tree::Visualize::Node::Factory;

sub checkTree {
    my ($self, $tree) = @_;
    (defined($tree) && ref($tree) && UNIVERSAL::isa($tree, "Tree::Simple")) 
        || throw Tree::Visualize::IncorrectObjectType "tree argument must be a Tree::Simple object";
    return $tree;
}

sub drawNode {
    my ($self, $tree) = @_;
    my $node = Tree::Visualize::Node::Factory->new()->get(output => 'ASCII', node_type => 'PlainBox', args => [ $tree ]);
    return Tree::Visualize::ASCII::BoundingBox->new($node->draw());    
}

sub drawChildren {
    my ($self, $tree) = @_;
    return () if $tree->isLeaf();
    
    my @children;
    foreach my $child ($tree->getAllChildren()) {
        push @children => $self->draw($child);
    }
    
    return @children;
}

1;

__END__

=head1 NAME

Tree::Visualize::ASCII::Layouts::Simple - A base class for Tree::Simple layouts

=head1 SYNOPSIS

  use Tree::Visualize::ASCII::Layouts::Simple;

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

