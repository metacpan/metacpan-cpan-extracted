package yEd::Edge::SplineEdge;

use strict;
use yEd::PropertyBasedObject;
use base qw(yEd::Edge);

=head1 NAME

yEd::Edge::SplineEdge - curving Edge that always has its waypoints on its line

=head1 DESCRIPTION

A curving Edge that always has its waypoints on its line (in contrast to e.g. QuadCurveEdge).

Can have multiple waypoints.

Make sure to have a look at L<yEd::Edge>, the properties and functions described there will not be repeated here.

=head1 SUPPORTED FEATURES

The type specific features are fully supported.

For basic Edge type feature support and which Edge types are supported see L<yEd::Edge>.

=head1 PROPERTIES

=head2 all properties from base class

L<yEd::Edge>

=head1 SUBROUTINES/METHODS

=head2 all functions from base class

L<yEd::Edge>

=cut


sub new {
    my ($class, @args) = @_;
    my $self = bless {}, $class;
    return $self->_init(@args);
}

sub _addTypeNode {
    my ($self, $node) = @_;
    return $node->addNewChild('', 'y:SplineEdge');
}

=head1 SEE ALSO

L<yEd::Document> for further informations about the whole package

L<yEd::PropertyBasedObject> for further basic information about properties and their additional functions

L<yEd::Edge> for information about the Edge base class and which other Edge types are currently supported

=cut

1;
