
package Tree::Visualize::Connector::IConnector;

use strict;
use warnings;

use Tree::Visualize::Exceptions;

our $VERSION = '0.01';

## constructor

sub new {
    my ($_class) = @_;
    my $class = ref($_class) || $_class;
    my $connector = {};
    bless($connector, $class);
    return $connector;
}

sub checkArgs {
    my ($self, @args) = @_;
    (defined($_) && ref($_) && UNIVERSAL::isa($_, "Tree::Visualize::ASCII::BoundingBox"))
        || throw Tree::Visualize::InsufficientArguments "argument must be a bounding box"
            foreach @args;     
}

1;

__END__

=head1 NAME

Tree::Visualize::Connector::IConnector - An abstract base class for Connector objects

=head1 SYNOPSIS

  use Tree::Visualize::Connector::IConnector;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<new>

=item B<checkArgs>

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

