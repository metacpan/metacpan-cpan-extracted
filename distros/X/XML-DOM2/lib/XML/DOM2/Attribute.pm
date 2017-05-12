package XML::DOM2::Attribute;

=head1 NAME

  XML::DOM2::Attribute

=head1 DESCRIPTION

  Attribute object class for XML documents

=head1 METHODS

=cut

use base "XML::DOM2::DOM::Attribute";

use strict;
use warnings;
use Carp;

use overload
	'""' => sub { shift->auto_string( @_ ) },
	'eq' => sub { shift->auto_eq( @_ ) },
	'ne' => sub { not shift->auto_eq( @_ ) };

=head2 $class->new( %options )

  Create a new Attribute object.

=cut
sub new
{
	my ($proto, %opts) = @_;
	croak "Attribute must have a name!" if not $opts{'name'};
	croak "Attribute must have an owner" if not $opts{'owner'};
	my $value = delete($opts{'value'});
	my $self = bless \%opts, $proto;
	$self->deserialise( $value ) if defined($value);
	return $self;
}

=head2 $attribute->value()

  Returns the serialised value within this attribute.

=cut
sub value
{
	my ($self) = @_;
	return $self->serialise;
}

=head2 $attribute->serialise()

  Returns the serialised value for this attribute.

=cut
sub serialise
{
	my ($self) = @_;
	return $self->{'value'};
}

=head2 $attribute->deserialise( $value )

  Sets the attribute value to $value, does any deserialisation too.

=cut
sub deserialise
{
	my ($self, $value) = @_;
	$self->{'value'} = $value;
}

=head2 $attribute->serialise_full()

  Returns the serialised name and value for this attribute.

=cut
sub serialise_full
{
	my ($self) = @_;
	my $value = $self->value;
	$value = '~undef~' if not defined($value);
	return $self->name.'="'.$value.'"';
} 

=head2 $attribute->document()

  Return the document associated with this attribute.

=cut
sub document
{
	my ($self) = @_;
	warn "No owner element\n" if not $self->ownerElement;
	return undef if not $self->ownerElement;
	return $self->ownerElement->document;
}

=head2 $attribute->delete()

  Delete this attribute, NOT IMPLIMENTED.

=cut
sub delete {}

=head1 OVERLOADED

=head2 $object->auto_string()

=cut
sub auto_string { return shift->value() }

=head2 $object->auto_eq( $string )

=cut
sub auto_eq { return shift->value() eq shift }

=head1 COPYRIGHT

Martin Owens, doctormo@cpan.org

=head1 SEE ALSO

L<XML::DOM2>,L<XML::DOM2::DOM::Attribute>

=cut
1;
