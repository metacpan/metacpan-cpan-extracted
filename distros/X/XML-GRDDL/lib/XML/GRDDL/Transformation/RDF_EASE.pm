package XML::GRDDL::Transformation::RDF_EASE;

use 5.008;
use strict;
use base qw[XML::GRDDL::Transformation];

use Scalar::Util qw[blessed];
use XML::GRDDL::Transformation::RDF_EASE::Functional qw[:standard];

our $VERSION = '0.004';

sub transform
{
	my ($self, $input) = @_;
	
	if (blessed($input) && $input->isa('XML::LibXML::Document'))
	{
		$input = $input->toString;
	}
	
	my $rdfa = &rdfease_to_rdfa($self->response->decoded_content, $input);

	return ($rdfa, 'application/xhtml+xml') if wantarray;
	return $rdfa;
}

sub model
{
	my ($self, $input) = @_;
	
	if (blessed($input) && $input->isa('XML::LibXML::Document'))
	{
		$input = $input->toString;
	}
	
	my $rdfa = &rdfease_to_rdfa($self->response->decoded_content, $input);
	return $self->{grddl}->_rdf_model($rdfa, $self->{referer}, 'application/xhtml+xml', 1);
}

1;

__END__

=head1 NAME

XML::GRDDL::Transformation::RDF_EASE - represents an RDF-EASE transformation

=head1 DESCRIPTION

Implements RDF-EASE transformations.

=head1 SEE ALSO

L<XML::GRDDL>, L<XML::GRDDL::Transformation>.

A standalone RDF-EASE implementation can be found in
L<XML::GRDDL::Transformation::RDF_EASE::Functional>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2008-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
