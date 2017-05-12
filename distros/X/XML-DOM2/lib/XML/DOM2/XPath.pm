package XML::DOM2::XPath;

use strict;
use Carp;

our $VERSION = '0.01';

=pod

=head1 NAME

XML::DOM2::XPath

=head1 DESCRIPTION

Provides the required methods for XPath

=head1 TODO

see http://www.w3.org/TR/xpath

=head1 METHODS
=cut

=head2 getElementByXPath

Returns an element by XPath, This is still under development not
all xpath rules may work correctly.

$element->getElementByXPath('/Blah/Foo/Bar');

=cut
sub getElementByXPath
{
	my ($self, $path) = @_;
	# Remove double directories, prevents repathing to root
	$path =~ s/\/\//\// if not ref($path);
	# Aquire Next steps in Path
	my @path = ref($path) ? @{$path} : split(/\//, $path);
	return if not @path;
	my $this = shift @path;
	my $next;
	if($this eq '') {
		# Root Document
		push @next, $self->document->documentElement;
	} elsif($this eq '..') {
		# Parent Element or self (top level reached)
		push @next, $self->getParent ? $self->getParent : $self;
	} elsif($this eq '.') {
		# Current Element (this is almost useless)
		push @next, $self;
	} else {
		# Return Children with this name
		@next = $self->getChildrenByName( $this );
	}
	return @next if not @path;
	return map { $_->getElementByXPath( \@path ) }, @next;
}

=head1 AUTHOR

Martin Owens, doctormo@postmaster.co.uk

=head1 SEE ALSO

perl(1), L<XML::DOM2>, L<XML::DOM2::Element>

L<http://www.w3.org/TR/1998/REC-DOM-Level-1-19981001/level-one-core.html> DOM at the W3C

=cut

return 1;
