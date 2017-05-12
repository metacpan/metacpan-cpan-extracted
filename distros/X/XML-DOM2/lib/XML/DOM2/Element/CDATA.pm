package XML::DOM2::Element::CDATA;

=head1 NAME

  XML::DOM2::Element::CDATA

=head1 DESCRIPTION

  CDATA Element object class

=head1 METHODS

=cut

use base "XML::DOM2::Element";

use strict;
use warnings;

use overload
	'""' => sub { shift->auto_string( @_ ) },
	'eq' => sub { shift->auto_eq( @_ ) },
	'ne' => sub { not shift->auto_eq( @_ ) };

=head2 $class->new( $text, %arguments )

  Create a new cdata object.

=cut
sub new
{
	my ($proto, $text, %args) = @_;
	$args{'text'} = $text;
	my $self = $proto->SUPER::new('cdata', %args);
	return $self;
}

=head2 $element->xmlify()

  Returns the text as a serialised xml string (serialisation)

=cut
sub xmlify
{
	my ($self, %p) = @_;
	my $sep = $p{'seperator'};
	my $text = $self->text();
	if($self->{'notag'}) {
		return $sep.'<![CDATA['.$text.']]>'.$sep;
	} elsif($self->{'noescape'}) {
		return $text;
	}
	return $text;
}

=head2 $element->text()

  Return plain text (UTF-8)

=cut
sub text
{
	my ($self) = @_;
	return $self->{'text'};
}

=head2 $element->setData( $text )

  Replace text data with $text.

=cut
sub setData
{
	my ($self, $text) = @_;
	$self->{'text'} = $text;
}

=head2 $element->appendData( $text )

  Append to the end of the data $text.

=cut
sub appendData
{
	my ($self, $text) = @_;
	$self->{'text'} .= $text;
}

=head2 $element->_can_contain_elements()

  The element can not contain sub elements.

=cut
sub _can_contain_elements { 0 }

=head2 $element->_can_contain_attributes()

  The element can not contain attributes

=cut
sub _can_contain_attributes { 0 }

=head1 OVERLOADED

=head2 $object->auto_string()

=cut
sub auto_string { return shift->text() }

=head2 $object->auto_eq( $string )

=cut
sub auto_eq { return shift->text() eq shift }

=head1 COPYRIGHT

Martin Owens, doctormo@cpan.org

=head1 SEE ALSO

L<XML::DOM2>,L<XML::DOM2::DOM::Element>

=cut
1;
