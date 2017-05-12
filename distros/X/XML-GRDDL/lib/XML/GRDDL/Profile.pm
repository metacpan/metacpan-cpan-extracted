package XML::GRDDL::Profile;

use 5.008;
use strict;
use base qw[XML::GRDDL::External];

use RDF::Trine qw[iri];
use Scalar::Util qw[blessed];

our $VERSION = '0.004';

# hard-code certain profiles to skip...
our @ignore = (
	'http://www.w3.org/1999/xhtml/vocab',
	'http://www.w3.org/1999/xhtml/vocab#',
	'http://www.w3.org/2003/g/data-view',
	'http://www.w3.org/2003/g/data-view#',
	qr{^http://microformats\.org/profile/},
	qr{^http://ufs\.cc/x/},
	);

# skip profile fetch...
our %hard_coded = (
	'http://dublincore.org/documents/dcq-html/'
		=> ['http://www.w3.org/2000/06/dc-extract/dc-extract.xsl'],
	'http://dublincore.org/documents/2008/08/04/dc-html/'
		=> ['http://dublincore.org/transform/dc-html-20080804-grddl/dc-html2rdfxml.xsl'],
	'http://purl.org/NET/erdf/profile'
		=> ['http://purl.org/NET/erdf/extract-rdf.xsl'],
	'http://purl.org/stuff/glink/'
		=> ['http://danja.talis.com/glink/groklinks.xsl'],
	'http://www.w3.org/2002/12/cal/hcal'
		=> ['http://www.w3.org/2002/12/cal/glean-hcal.xsl'],
	'http://www.w3.org/2006/03/hcard'
		=> ['http://www.w3.org/2006/vcard/hcard2rdf.xsl'],
	'http://www.purl.org/stuff/rev'
		=> ['http://danja.talis.com/xmlns/rev_2007-11-09/hreview2rdfxml.xsl'],
	'http://purl.org/net/ns/metaprof'
		=> ['http://www.kanzaki.com/parts/xh2rdf.xsl'],
	'http://ns.inria.fr/grddl/rdfa/'
		=> ['http://ns.inria.fr/grddl/rdfa/2008/09/03/RDFa2RDFXML.xsl'],
	'http://www.w3.org/2000/08/w3c-synd/'
		=> ['http://www.w3.org/2000/08/w3c-synd/home2rss.xsl'],
	);

sub ignore
{
	my ($class) = @_;
	return @ignore;
}

sub transformations
{
	my ($self) = @_;
	
	if (defined $hard_coded{ $self->{uri} })
	{
		return @{ $hard_coded{ $self->{uri} } };
	}
	
	my $response = $self->{grddl}->_fetch(
		$self->{uri},
		Referer  => $self->{referer},
		Accept   => 'application/xhtml+xml, text/html, application/rdf+xml, text/turtle, application/xml;q=0.1, text/xml;q=0.1, */*;q=0.01',
		);
		
	my ($model, @transformations);
	$model = $self->{grddl}->_rdf_model($response->decoded_content, $response->base, $response->content_type);

	return
		unless blessed($model)
		&& $model->can('count_statements')
		&& $model->count_statements;

	my $iter = $model->get_statements(
		iri($self->{uri}),
		iri(XML::GRDDL::GRDDL_NS.'profileTransformation'),
		undef);
	while (my $st = $iter->next)
	{
		next unless $st->object->is_resource;
		push @transformations, $st->object->uri;
	}
	
	return @transformations;
}

1;

__END__

=head1 NAME

XML::GRDDL::Profile - represents a profile URI

=head1 DESCRIPTION

This module is used internally by XML::GRDDL and you probably don't want to mess with it.

C<< @XML::GRDDL::Profile::ignore >> is an array of strings and regular expressions
for matching profile URIs that should be ignored. You can fiddle with it, but it voids
your warranty.

The ignore list currently consists of the RDFa profile, the GRDDL profile itself, and regular
expressions matching profiles that start 'http://purl.org/uF/', 'http://microformats.org/profile/'
and 'http://ufs.cc/x/'.

Profile documents many be written in any format supported by
RDF::RDFa::Parser or RDF::Trine::Parser, including RDF/XML, Turtle
and XHTML+RDFa.

=head1 SEE ALSO

L<XML::GRDDL>.

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
