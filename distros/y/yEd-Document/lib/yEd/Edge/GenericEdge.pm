package yEd::Edge::GenericEdge;

use strict;
use yEd::PropertyBasedObject;
use base qw(yEd::Edge);

=head1 NAME

yEd::Edge::GenericEdge - generic Edge type

=head1 DESCRIPTION

A generic Edge type which mostly behaves like a PolyLineEdge without smoothening.

It has two lines and can have a filling in between.

Like generic Nodes it has Java based properties that define it.
But this is hidden away at the moment since there actually is only one characteristic type.
This means that this class could change significantly with future versions of yEd.

Make sure to have a look at L<yEd::Edge>, the properties and functions described there will not be repeated here.

=head1 SUPPORTED FEATURES

The type specific features are fully supported.

For basic Edge type feature support and which Edge types are supported see L<yEd::Edge>.

=head1 PROPERTIES

=head2 all properties from base class

L<yEd::Edge>

=head2 configuration

Type: descrete values ( framed )

Default: framed

There is only one type at the moment, so this can be ignored.

=head2 fillColor

Type: '#0000fa' (rgb) or '#000000cc' (rgb + transparency) java.awt.Color hex form or 'none'

Default: 'none'

The filling between the 2 Edge lines.

=head1 SUBROUTINES/METHODS

=head2 all functions from base class

L<yEd::Edge>

=cut

my %conf = (
    'framed' => 'com.yworks.edge.framed',
);

sub new {
    my ($class, @args) = @_;
    my $self = bless {}, $class;
    return $self->_init(@args);
}

sub _init {
    my ($self, @args) = @_;
    $self->configuration('framed');
    $self->fillColor('none');
    $self->SUPER::_init(@args);
    return $self;
}

sub configuration {
    my $mask = join '|', keys %conf;
    return _PROPERTY('^(?:' . $mask . ')$', @_);
}
sub fillColor {
    return _PROPERTY($match{'color'}, @_);
}

sub _addTypeNode {
    my ($self, $node) = @_;
    my $type = $node->addNewChild('', 'y:GenericEdge');
    $type->setAttribute('configuration', $conf{$self->configuration()});
    return $type;
}
sub _addAdditionalNodes {
    my ($self, $node) = @_;
    if ($self->configuration() eq 'framed' and $self->fillColor() ne 'none') {
        my $sp = $node->addNewChild('', 'y:StyleProperties');
        my $p = $sp->addNewChild('', 'y:Property');
        $p->setAttribute('class', 'java.awt.Color');
        $p->setAttribute('name', 'FramedEdgePainter.fillColor');
        $p->setAttribute('value', $self->fillColor());
    }
}

=head1 SEE ALSO

L<yEd::Document> for further informations about the whole package

L<yEd::PropertyBasedObject> for further basic information about properties and their additional functions

L<yEd::Edge> for information about the Edge base class and which other Edge types are currently supported

=cut

1;
