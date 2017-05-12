package yEd::Edge::QuadCurveEdge;

use strict;
use yEd::PropertyBasedObject;
use base qw(yEd::Edge);

=head1 NAME

yEd::Edge::QuadCurveEdge - quadratic curve Edge

=head1 DESCRIPTION

Creates an Edge with quadratic curving.

It can have multiple waypoints which may actually lie outside the Edge depending on C<straightness>.

A C<straightness> set to 1 will look like a PolyLineEdge without smoohting.

Make sure to have a look at L<yEd::Edge>, the properties and functions described there will not be repeated here.

=head1 SUPPORTED FEATURES

The type specific features are fully supported.

For basic Edge type feature support and which Edge types are supported see L<yEd::Edge>.

=head1 PROPERTIES

=head2 all properties from base class

L<yEd::Edge>

=head2 straightness

Type: ratio (ufloat [0-1])

Default: 0.1

The straightness.

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
    $self->straightness(0.1);
    $self->SUPER::_init(@args);
    return $self;
}

sub straightness {
    return _PROPERTY($match{'ratio'}, @_);
}

sub _addTypeNode {
    my ($self, $node) = @_;
    my $type = $node->addNewChild('', 'y:QuadCurveEdge');
    $type->setAttribute('straightness', $self->straightness());
    return $type;
}

=head1 SEE ALSO

L<yEd::Document> for further informations about the whole package

L<yEd::PropertyBasedObject> for further basic information about properties and their additional functions

L<yEd::Edge> for information about the Edge base class and which other Edge types are currently supported

=cut

1;
