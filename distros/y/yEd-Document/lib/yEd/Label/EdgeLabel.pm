package yEd::Label::EdgeLabel;

use strict;
use yEd::PropertyBasedObject;
use base qw(yEd::Label);

=head1 NAME

yEd::Label::EdgeLabel - Textlabels for Edges

=head1 DESCRIPTION

Use this class to label your Edges. 

Make sure to have a look at L<yEd::Label>, the properties and functions described there will not be repeated here.

If you want to label a Node class element use L<yEd::Label::NodeLabel>. 

=head1 SUPPORTED FEATURES

see L<yEd::Label>

=head1 PROPERTIES

=head2 all properties from base class

L<yEd::Label>

=head2 positionModell

Type: descrete values ( see below )

Default: 'two_pos-head'

Describes how to position the Label on the Edge.

=head3 free

Free positioning (use C<x>, C<y> properties)

=head3 two_pos-X

Where X is one of:

=over 4

=item *

head : Centered above line

=item *

tail : Centered below line

=back

=head3 centered

Centered on line

=head3 six_pos-X

Where X is one of:

=over 4

=item *

head : Centered above line

=item *

shead : At source above line

=item *

thead : At target above line

=item *

tail : Centered below line

=item *

stail : At source below line

=item *

ttail : At target below line

=back

=head3 three_center-X 

Where X is one of:

=over 4

=item *

center : Centered on line

=item *

scentr : At source on line

=item *

tcentr : At target on line

=back

=head3 center_slider

On the line position defined by ratio

=head3 side_slider

Above or below the line position defined by ratio and y value for above/below (?)

=head2 ratio

Type: ration (ufloat [0-1])

Default: 0.5

Defines the Label position for slider positioning modells, where 0 is at source, 1 is at target and 0.5 is centered.

=head2 distance

Type: float

Default: 2

Defines the distance of the Label from the Edge (may have no effect depending on positioning modell).

=head2 autoFlip

Type: bool

Default: true

Automatically flip the Label if it gets upside-down (because of effective direction of the Edge).

=head1 SUBROUTINES/METHODS

=head2 all functions from base class

L<yEd::Label>

=cut

my $modellmatch = '^(?:free|two_pos-(?:head|tail)|centered|six_pos-(?:head|shead|thead|tail|stail|ttail)|three_center-(?:center|scentr|tcentr)|center_slider|side_slider)$';

sub new {
    my ($class, @args) = @_;
    my $self = bless {}, $class;
    return $self->_init(@args);
}

sub _init {
    my ($self, @args) = @_;
    $self->distance(2);
    $self->autoFlip(1);
    $self->ratio(0.5);
    $self->positionModell('two_pos-head');
    $self->SUPER::_init(@args);
    return $self;
}

sub positionModell {
    return _PROPERTY($modellmatch, @_);
}
sub distance { # to edge
    return _PROPERTY($match{'float'}, @_);
}
sub ratio { # position on sliders
    return _PROPERTY($match{'ratio'}, @_);
}
sub autoFlip {
    return _PROPERTY('bool', @_);
}

sub _build {
    my $self = shift;
    my $node = XML::LibXML::Element->new('y:EdgeLabel');
    $node->appendText($self->getTextString());
    $node->setAttribute('alignment', $self->alignment());
    $node->setAttribute('fontFamily', $self->fontFamily());
    $node->setAttribute('fontSize', $self->fontSize());
    $node->setAttribute('fontStyle', $self->fontStyle());
    if ($self->backgroundColor() eq 'none') {
        $node->setAttribute('hasBackgroundColor', 'false');
    } else {
        $node->setAttribute('backgroundColor', $self->backgroundColor());
    }
    if ($self->lineColor() eq 'none') {
        $node->setAttribute('hasLineColor', 'false');
    } else {
        $node->setAttribute('lineColor', $self->lineColor());
    }
    $node->setAttribute('x', $self->x());
    $node->setAttribute('y', $self->y());
    $node->setAttribute('height', $self->height());
    $node->setAttribute('width', $self->width());
    $node->setAttribute('textColor', $self->textColor() eq 'none' ? '#000000' : $self->textColor());
    $node->setAttribute('visible', $self->visible() ? 'true' : 'false');
    $node->setAttribute('bottomInset', $self->bottomInset()) unless ($self->bottomInset() =~ m/^0*$/);;
    $node->setAttribute('topInset', $self->topInset()) unless ($self->topInset() =~ m/^0*$/);;
    $node->setAttribute('rightInset', $self->rightInset()) unless ($self->rightInset() =~ m/^0*$/);;
    $node->setAttribute('leftInset', $self->leftInset()) unless ($self->leftInset() =~ m/^0*$/);;
    $node->setAttribute('rotationAngle', $self->rotationAngle()) unless ($self->rotationAngle() =~ m/^-?0*\.?0*$/);;
    $node->setAttribute('underlinedText', 'true') if ($self->underlinedText());
    # EdgeLabel
    if ($self->positionModell() eq 'free') {
        $node->setAttribute('modelName', $self->positionModell());
        $node->setAttribute('modelPosition', 'anywhere');
    } elsif ($self->positionModell() eq 'centered') {
        $node->setAttribute('modelName', $self->positionModell());
        $node->setAttribute('modelPosition', 'center');
    } elsif ($self->positionModell() =~ m/^(?:center|side)_slider$/) {
        $node->setAttribute('modelName', $self->positionModell());
    } else {
        my ($m, $p) = split '-', $self->positionModell();
        $node->setAttribute('modelName', $m);
        $node->setAttribute('modelPosition', $p);
    }
    $node->setAttribute('configuration', 'AutoFlippingLabel') if ($self->autoFlip());
    $node->setAttribute('distance', $self->distance());
    $node->setAttribute('ratio', $self->ratio());
    $node->setAttribute('preferredPlacement', 'anywhere');
    my $ppdNode = $node->addNewChild('', 'y:PreferredPlacementDescriptor');
    $ppdNode->setAttribute('angle', '0.0');
    $ppdNode->setAttribute('angleOffsetOnRightSide', '0');
    $ppdNode->setAttribute('angleReference', 'relative_to_edge_flow');
    $ppdNode->setAttribute('angleRotationOnRightSide', 'co');
    $ppdNode->setAttribute('distance', '-1.0');
    $ppdNode->setAttribute('placement', 'anywhere');
    $ppdNode->setAttribute('side', 'anywhere');
    $ppdNode->setAttribute('sideReference', 'relative_to_edge_flow');
    $ppdNode->setAttribute('preferredPlacement', 'anywhere');
    return $node;
}

=head1 SEE ALSO

L<yEd::Document> for further informations about the whole package

L<yEd::PropertyBasedObject> for further basic information about properties and their additional functions

L<yEd::Label> for information about the Label base class

L<yEd::Label::NodeLabel> for information about specialized Label elements for Nodes

=cut

1;
