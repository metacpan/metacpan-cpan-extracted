package XML::DOM2::DOM::NameSpace;

=head1 NAME

  XML::DOM2::DOM::NameSpace

=head1 DESCRIPTION

  NameSpace base class for all attributes and elements

=head1 METHODS

=cut

use strict;
use Carp;

=head2 $element->name()

  Returns the attributes full name with namespace prefix.

=cut
sub name
{
	my ($self) = @_;
	my $prefix = $self->prefix;
	return ($prefix ? $prefix.':' : '').$self->localName;
}

=head2 $element->localName()

  Returns the attribute name without name space prefix.

=cut
sub localName
{
	my ($self) = @_;
	confess "Does not have a self object for some reason\n" if not $self;
	return $self->{'name'};
}

=head2 $element->namespaceURI()

  Returns the URI of the attributes namespace.

=cut
sub namespaceURI
{
	my ($self) = @_;
	return if not $self->namespace;
	return $self->namespace->ns_uri;
}

=head2 $element->prefix()

  Returns the attributes namespace prefix, returns undef if the namespace is the same as the owning element.

=cut 
sub prefix
{
	my ($self) = @_;
	return if not $self->namespace;
	if(not ref($self->namespace)) {
		warn "This name space is not right, I'd find out what gave it to you if I were you ".$self->namespace.':'.$self->localName.':'.$self." \n";
		return;
	}
	return $self->namespace->ns_prefix;
}

=head2 $element->namespace()

  Return the namespace string this element or attribute belongs to.

=cut
sub namespace
{
	my ($self) = @_;
	return $self->{'namespace'};
}

=head1 COPYRIGHT

Martin Owens, doctormo@cpan.org

=head1 SEE ALSO

L<XML::DOM2>

=cut
1;
