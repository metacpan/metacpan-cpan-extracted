package yEd::Node;

use strict;
use yEd::PropertyBasedObject;
use yEd::Label::NodeLabel;
use XML::LibXML;
use Carp;

=head1 NAME

yEd::Node - Base class for Nodes

=head1 DESCRIPTION

This is the base class for Nodes. 
It may not be instanciated, instead use one of the specialized types as described in the L</SUPPORTED FEATURES> section.

Have a look at the C<addNewNode()> function of L<yEd::Document>, it is the preferred way to create Nodes.

For saving Node templates see L<yEd::Document>'s C<addNewNodeTemplate()>, C<addTemplateNode()> and the related functions.

=head1 SUPPORTED FEATURES

The following Node types are currently supported:

=over 4
    
=item *
    
L<yEd::Node::ShapeNode> basic shape type nodes
    
=item *
    
L<yEd::Node::GenericNode> see link for a list of which Nodes of yEd actually are GenericNodes
    
=back

The following types and features are currently not supported (and it's not sure they'll ever be):

=over 4

=item *

Group/Folder type Nodes (e.g. group 'Group Nodes')

=item *

Table type Nodes (e.g. group "Swimlane Nodes and Tables")

=item *

SVG type Nodes (e.g. group "People")

=item *

Adding meta data to Nodes or edit the present ones (e.g. URL, description)

=back

All other basic features of Nodes (yEd Version 3.13) are supported.

Support beyond yEd:

=over 4
    
=item *
    
You may specify Nodes to be relative to other Nodes (see C<relative> property)

=item *

You may add multiple Labels to a single Node (yEd will handle it properly)

=back

=head1 PROPERTIES

=head2 layer

Type: uint

Default: 0

The drawing pane layer this Node is on.

See L<yEd::Document> for details about using layers.

=head2 relative

Type: yEd::Node or 0 to erase relation

Default: 0

If a Node reference is set here, this Nodes x and y properties will be interpreted as being relative to the given Node.

See L<yEd::Document> for details about relative objects.

=head2 id

This property is read only and returns the Nodes ID.

See L<yEd::Document> for details about object identifiers.

=head2 x

Type: float

Default: 0

The x position (upper left corner).

=head2 y

Type: float

Default: 0

The y position (upper left corner).

=head2 height

Type: ufloat

Default: 30

The height of the Node.

=head2 width

Type: ufloat

Default: 30

The width of the Node.

=head2 fillColor

Type: '#0000fa' (rgb) or '#000000cc' (rgb + transparency) java.awt.Color hex form or 'none'

Default: '#ffcc00'

The background color.

=head2 fillColor2

Type: '#0000fa' (rgb) or '#000000cc' (rgb + transparency) java.awt.Color hex form or 'none'

Default: 'none'

The second background color (will be ignored if fillColor is 'none').

=head2 borderColor

Type: '#0000fa' (rgb) or '#000000cc' (rgb + transparency) java.awt.Color hex form or 'none'

Default: '#000000'

The color for the border line.

=head2 borderType

Type: descrete values ( line | dotted | dashed | dashed_dotted )

Default: 'line'

Linetype of the border.

=head2 borderWidth

Type: ufloat

Default: 1

The width of the border.

=head1 SUBROUTINES/METHODS

=head2 new

Creates a new instance of a Node.

An ID must be provided as first parameter.
This value may be any string or number but must be unique among the whole L<yEd::Document>.
If you don't want to bother with IDs use the C<addNewNode()> function of L<yEd::Document> instead, it will take care of the IDs.

Further parameters to set properties are optional (C<property1 =E<gt> value, property2 =E<gt> value2, ...>).

=head3 EXAMPLE

    my $node = yEd::Node::GenericNode->new('myid1', 'x' => 500, 'y' => -33.7);

=cut

sub new {
    confess 'you may not instantiate a yEd::Node base class object';
}

=head2 copy

Creates a copy of this Node and returns it.

Also copies all attached Labels.

An ID must be given as first parameter as described in the Node classes constructors, it will be applied to the copy.

You may optionally specify properties in the form C<property1 =E<gt> value, property2 =E<gt> value2, ...> to change these properties for the returned copy.

If this Node is relative to another one you may want to set a new relation partner for the copy, change its relative position or make it absolute.

=head3 EXAMPLE

    my $node2 = $node->copy('id2', 'x' => 89.5, 'y' => -33.7);

=cut

sub copy {
    my ($self, $id, @p) = @_;
    my $ref = ref $self;
    my $o = $ref->new($id);
    $o->setProperties($self->getProperties());
    $o->setProperties(@p);
    foreach my $l ($self->labels()) {
        $o->addLabel($l->copy());
    }
    return $o;
}

sub _init {
    my ($self, $id, @properties) = @_;
    confess 'node id missing for node creation' unless (defined $id);
    $self->{'properties'}{'id'} = $id;
    $self->{'datakeys'} = [ 'd4', 'd5' ];
    $self->{'rootkey'} = 'd6';
    # defaults
    $self->relative(0);
    $self->x(0);
    $self->y(0);
    $self->height(30);
    $self->width(30);
    $self->fillColor('#ffcc00');
    $self->fillColor2('none');
    $self->borderColor('#000000');
    $self->borderType('line');
    $self->borderWidth(1);
    $self->clearLabels();
    $self->layer(0);
    $self->{'edges'} = {};
    # user values
    $self->setProperties(@properties);
    return $self;
}

# "virtual" properties
sub layer {
    return _PROPERTY($match{'uint'}, @_);
}
sub _checkloop {
    my $self = shift;
    my $node = $self;
    my $count = 0;
    do {
        $node = $node->relative();
        $count++;
        confess "loop detected: relative node $self (id: " . $self->id() . ") found itself $count nodes later in hierarchy" if ($node == $self);
    } while ($node);
}
sub relative {
    my ($self, $value) = @_;
    my $key = 'relative';
    if (defined $value) {
        confess "value must be a yEd::Node (or one of its subtypes) (given value: $value)" unless ($value == 0 or $value->isa('yEd::Node'));
        confess "Did you really think making a Node relative to itself would be a good idea?" if ($value and $value == $self);
        $self->{'properties'}{$key} = $value;
        $self->_checkloop();
        return;
    } else {
        return $self->{'properties'}{$key};
    }
}

# node
sub id {
    return _PROPERTY('ro', @_);
}

sub _registerEdge {
    my ($self, $edge) = @_;
    if ($edge->isa('yEd::Edge')) {
        $self->{'edges'}{$edge}{'count'}++;
        $self->{'edges'}{$edge}{'ref'} = $edge;
    }
}
sub _deregisterEdge {
    my ($self, $edge) = @_;
    if ($edge->isa('yEd::Edge')) {
        $self->{'edges'}{$edge}{'count'}--;
        delete $self->{'edges'}{$edge} unless ($self->{'edges'}{$edge}{'count'});
    }
}

=head2 absX

Returns the absolute x value for this Node which equals C<$node-E<gt>x()> unless C<$node-E<gt>relative($node2)> was set.
In this case C<$node-E<gt>absX()> is C<$node2-E<gt>absX()> + C<$node-E<gt>x()>.

=head3 EXAMPLE

    # before you do $node->relative(0) you may want to make coords absolute:
    $node->x($node->absX());

=cut

sub absX {
    my $self = shift;
    my $x = $self->x();
    $x += $self->relative()->absX() if ($self->relative());
    return $x;
}

=head2 absY

Returns the absolute y value for this Node which equals C<$node-E<gt>y()> unless C<$node-E<gt>relative($node2)> was set.
In this case C<$node-E<gt>absY()> is C<$node2-E<gt>absY()> + C<$node-E<gt>y()>.

=head3 EXAMPLE

    # before you do $node->relative(0) you may want to make coords absolute:
    $node->y($node->absY());

=cut

sub absY {
    my $self = shift;
    my $y = $self->y();
    $y += $self->relative()->absY() if ($self->relative());
    return $y;
}

=head2 absCenter

Returns the absolute (x,y) values for this Node's center (as an array of 2 elements).
Note that normal coords indicate the upper left corner of a Node.

=head3 EXAMPLE

    my ($xc, $yc) = $node->absCenter();

=cut

sub absCenter {
    my $self = shift;
    return (
        $self->absX() + 0.5 * $self->width(),
        $self->absY() + 0.5 * $self->height()
    );
}

=head2 getEdges

Returns an array of all Edges connected to this Node.

=head3 EXAMPLE

    foreach my $edge ($node->getEdges()) { ...

=cut

sub getEdges {
    my $self = shift;
    my @edges;
    foreach my $edge (keys %{$self->{'edges'}}) {
        push @edges, $self->{'edges'}{$edge}{'ref'};
    }
    return @edges;
}

# Labels

=head2 addNewLabel

Takes a value for the C<text> property of Labels followed by optional Label properties (C<property1 =E<gt> value, property2 =E<gt> value2, ...>) and creates and adds a new Label from it.

Returns a ref to the Label object.

=head3 EXAMPLE

    my $label = $node->addNewLabel('hello world', 'alignment' => 'left');

=cut

sub addNewLabel {
    my $self = shift;
    my $label = yEd::Label::NodeLabel->new(@_);
    $self->addLabel($label);
    return $label;
}

=head2 addLabel

Takes a L<yEd::Label::NodeLabel> object and adds it.

=head3 EXAMPLE

    $node->addLabel($label);

=cut

sub addLabel {
    my ($self, $label) = @_;
    confess "only yEd::Label::NodeLabel's can be added" unless ($label->isa('yEd::Label::NodeLabel'));
    push @{$self->{'labels'}}, $label;
    return;
}

=head2 labels

Acts as a getter with no parameters provided and returns an array of all Labels attached to this Node.

If an array of NodeLabel objects is provided, this Node's Labels are replaced by the given Labels.

=head3 EXAMPLE

    # this will make a copy of the array but not the Labels itself 
    $node->labels($node2->labels());
    # if you want a copy rather than shared refs use Label's copy() function:
    $node->clearLabels(); # if there may be any
    foreach my $l ($node2->labels()) {
        $node->addLabel($l->copy());
    }

=cut

sub labels {
    my ($self, @labels) = @_;
    if (@labels) {
        foreach my $label (@labels) {
            confess "only yEd::Label::NodeLabel's can be added" unless ($label->isa('yEd::Label::NodeLabel'));
        }
        $self->{'labels'} = \@labels;
        return;
    } else {
        return @{$self->{'labels'}};
    }
}

=head2 clearLabels

Removes all Labels from this Node.

=head3 EXAMPLE

    $node->clearLabels();

=cut

sub clearLabels {
    $_[0]->{'labels'} = [];
    return;
}

=head2 getLabelsByProperties

Takes arguments of the form C<property1 =E<gt> value, property2 =E<gt> value2, ...>.

Returns a list of all Labels that matches the given filter.

=head3 EXAMPLE

    my @bigfatlabels = $node->getLabelsByProperties('fontSize' => 20, 'fontStyle' => 'bold');

=cut

sub getLabelsByProperties {
    my ($self, @properties) = @_;
    my @labels;
    foreach my $label ($self->labels()) {
        push @labels, $label if $label->hasProperties(@properties);
    }
    return @labels;
}

# Geometry
sub x {
    return _PROPERTY($match{'float'}, @_);
} 
sub y {
    return _PROPERTY($match{'float'}, @_);
} 
sub height {
    return _PROPERTY($match{'ufloat'}, @_);
} 
sub width {
    return _PROPERTY($match{'ufloat'}, @_);
} 

# Fill
sub fillColor {
    return _PROPERTY($match{'color'}, @_);
} 
sub fillColor2 {
    return _PROPERTY($match{'color'}, @_);
} 

# BorderStyle
sub borderColor {
    return _PROPERTY($match{'color'}, @_);
} 
sub borderType {
    return _PROPERTY($match{'linetype'}, @_);
} 
sub borderWidth {
    return _PROPERTY($match{'ufloat'}, @_);
} 

sub _build {
    my $self = shift;
    my $node = $self->_createNodeNode();
    my $root = $self->_addRootNode($node);
    my $type = $self->_addTypeNode($root);
    $self->_addGeometryNode($type);
    $self->_addFillNode($type);
    $self->_addBorderNode($type);
    $self->_addLabelsNode($type);
    $self->_addAdditionalNodes($type);
    return $node;
}
sub _createNodeNode {
    my $self = shift;
    my $node = XML::LibXML::Element->new('node');
    $node->setAttribute('id', $self->id());
    foreach my $dk (@{$self->{'datakeys'}}) {
        $node->addNewChild('', 'data')->setAttribute('key', $dk);
    }
    return $node;
}
sub _addRootNode {
    my ($self, $node) = @_;
    my $root = $node->addNewChild('', 'data');
    $root->setAttribute('key', $self->{'rootkey'});
    return $root;
}
sub _addTypeNode {
    # add type node here and return it (e.g. <y:ShapeNode>)
    confess 'you may not build a yEd::Node base class object, override this method in a specialized subclass';
}
sub _addGeometryNode {
    my ($self, $node) = @_;
    my $geo = $node->addNewChild('', 'y:Geometry');
    $geo->setAttribute('height', $self->height());
    $geo->setAttribute('width', $self->width());
    $geo->setAttribute('x', $self->absX());
    $geo->setAttribute('y', $self->absY());
}
sub _addFillNode {
    my ($self, $node) = @_;
    my $fill = $node->addNewChild('', 'y:Fill');
    if ($self->fillColor() eq 'none') {
        $fill->setAttribute('hasColor', 'false');
    } else {
        $fill->setAttribute('color', $self->fillColor());
        $fill->setAttribute('color2', $self->fillColor2()) unless ($self->fillColor2() eq 'none');
    }
    $fill->setAttribute('transparent', 'false');
}
sub _addBorderNode {
    my ($self, $node) = @_;
    my $border = $node->addNewChild('', 'y:BorderStyle');
    if ($self->borderColor() eq 'none') {
        $border->setAttribute('hasColor', 'false');
    } else {
        $border->setAttribute('color', $self->borderColor());
    }
    $border->setAttribute('type', $self->borderType());
    $border->setAttribute('width', $self->borderWidth());
}
sub _addLabelsNode {
    my ($self, $node) = @_;
    foreach my $label ($self->labels()) {
        $node->addChild($label->_build());
    }
}
sub _addAdditionalNodes {
    # add type specific data here (e.g. <y:Shape ...)
}

=head2 setProperties getProperties hasProperties

As described at L<yEd::PropertyBasedObject>

=head1 SEE ALSO

L<yEd::Document> for further informations about the whole package

L<yEd::PropertyBasedObject> for further basic information about properties and their additional functions

The specialized Nodes:

L<yEd::Node::ShapeNode>

L<yEd::Node::GenericNode>

=cut

1;
