package yEd::Label;

use strict;
use XML::LibXML;
use yEd::PropertyBasedObject;
use Carp;

=head1 NAME

yEd::Label - Textlabels for Nodes and Edges

=head1 DESCRIPTION

This is the base class for Labels. 
It may not be instanciated, instead use one of the specialized types:

=over 4

=item *

L<yEd::Label::EdgeLabel> Label for Edges, see documentation for additional EdgeLabel properties

=item *

L<yEd::Label::NodeLabel> Label for Nodes, see documentation for additional NodeLabel properties

=back

Have a look at the C<addNewLabel()> function of L<yEd::Node> and L<yEd::Edge>, it is the preferred way to create Labels.

For saving Label templates see L<yEd::Document>'s C<addNewLabelTemplate()>, C<getTemplateLabel()> and the related functions.

=head1 SUPPORTED FEATURES

Labels are supported for both, Nodes and Edges.
However there are some features which are currently not supported:

=over 4

=item *

Smart Label positioning: Because it offers few advantages over the other positioning modells and is much more complex to implement.

=item *

configuration of the Preferred Placement Descriptors: As they seem to only have an effect on Smart Labels (and do only exist for Labels on Edges).

=item *

SVG content (icons) for Labels 

=back

All other features of Labels (yEd Version 3.13) are supported.

For the available positioning modells see the documentation of the specialized Labels.

Other than in yEd itself you may add more than one Label to a single Node or Edge, regardless of its type.
In fact some special Nodes in yEd have multiple Labels per default (e.g. tables), so yEd will handle this correctly.

=head1 PROPERTIES

=head2 text

Type: anything

Default: ... must be supplied

The text to be displayed by the Label.

If it is a blessed ref it will try to find a C<toString()> or C<to_string()> method with the fallback of standard perl stringification.

If it is an array ref each entry will be treated as a line of text.

If it is a hash ref its content will be formated like so:

    key1:        value
    key2:        val2
    another key: val3

Use a monospace font and left alignment (e.g. 'alignment' => 'left', 'fontFamily' => 'Monospaced') for hashes.
Output will be sorted by keys, you can make your keys like _01_keyfirst , _02_keysecond, ... to order them (the ^_\d+_ portion will be removed for printing).

Also see the C<getTextString()> function which returns this property as the printed text.

=head2 visible

Type: bool

Default: true

Whether the Label is visible or not (rather useless).

=head2 x

Type: float

Default: 0

The x position of the Label (ignored in most positioning modells).

=head2 y

Type: float

Default: 0

The y position of the Label (ignored in most positioning modells).

=head2 height

Type: ufloat

Default: 20

The height of the Label (mostly ignored depending on autoSizePolicy).

=head2 width 

Type: ufloat

Default: 30

The width of the Label (mostly ignored depending on autoSizePolicy).

=head2 backgroundColor

Type: '#0000fa' (rgb) or '#000000cc' (rgb + transparency) java.awt.Color hex form or 'none'

Default: 'none'

The background color of the Label.

=head2 lineColor

Type: '#0000fa' (rgb) or '#000000cc' (rgb + transparency) java.awt.Color hex form or 'none'

Default: 'none'

The border color of the Label.

=head2 bottomInset

Type: uint

Default: 0

The bottom inset between Label border and text.

=head2 topInset

Type: uint

Default: 0

The top inset between Label border and text.

=head2 leftInset

Type: uint

Default: 0

The left inset between Label border and text.

=head2 rightInset

Type: uint

Default: 0

The right inset between Label border and text.

=head2 rotationAngle

Type: float

Default: 0

Rotation of the whole Label.

=head2 alignment

Type: descrete values ( center | right | left )

Default: 'center'

The text alignment.

=head2 fontFamily

Type: Fontstring

Default: 'Dialog'

The font for the Label text.

As fonts differ on systems and platforms, this is not a descrete values property, be sure to choose a proper value (e.g. look into a yEd created graphml).
The default font 'Dialog' seems to be always present.

=head2 fontSize

Type: uint

Default: 12

The font size.

=head2 fontStyle

Type: descrete values ( plain | bold | italic | bolditalic )

Default: 'plain'

The font style.

=head2 textColor

Type: '#0000fa' (rgb) or '#000000cc' (rgb + transparency) java.awt.Color hex form or 'none'

Default: '#000000'

The text color.

=head2 underlinedText

Type: bool

Default: false

Whether the text is underlined or not.

=head1 SUBROUTINES/METHODS

=head2 new

Creates a new instance of a Label typ type.

A value for the C<text> property must be provided as first parameter.

Further parameters to set properties are optional (C<property1 =E<gt> value, property2 =E<gt> value2, ...>).

=head3 EXAMPLE

    my $label = yEd::Label::NodeLabel->new('hello world', 'underlinedText' => 1, 'textColor' => '#ff0000');

=cut

sub new {
    confess 'you may not instantiate a yEd::Label base class object';    
}

=head2 copy

Creates a copy of this Label and returns it.

You may optionally specify properties in the form C<property1 =E<gt> value, property2 =E<gt> value2, ...> to change these properties for the returned copy.

=head3 EXAMPLE

    my $newlabel = $label->copy();
    my $newlabel2 = $label->copy('text' => 'my new text');

=cut

sub copy {
    my ($self, @p) = @_;
    my $ref = ref $self;
    my $o = $ref->new();
    $o->setProperties($self->getProperties());
    $o->setProperties(@p);
    return $o;
}

sub _init {
    my ($self, $text, @properties) = @_;
    $self->text($text);
    # defaults
    $self->x(0);
    $self->y(0);
    $self->height(20);
    $self->width(30);
    $self->alignment('center');
    $self->fontFamily('Dialog');
    $self->fontSize(12);
    $self->fontStyle('plain');
    $self->textColor('#000000');
    $self->visible(1);
    $self->backgroundColor('none');
    $self->lineColor('none');
    $self->underlinedText(0);
    $self->allInsets(0);
    $self->rotationAngle(0);
    # user values
    $self->setProperties(@properties);
    return $self;
}

sub text {
    return _PROPERTY(0, @_);
} 

=head2 getTextString

While the C<text> property will return the set value (which may be a ref), this will return the text form of the property as it will be shown in yEd.

Have a look at the C<text> property description for details.

=head3 EXAMPLE

    print $label->getTextString();

=cut

my @knownStringifier = ('toString', 'to_String');
sub getTextString {
    my $self = shift;
    my $text = $self->text();
    my $ref = ref $text;
    if ($ref) {
        if ($ref eq 'ARRAY') {
            return join "\n", @{$text};
        } elsif (UNIVERSAL::isa($text,'UNIVERSAL')) {
            foreach my $toStr (@knownStringifier) {
                return $text->$toStr() if $text->can($toStr);
                $toStr = lc $toStr;
                return $text->$toStr() if $text->can($toStr);
            }
        } elsif ($ref eq 'HASH') {
            my @keys = sort keys %{$text};
            my $l = 0;
            foreach my $k (@keys) {
                $k =~ m/^(?:_\d+_)?(.*)$/;
                $l = length($1) if (length($1) > $l);
            }
            $l++;
            my $t = '';
            foreach my $k (@keys) {
                $k =~ m/^(?:_\d+_)?(.*)$/;
                $t .= sprintf("%-${l}s %s\n", $1 . ':', $text->{$k});
            }
            return $t;
        }
    }
    return "$text"; # stringify everthing else by using perl defaults
}

# Labelarea
sub visible {
    return _PROPERTY('bool', @_);
}
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
sub backgroundColor {
    return _PROPERTY($match{'color'}, @_);
}
sub lineColor {
    return _PROPERTY($match{'color'}, @_);
}
sub bottomInset {
    return _PROPERTY($match{'uint'}, @_);
} 
sub leftInset {
    return _PROPERTY($match{'uint'}, @_);
} 
sub rightInset {
    return _PROPERTY($match{'uint'}, @_);
} 
sub topInset {
    return _PROPERTY($match{'uint'}, @_);
} 

=head2 allInsets

This is an alternative setter for the C<inset...> properties.

It takes one or two parameters, where the first one will set bottom and top (or all insets if there is no second parameter) and the second will set left and right.

=head3 EXAMPLE

    $label->allInsets(10);
    $label->allInsets(4, 8);

=cut

sub allInsets {
    my ($self, $i1, $i2) = @_;
    confess 'allInsets will only set insets, specify 1 or 2 args (top/bottom , left/right)' unless (defined $i1);
    $i2 = $i1 unless (defined $i2);
    $self->bottomInset($i1);
    $self->topInset($i1);
    $self->rightInset($i2);
    $self->leftInset($i2);
    return;
}
sub rotationAngle {
    return _PROPERTY($match{'float'}, @_);
}

# Font
sub alignment {
    return _PROPERTY($match{'alignment'}, @_);
} 
sub fontFamily {
    return _PROPERTY(0, @_);
} 
sub fontSize {
    return _PROPERTY($match{'uint'}, @_);
} 
sub fontStyle {
    return _PROPERTY($match{'fontstyle'}, @_);
} 
sub textColor {
    return _PROPERTY($match{'color'}, @_);
} 
sub underlinedText {
    return _PROPERTY('bool', @_);
} 

sub _build {
    confess 'you may not build a yEd::Label base class object, override this method in a specialized subclass';    
}

=head2 setProperties getProperties hasProperties

As described at L<yEd::PropertyBasedObject>

=head1 SEE ALSO

L<yEd::Document> for further informations about the whole package

L<yEd::PropertyBasedObject> for further basic information about properties and their additional functions

L<yEd::Label::EdgeLabel> for information about specialized Label elements for Edges

L<yEd::Label::NodeLabel> for information about specialized Label elements for Nodes

=cut


1;
