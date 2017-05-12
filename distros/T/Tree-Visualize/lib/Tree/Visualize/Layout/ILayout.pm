
package Tree::Visualize::Layout::ILayout;

use strict;
use warnings;

use Tree::Visualize::Exceptions;

our $VERSION = '0.01';

sub new { 
    my ($_class, $options) = @_;
    my $class = ref($_class) || $_class;
    my $layout = {};
    bless($layout, $class);
    return $layout;
}

sub draw {
    my ($self, $tree) = @_;
    # check the tree, do anything needed on it
    $tree = $self->checkTree($tree);
    # draw the current node
    my $current = $self->drawNode($tree);
    # draw all the children
    my @children = $self->drawChildren($tree);
    # draw all the connections
    my @connections = $self->drawConnections($current, @children);
    # assemble the drawing and return it
    return $self->assembleDrawing($current, \@children, \@connections);
}

sub checkTree       { throw Tree::Visualize::MethodNotImplemented }
sub drawNode        { throw Tree::Visualize::MethodNotImplemented }
sub drawChildren    { throw Tree::Visualize::MethodNotImplemented }
sub drawConnections { throw Tree::Visualize::MethodNotImplemented }
sub assembleDrawing { throw Tree::Visualize::MethodNotImplemented }

1;

__END__

=head1 NAME

Tree::Visualize::Layout::ILayout - An abstract base class for Layout objects

=head1 SYNOPSIS

  use Tree::Visualize::Layout::ILayout;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<new>

=item B<checkTree>

=item B<assembleDrawing>

=item B<draw>

=item B<drawNode>

=item B<drawChildren>

=item B<drawConnections>

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

