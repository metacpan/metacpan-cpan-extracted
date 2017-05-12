package yEd::Node::ShapeNode;

use strict;
use yEd::PropertyBasedObject;
use base qw(yEd::Node);

=head1 NAME

yEd::Node::ShapeNode - Basic shape node type

=head1 DESCRIPTION

Use this class to create basic shape Nodes. 

These are all the Nodes from yEd's "Shape Nodes" group.

Make sure to have a look at L<yEd::Node>, the properties and functions described there will not be repeated here.

=head1 SUPPORTED FEATURES

The ShapeNode type specific features are fully supported.

For basic Node type feature support and which node types are supported see L<yEd::Node>.

=head1 PROPERTIES

=head2 all properties from base class

L<yEd::Node>

=head2 shape

Type: descrete values ( roundrectangle | rectangle | ellipse | parallelogram | hexagon | triangle | rectangle3d | octagon | diamond | trapezoid | trapezoid2 )

Default: 'roundrectangle'

The shape used for this node.

=head2 shadowColor

Type: '#0000fa' (rgb) or '#000000cc' (rgb + transparency) java.awt.Color hex form or 'none'

Default: '#b3a691'

The color of the Node's shadow.

=head2 shadowX

Type: 'float'

Default: 0

The x offset of the Node's shadow.

=head2 shadowY

Type: 'float'

Default: 0

The y offset of the Node's shadow.

=head1 SUBROUTINES/METHODS

=head2 all functions from base class

L<yEd::Node>

=cut

my $shapes = '^(?:roundrectangle|rectangle|ellipse|parallelogram|hexagon|triangle|rectangle3d|octagon|diamond|trapezoid|trapezoid2)$';

sub new {
    my ($class, @args) = @_;
    my $self = bless {}, $class;
    return $self->_init(@args);
}

sub _init {
    my ($self, @args) = @_;
    $self->shape('roundrectangle');
    $self->shadowColor('#b3a691');
    $self->shadowX(0);
    $self->shadowY(0);
    $self->SUPER::_init(@args);
    return $self;
}

sub shape {
    return _PROPERTY($shapes, @_);
}

sub shadowColor {
    return _PROPERTY($match{'color'}, @_);
}

sub shadowX {
    return _PROPERTY($match{'float'}, @_);
}

sub shadowY {
    return _PROPERTY($match{'float'}, @_);
}

sub _addTypeNode {
    my ($self, $node) = @_;
    return $node->addNewChild('', 'y:ShapeNode');
}
sub _addAdditionalNodes {
    my ($self, $node) = @_;
    my $shape = $node->addNewChild('', 'y:Shape');
    $shape->setAttribute('type', $self->shape());
    if ($self->shadowX() != 0 or $self->shadowY() != 0) {
        my $shadow = $node->addNewChild('', 'y:DropShadow');
        $shadow->setAttribute('color', $self->shadowColor());
        $shadow->setAttribute('offsetX', $self->shadowX());
        $shadow->setAttribute('offsetY', $self->shadowY());
    }
}

=head1 SEE ALSO

L<yEd::Document> for further informations about the whole package

L<yEd::PropertyBasedObject> for further basic information about properties and their additional functions

L<yEd::Node> for information about the Node base class and which other Node types are currently supported

=cut

1;
