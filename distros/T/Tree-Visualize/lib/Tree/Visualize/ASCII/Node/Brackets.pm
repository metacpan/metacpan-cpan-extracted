
package Tree::Visualize::ASCII::Node::Brackets;

use strict;
use warnings;

use Tree::Visualize::Exceptions;

our $VERSION = '0.01';

use base qw(Tree::Visualize::Node::INode);

sub draw {
    my ($self) = @_;
    my $node_value = $self->{tree}->getNodeValue();
    ($node_value !~ /\n/) 
        || throw Tree::Visualize::IllegalOperation "node value has a newline in it, this is currently not supported.";             
    return "[$node_value]"; 
}

1;

__END__

=head1 NAME

Tree::Visualize::ASCII::Node::Brackets - A simple bracket node

=head1 SYNOPSIS

  use Tree::Visualize::ASCII::Node::Brackets;

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

