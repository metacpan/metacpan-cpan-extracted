package yEd::Edge::PolyLineEdge;

use strict;
use yEd::PropertyBasedObject;
use base qw(yEd::Edge);

=head1 NAME

yEd::Edge::PolyLineEdge - straight point to point Edge

=head1 DESCRIPTION

A straight point to point Edge which can have multiple waypoints.

The bends have hard edging by default, but can be smoothend slightly.

Make sure to have a look at L<yEd::Edge>, the properties and functions described there will not be repeated here.

=head1 SUPPORTED FEATURES

The type specific features are fully supported.

For basic Edge type feature support and which Edge types are supported see L<yEd::Edge>.

=head1 PROPERTIES

=head2 all properties from base class

L<yEd::Edge>

=head2 smoothBend

Type: bool

Default: false

Slightly smoothen waypoint bends.

=head1 SUBROUTINES/METHODS

=head2 all functions from base class

L<yEd::Edge>

=cut

sub new {
    my ($class, @args) = @_;
    my $self = bless {}, $class;
    return $self->_init(@args);
}

sub _init {
    my ($self, @args) = @_;
    $self->smoothBend(0);
    $self->SUPER::_init(@args);
    return $self;
}

sub smoothBend {
    return _PROPERTY('bool', @_);
}

sub _addTypeNode {
    my ($self, $node) = @_;
    return $node->addNewChild('', 'y:PolyLineEdge');
}
sub _addAdditionalNodes {
    my ($self, $node) = @_;
    my $bs = $node->addNewChild('', 'y:BendStyle');
    $bs->setAttribute('smoothed', $self->smoothBend() ? 'true' : 'false');
}

=head1 SEE ALSO

L<yEd::Document> for further informations about the whole package

L<yEd::PropertyBasedObject> for further basic information about properties and their additional functions

L<yEd::Edge> for information about the Edge base class and which other Edge types are currently supported

=cut


1;
