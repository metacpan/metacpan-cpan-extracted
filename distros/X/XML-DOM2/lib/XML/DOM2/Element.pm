package XML::DOM2::Element;

use strict;
use warnings;

=head1 NAME

  XML::DOM2::Element - XML Element level control

=head1 DISCRIPTION

  Element base class represents an element at the XML level.
  More specific element classes control the xml functionality which is abstracted from the xml.

=head1 METHODS

=cut

use base "XML::DOM2::DOM::Element";
use Carp;

use XML::DOM2::Attribute;
use XML::DOM2::Element::CDATA;

=head2 $element->new( $name, %options )

  Create a new element object.

=cut
sub new
{
    my ($proto, $name, %opts) = @_;
	my $class = ref($proto) || $proto;

	my $self = bless \%opts, $class;
    $self->{'name'} = $name;

    return $self;
}

=head2 $element->xmlify()

  Returns the element and all it's sub elements as a serialised xml string (serialisation)

=cut
sub xmlify
{
	my ($self, %p) = @_;
	my ($ns, $indent, $level, $sep) = @p{qw/namespace indent level seperator/};

	$indent = '  ' if not $indent;
	$level = 0 if not $level;

	my $xml = $sep;

	$xml .= $indent x $level;

	if($self->hasChildren or $self->hasCDATA) {
		$xml .= $self->_serialise_open_tag($ns);
		if($self->hasChildren()) {
			foreach my $child ($self->getChildren) {
				$xml .= $child->xmlify(
						indent    => $indent,
						level     => $level+1,
						seperator => $sep,
					);
			}
			$xml .= $sep.($indent x $level);
		} else {
			$xml .= $self->cdata->text();
		}
		$xml .= $self->_serialise_close_tag();
	} else {
		$xml .= $self->_serialise_tag();
	}
	return $xml;
}

=head2 $element->_element_handle()

Inherited method, returns element which is the specific kind
of child object required for this element.

=cut
sub _element_handle
{
	my ($self, $name, %opts) = @_;
	if(defined($self->getParent)) {
		$self->getParent->_element_handle($name, %opts);
	} elsif($self->document) {
		$self->document->createElement($name, %opts);
	} else {
		croak "Unable to create element, no document or parent node to create against";
	}
}

=head2 $element->_attribute_handle()

Inherited method, returns attribute as new object or undef.

$attribute = $element->_attribute_handle( $attribute_name, $ns );

Used by XML::DOM2::DOM for auto attribute object handlers.

=cut
sub _attribute_handle
{
	my ($self, $name, %opts) = @_;
	return XML::DOM2::Attribute->new( name => $name, owner => $self, %opts );
}

=head2 $element->_has_attribute()

Inherited method, returns true if attribute has an object.

Used by XML::DOM2::DOM for auto attribute object handlers.

=cut
sub _has_attribute { 1 }

=head2 $element->_can_contain_elements()

  Inherited method, returns true if the element can contain sub elements

=cut
sub _can_contain_elements { 1 }


=head2 $element->_can_contain_attributes()

  Inherited method, returns true if the element can have attributes.

=cut
sub _can_contain_attributes { 1 }

=head2 $element->_serialise_open_tag()

  XML ELement serialisation, Open Tag.

=cut
sub _serialise_open_tag
{
	my ($self) = @_;
	my $name = $self->name();
	my $at = $self->hasAttributes() ? ' '.$self->_serialise_attributes() : '';
	return '' if not defined $name;
	return "<$name$at>";
}

=head2 $element->_serialise_tag()

  XML ELement serialisation, Self contained tag.

=cut
sub _serialise_tag
{
	my ($self) = @_;
	my $name = $self->name();
	my $at= $self->hasAttributes ? ' '.$self->_serialise_attributes : '';
	return "<$name$at \/>";
}

=head2 $element->_serialise_close_tag()

  XML ELement serialisation, Close Tag.

=cut
sub _serialise_close_tag
{
	my ($self) = @_;
	my $name = $self->name();
	return "</$name>";
}

=head2 $element->_serialise_attributes()

  XML ELement serialisation, Attributes.

=cut
sub _serialise_attributes
{
    my ($self) = @_;
    return $self->getAttributes(3);
}

=head2 $element->error( $command, $error )

  Raise an error.

=cut
sub error ($$$) {
    my ($self,$command,$error)=@_;
	confess "Error requires both command and error" if not $command or not $error;
	if($self->document) {
		if ($self->document->{-raiseerror}) {
			die "$command: $error\n";
		} elsif ($self->document->{-printerror}) {
			print STDERR "$command: $error\n";
		}
	}

    $self->{errors}{$command}=$error;
}

=head1 OVERLOADED

=head2 $object->auto_string()

=cut
sub auto_string { return $_[0]->hasCDATA() ? $_[0]->cdata() : '' }

=head2 $object->auto_eq( $string )

=cut
sub auto_eq { return shift->auto_string() eq shift }

=head2 BEGIN()

  POD Catch, imagened method.

=head1 AUTHOR

  Martin Owens <doctormo@cpan.org> (Fork)
  Ronan Oger <ronan@roasp.com>

=head1 SEE ALSO

  perl(1),L<XML::DOM2>,L<XML::DOM2::Parser>

=cut
1;
