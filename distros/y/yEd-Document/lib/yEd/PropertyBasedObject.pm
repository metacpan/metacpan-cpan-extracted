package yEd::PropertyBasedObject;

use strict;
use Carp;
use base qw(Exporter);

=head1 NAME

yEd::PropertyBasedObject - common methods for property based yEd Objects (Nodes,Edges,Labels)

=head1 DESCRIPTION

This module is just a collection of commonly used subroutines for handling property access.

All properties can be accessed by using the property name as a funktion. 
Without any parameters they will act as a getter and as a setter if a value is provided. 
An exception will be thrown if the value is invalid.
All properties will have very similar default values to yEd.

For a list of available properties for each Object have a look at the documentation for

=over 4

=item *

L<yEd::Node>

=item *

L<yEd::Edge>

=item *

L<yEd::Label>

=back

and its subclasses.

=head3 EXAMPLE

    $node->x(3.5);
    $node->fillColor('#cccccc');
    # which is equivalent to:
    $node->setProperties('x' => 3.5, 'fillColor' => '#cccccc');

    my $text = $label->text();

=cut

our @EXPORT = qw(_PROPERTY %match @ignoreProperties setProperties getProperties hasProperties);

our %match = (
    'color' => '^(?:#[0-9a-f]{6}(?:[0-9a-f]{2})?|none)$',
    'uint' => '^\d+$',
    'ufloat' => '^\d+(?:\.\d+)?$',
    'float' => '^-?\d+(?:\.\d+)?$',
    'ratio' => '^(?:1(?:\.0+)?|0(?:\.\d+)?)$',
    'linetype' => '^(?:line|dotted|dashed|dashed_dotted)$',
    'arrowtype' => '^(?:standard|delta|white_delta|diamond|white_diamond|short|plain|concave|convex|circle|transparent_circle|dash|skewed_dash|t_shape|crows_foot_one_mandatory|crows_foot_many_mandatory|crows_foot_one_optional|crows_foot_many_optional|crows_foot_one|crows_foot_many|crows_foot_optional|none)$',
    'alignment' => '^(?:center|right|left)$',
    'fontstyle' => '^(?:plain|bold|italic|bolditalic)$',
    'autosizepolicy' => '^(?:content|node_size|node_height|node_width)$',
    'arctype' => '^(?:fixedRatio|fixedHeight)$',
);

our @ignoreProperties = ( 'id' );

=head1 SUBROUTINES/METHODS

=head2 setProperties

Takes arguments of the form C<property1 =E<gt> value, property2 =E<gt> value2, ...> and sets the provided properties accordingly for the element in which's context this funktion is called.

Properties not provided will be left unchanged. 

=head3 EXAMPLE

    $node->setProperties('fillColor' => '#ffffff', 'borderColor' => 'none');

=cut

sub setProperties {
    my $self = shift;
    my %ignore = map{ $_ => 1 } @ignoreProperties;
    confess 'properties must be supplied as key => value pairs (odd number supplied)' if(@_ % 2);
    my %props = @_;
    foreach my $key (keys %props) {
        unless ($ignore{$key}) {
            confess "no such property: $key" unless ($self->can($key));
            $self->$key($props{$key});
        }
    }
    return;
}

=head2 getProperties

Returns a hash of the properties and their current values for the element in which's context this funktion is called.

=head3 EXAMPLE

    my %properties = $node->getProperties();

=cut

sub getProperties {
    return %{$_[0]->{'properties'}};
}

=head2 hasProperties

Takes arguments of the form C<property1 =E<gt> value, property2 =E<gt> value2, ...>.

Returns true if the element in which's context this funktion is called has all provided properties set to the provided values.

Returns false otherwise or if an invalid property is provided.

=head3 EXAMPLE

    if ($node->hasProperties('fillColor' => '#ffffff', 'borderColor' => 'none')) { ...

=cut

sub hasProperties {
    my $self = shift;
    confess 'properties must be supplied as key => value pairs (odd number supplied)' if(@_ % 2);
    my %props = @_;
    foreach my $key (keys %props) {
        return 0 unless ($self->can($key));
        my $v1 = $self->$key();
        my $v2 = $props{$key};
        if ($v1 =~ m/$match{'float'}/ and $v2 =~ m/$match{'float'}/) {
            return 0 unless ($v1 == $v2);
        } else {
            return 0 unless ($v1 eq $v2);
        }
    }
    return 1;
}

sub _PROPERTY {
    my $ACCESSKEY = (caller(1))[3];
    $ACCESSKEY =~ s/^.*:://;
    my ($writemask, $self, $value) = @_;
    if (defined $value) {
        if ($writemask) {
            if ($writemask eq 'ro') {
                confess "tried to write to a read only property ($ACCESSKEY)";
            } elsif ($writemask eq 'bool') {
                $value = $value ? 1 : 0;
            } elsif ($writemask =~ m/^isa\((.+)\)$/) {
                my $type = $1;
                confess "value for property $ACCESSKEY must be a reference of the type $type (or one of its subtypes) (given value: $value)" unless ($value->isa($type));
            } else {
                confess "value for property $ACCESSKEY doesn't match $writemask (given value: $value)" unless ($value =~ m/$writemask/);
            }
        }
        $self->{'properties'}{$ACCESSKEY} = $value;
        return;
    } else {
        return $self->{'properties'}{$ACCESSKEY};
    }
}

=head1 SEE ALSO

L<yEd::Document> for further informations about the whole package

L<yEd::Node> for information about Node elements

L<yEd::Edge> for information about Edge elements

L<yEd::Label> for information about Label elements

=cut

1;
