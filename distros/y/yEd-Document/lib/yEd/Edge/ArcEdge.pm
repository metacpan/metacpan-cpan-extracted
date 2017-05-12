package yEd::Edge::ArcEdge;

use strict;
use yEd::PropertyBasedObject;
use base qw(yEd::Edge);
use Carp;

=head1 NAME

yEd::Edge::ArcEdge - spans an arc from source to target

=head1 DESCRIPTION

This Edge spans an arc from C<source> to C<target>.

It can have no waypoints, thus calls to C<addWaypoint()> or C<waypoints()>> will result in error.

Make sure to have a look at L<yEd::Edge>, the properties and functions described there will not be repeated here.

=head1 SUPPORTED FEATURES

The type specific features are fully supported.

For basic Edge type feature support and which Edge types are supported see L<yEd::Edge>.

=head1 PROPERTIES

=head2 all properties from base class

L<yEd::Edge>

=head2 arcType 

Type: descrete values ( fixedRatio | fixedHeight )

Default: 'fixedRatio'

Defines the mode for arc shaping.

=head2 arcHeight

Type: float

Default: 90

Defines arc shape in mode fixedRatio.

=head2 arcRatio

Type: float

Default: 1

Defines arc shape in mode fixedHeight.

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
    $self->arcType('fixedRatio');
    $self->arcHeight(90);
    $self->arcRatio(1);
    $self->SUPER::_init(@args);
    return $self;
}

sub arcType {
    return _PROPERTY($match{'arctype'}, @_);
}
sub arcHeight {
    return _PROPERTY($match{'float'}, @_);
}
sub arcRatio {
    return _PROPERTY($match{'float'}, @_);
}

sub addWaypoint {
    confess 'setting waypoints is not allowed for edge type ArcEdge';
}
sub waypoints {
    my ($self, @wps) = @_;
    if (@wps) {
        confess 'setting waypoints is not allowed for edge type ArcEdge';
    } else {
        return @{$self->{'waypoints'}};
    }
}

sub _addTypeNode {
    my ($self, $node) = @_;
    return $node->addNewChild('', 'y:ArcEdge');
}
sub _addAdditionalNodes {
    my ($self, $node) = @_;
    my $arc = $node->addNewChild('', 'y:Arc');
    $arc->setAttribute('height', $self->arcHeight());
    $arc->setAttribute('ratio', $self->arcRatio());
    $arc->setAttribute('type', $self->arcType());
}

=head1 SEE ALSO

L<yEd::Document> for further informations about the whole package

L<yEd::PropertyBasedObject> for further basic information about properties and their additional functions

L<yEd::Edge> for information about the Edge base class and which other Edge types are currently supported

=cut

1;
