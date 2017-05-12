package yEd::Label::NodeLabel;

use strict;
use yEd::PropertyBasedObject;
use base qw(yEd::Label);

=head1 NAME

yEd::Label::NodeLabel - Textlabels for Nodes

=head1 DESCRIPTION

Use this class to label your Nodes. 

Make sure to have a look at L<yEd::Label>, the properties and functions described there will not be repeated here.

If you want to label an Edge class element use L<yEd::Label::EdgeLabel>. 

=head1 SUPPORTED FEATURES

see L<yEd::Label>

=head1 PROPERTIES

=head2 all properties from base class

L<yEd::Label>

=head2 positionModell

Type: descrete values ( see below )

Default: 'internal-c'

Describes how to position the Label on the Node.

=head3 free

Free positioning (use C<x>, C<y> properties)

=head3 internal-X

Within the Node.

Where X is one of:

=over 4

=item *

c : centered 

=item *

t : top

=item *

b : bottom

=item *

l : left

=item *

r : right

=item *

tl : top left

=item *

tr : top right

=item *

bl : bottom left

=item *

br : bottom right

=back

=head3 corners-X

Outside of the Node.

Where X is one of:

=over 4

=item *

nw : north west

=item *

ne : north east

=item *

se : south east

=item *

sw : south west

=back

=head3 sandwich-X

Outside of the Node.

Where X is one of:

=over 4

=item *

n : north

=item *

s : south

=back

=head3 sides-X

Outside of the Node.

Where X is one of:

=over 4

=item *

n : north

=item *

s : south

=item *

w : west

=item *

e : east

=back

=head3 eight_pos-X

Outside of the Node.

Where X is one of:

=over 4

=item *

n : north

=item *

s : south

=item *

w : west

=item *

e : east

=item *

nw : north west

=item *

ne : north east

=item *

se : south east

=item *

sw : south west

=back

=head3 edge_opposite

Outside of the Node, opposing the side that is connected to an Edge.

=head2 borderDistance

Type: float

Default: 0

Effect unknown ...

=head2 autoSizePolicy

Type: descrete values ( content | node_size | node_height | node_width )

Default: 'content'

The way to automatically determine the Labels C<height> and/or C<witdh>.

=head2 cropping

Type: bool

Default: false

Whether to wrap the text at Node boundaries (true) or let it emerge (false).

=head1 SUBROUTINES/METHODS

=head2 all functions from base class

L<yEd::Label>

=cut

my $modellmatch = '^(?:free|internal-(?:c|t|b|l|r|tl|tr|bl|br)|corners-(?:nw|ne|se|sw)|sandwich-(?:n|s)|sides-(?:n|s|w|e)|eight_pos-(?:n|s|e|w|nw|ne|sw|se)|edge_opposite)$';

sub new {
    my ($class, @args) = @_;
    my $self = bless {}, $class;
    return $self->_init(@args);
}

sub _init {
    my ($self, @args) = @_;
    $self->borderDistance(0);
    $self->cropping(0);
    $self->autoSizePolicy('content');
    $self->positionModell('internal-c');
    $self->SUPER::_init(@args);
    return $self;
}

sub positionModell {
    return _PROPERTY($modellmatch, @_);
}
sub borderDistance {
    return _PROPERTY($match{'float'}, @_);
}
sub autoSizePolicy {
    return _PROPERTY($match{'autosizepolicy'}, @_);
}
sub cropping {
    return _PROPERTY('bool', @_);
}

sub _build {
    my $self = shift;
    my $node = XML::LibXML::Element->new('y:NodeLabel');
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
    # NodeLabel
    if ($self->positionModell() eq 'free') {
        $node->setAttribute('modelName', $self->positionModell());
        $node->setAttribute('modelPosition', 'anywhere');
    } elsif ($self->positionModell() eq 'edge_opposite') {
        $node->setAttribute('modelName', $self->positionModell());
    } else {
        my ($m, $p) = split '-', $self->positionModell();
        $node->setAttribute('modelName', $m);
        $node->setAttribute('modelPosition', $p);
    }
    $node->setAttribute('autoSizePolicy', $self->autoSizePolicy());
    $node->setAttribute('borderDistance', $self->borderDistance()) unless ($self->borderDistance() =~ m/^-?0*\.?0*$/);
    $node->setAttribute('configuration', 'CroppingLabel') if $self->cropping();
    return $node;
}

=head1 SEE ALSO

L<yEd::Document> for further informations about the whole package

L<yEd::PropertyBasedObject> for further basic information about properties and their additional functions

L<yEd::Label> for information about the Label base class

L<yEd::Label::EdgeLabel> for information about specialized Label elements for Edges

=cut

1;
