
package Tree::Visualize::ASCII::Layouts::Binary::Diagonal;

use strict;
use warnings;

use Tree::Visualize::Exceptions;
use Tree::Visualize::ASCII::BoundingBox;

use Tree::Visualize::Node::Factory;
use Tree::Visualize::Connector::Factory;

our $VERSION = '0.01';

use base qw(Tree::Visualize::ASCII::Layouts::Binary);

sub drawNode {
    my ($self, $tree) = @_;
    my $node = Tree::Visualize::Node::Factory->new()->get(output => 'ASCII', node_type => 'Parens', args => [ $tree ]);
    return Tree::Visualize::ASCII::BoundingBox->new($node->draw());
}

sub drawConnections {
    my ($self, $current, $left, $right) = @_;
    # prepare the connections
    my ($left_connection, $right_connection) = (undef, undef);
    my $conn_factory = Tree::Visualize::Connector::Factory->new();
    # get the left connection if we need it
    $left_connection = $conn_factory->get(
                                output => 'ASCII',
                                layout => 'Diagonal',
                                connector_type => 'LeftRightConnector'
                                )->drawLeftConnector($current, $left, $right)
                                    if defined $left;
                                    
    # get the right connection if we need it
    $right_connection = $conn_factory->get(
                                output => 'ASCII',
                                layout => 'Diagonal',
                                connector_type => 'LeftRightConnector'
                                )->drawRightConnector($current, $right, $left)
                                    if defined $right;
    # return our connections
    return ($left_connection, $right_connection);
}

sub assembleDrawing {
    my ($self, $current, $children, $connections) = @_;
    
    my ($left, $right) = @{$children};
    my ($left_connection, $right_connection) = @{$connections};
    
    if (defined($right)) {
        $current->pasteRight($right_connection);
    } 
    if (defined($left)) {
        $current->pasteBottom($left_connection)
                ->pasteBottom($left); 
    }
    if (defined($right)) {
        $current->pasteRight($right);
    }
    
    return $current;
}

1;

__END__

=head1 NAME

Tree::Visualize::ASCII::Layouts::Binary::Diagonal - A Diagonal Tree::Binary and Tree::Binary::Search layout

=head1 SYNOPSIS

  use Tree::Visualize::ASCII::Layouts::Binary::Diagonal;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<assembleDrawing>

=item B<drawConnections>

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

