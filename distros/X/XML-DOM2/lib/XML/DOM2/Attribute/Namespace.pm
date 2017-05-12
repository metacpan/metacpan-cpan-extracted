package XML::DOM2::Attribute::Namespace;

=head1 NAME

  XML::DOM2::Attribute::Namespace

=head1 DESCRIPTION

  Attribute Namespace object class

=head1 METHODS

=cut

use base "XML::DOM2::Attribute";

use strict;
use warnings;
use Carp;

=head2 $class->new( %arguments )

  Create a new attribute namespace object.

=cut
sub new
{
	my ($proto, %opts) = @_;
	return $proto->SUPER::new(%opts);
}

=head2 $class->serialise()

  Format and return xml text serialised.

=cut
sub serialise
{
	my ($self) = @_;
	my $result = $self->{'value'};
	return $result;
}

=head2 $class->deserialise( $uri )

  Deserialise uri

=cut
sub deserialise
{
	my ($self, $uri) = @_;
	if($self->{'value'}) {
		$self->document->removeNamespace($self);
	}
	$self->{'value'} = $uri;
	$self->document->addNamespace($self);
	if($self->name eq 'xmlns') {
		$self->document->namespace($uri);
	}
	return $self;
}

=head2 $class->ns_prefix()

  Return the namespace prefix.

=cut
sub ns_prefix
{
	my ($self) = @_;
	return $self->localName;
}

=head2 $class->ns_uri()

  Return the namespace uri.

=cut
sub ns_uri
{
	my ($self) = @_;
	return $self->serialise;
}

=head2 $class->delete()

  Remove the namespace from the document.

=cut
sub delete
{
	my ($self) = @_;
	# Make sure we remove this namespace from
	# the document when we remove the namespace attribute
	$self->document->removeNamespace($self);
}

=head1 COPYRIGHT

Martin Owens, doctormo@cpan.org

=head1 SEE ALSO

L<XML::DOM2>,L<XML::DOM2::DOM::Attribute>

=cut
return 1;
