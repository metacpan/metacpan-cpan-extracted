package yEd::Edge::BezierEdge;

use strict;
use yEd::PropertyBasedObject;
use base qw(yEd::Edge);


=head1 NAME

yEd::Edge::BezierEdge - creates a bezier curve between source and target

=head1 DESCRIPTION

Creates a bezier curve between source and target.

To achieve this you may add up to 2 waypoints in yEd which act as the reference points for the bezier.

Since yEd handles it correctly if you add more than 2 waypoints (although it doesn't look like the intended curve anymore), this class is not restricted to a maximum of 2 waypoints. 

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
    return $node->addNewChild('', 'y:BezierEdge');
}

=head1 SEE ALSO

L<yEd::Document> for further informations about the whole package

L<yEd::PropertyBasedObject> for further basic information about properties and their additional functions

L<yEd::Edge> for information about the Edge base class and which other Edge types are currently supported

=cut

1;
