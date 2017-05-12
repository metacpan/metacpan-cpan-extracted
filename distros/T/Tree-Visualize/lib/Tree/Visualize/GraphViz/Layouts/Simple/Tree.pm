
package Tree::Visualize::GraphViz::Layouts::Simple::Tree;

use strict;
use warnings;

use Tree::Visualize::Exceptions;

our $VERSION = '0.01';

use base qw(Tree::Visualize::Layout::ILayout);

sub draw {
    my ($self, $tree) = @_;
    (defined($tree) && ref($tree) && UNIVERSAL::isa($tree, "Tree::Simple")) 
            || throw Tree::Visualize::IncorrectObjectType "argument must be Tree::Simple instance"; 
    return $self->_draw($tree);
}
            
sub _draw {
    my ($self, $tree) = @_;
    my $output = "digraph test {\n";
    $output .= "node_" . $tree->getUID() . " [ label = \"" . $tree->getNodeValue() . "\" ];\n";    
    $output .= $self->_draw_tree($tree);
    $output .= "}\n";
    return $output;
}

sub _draw_tree {
    my ($self, $tree) = @_;
    my $output = "";
    $tree->traverse(sub {
        my ($tree) = @_;   
        my $tree_id = $tree->getUID();
        my $parent_id = $tree->getParent()->getUID() unless $tree->isRoot();
        $output .= "node_$tree_id [ label = \"" . $tree->getNodeValue() . "\" ];\n";
        $output .= "node_${parent_id} -> node_${tree_id};\n" if $parent_id;
    });
    return $output;
}



1;

__END__

=head1 NAME

Tree::Visualize::GraphViz::Layouts::Simple::Tree - 

=head1 SYNOPSIS

  use Tree::Visualize::GraphViz::Layouts::Simple::Tree;

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

