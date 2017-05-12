
package Tree::Visualize::Node::INode;

use strict;
use warnings;

our $VERSION = '0.01';

sub new {
    my ($_class, $tree) = @_;
    my $class = ref($_class) || $_class;  
    my $node = {};    
    bless($node, $class);
    $node->_init($tree);
    return $node;
}

sub _init {
    my ($self, $tree) = @_;
    (defined($tree) && ref($tree) &&
        (UNIVERSAL::isa($tree, "Tree::Binary") || UNIVERSAL::isa($tree, "Tree::Simple"))) 
            || throw Tree::Visualize::InsufficientArguments "You must supply a tree to a Node object";
    $self->{tree} = $tree;
}

sub draw { throw Tree::Visualize::MethodNotImplemented }

1;

__END__

=head1 NAME

Tree::Visualize::Node::INode - An abstract base class for Node drawings

=head1 SYNOPSIS

  use Tree::Visualize::Node::INode;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<new>

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

