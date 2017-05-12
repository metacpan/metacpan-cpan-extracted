package XML::GRDDL;

use 5.008;
use strict;
use constant GRDDL_NS  => 'http://www.w3.org/2003/g/data-view#';
use constant XHTML_NS  => 'http://www.w3.org/1999/xhtml';

use Carp;
use Data::UUID;
use RDF::RDFa::Parser '1.097';
use RDF::Trine qw[iri statement];
use Scalar::Util qw[blessed];
use URI;
use URI::Escape qw[uri_escape];
use XML::GRDDL::Namespace;
use XML::GRDDL::Profile;
use XML::GRDDL::Transformation;
use XML::LibXML;

our $VERSION = '0.004';

use base 'Exporter';
our @EXPORT_OK = qw( GRDDL_NS XHTML_NS );

sub new
{
	my ($class) = @_;
	return bless { cache=>{}, ua=>undef, }, $class;
}

sub ua
{
	my $self = shift;
	if (@_)
	{
		my $rv = $self->{'ua'};
		$self->{'ua'} = shift;
		croak "Set UA to something that is not an LWP::UserAgent!"
			unless blessed $self->{'ua'} && $self->{'ua'}->isa('LWP::UserAgent');
		return $rv;
	}
	unless (blessed $self->{'ua'} && $self->{'ua'}->isa('LWP::UserAgent'))
	{
		$self->{'ua'} = LWP::UserAgent->new(agent=>sprintf('%s/%s ', __PACKAGE__, $VERSION));
	}
	return $self->{'ua'};
}

sub data
{
	my ($self, $document, $uri, %options) = @_;
	
	unless (blessed($document) && $document->isa('XML::LibXML::Document'))
	{
		my $parser = XML::LibXML->new;
		$document = $parser->parse_string($document);
	}
	
	my $model = RDF::Trine::Model->temporary_model;
	my @transformations = $self->discover($document, $uri, %options, strings => 0);

	foreach my $t (@transformations)
	{
		my $m = $t->model($document);
		if ($m)
		{
			my $context  = iri('urn:uuid:'.Data::UUID->new->create_str);
			my $rootnode = iri('urn:uuid:'.Data::UUID->new->create_str);
			my $property = iri('http://ontologi.es/grddl?transformation='.uri_escape($t->uri).'#result');
			$model->add_hashref($m->as_hashref, $context);
			
			if ($options{metadata})
			{
				$model->add_statement(statement(
					iri($uri),
					iri('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
					iri(GRDDL_NS.'InformationResource'),
					));
				$model->add_statement(statement(
					iri($uri),
					iri(GRDDL_NS.'rootNode'),
					$rootnode,
					));
				$model->add_statement(statement(
					$rootnode,
					iri('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
					iri(GRDDL_NS.'RootNode'),
					));
				$model->add_statement(statement(
					iri($uri),
					iri(GRDDL_NS.'result'),
					$context,
					));
				$model->add_statement(statement(
					$context,
					iri('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
					iri(GRDDL_NS.'RDFGraph'),
					));
				$model->add_statement(statement(
					iri($t->uri),
					iri('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
					iri(GRDDL_NS.'Transformation'),
					));
				$model->add_statement(statement(
					iri($t->uri),
					iri(GRDDL_NS.'transformationProperty'),
					$property,
					));
				$model->add_statement(statement(
					$property,
					iri('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
					iri(GRDDL_NS.'TransformationProperty'),
					));
				$model->add_statement(statement(
					$rootnode,
					$property,
					$context,
					));
			}
		}
	}
	
	return $model;
}

sub discover
{
	my ($self, $document, $uri, %options) = @_;

	unless (blessed($document) && $document->isa('XML::LibXML::Document'))
	{
		my $parser = XML::LibXML->new;
		$document = $parser->parse_string($document);
	}
	
	my @transformations;

	push @transformations,
		$self->_discover_from_rel_attribute($document, $uri, %options);

	push @transformations,
		$self->_discover_from_transformation_attribute($document, $uri, %options);

	push @transformations,
		$self->_discover_from_profiles($document, $uri, %options);
	
	push @transformations,
		$self->_discover_from_namespace($document, $uri, %options);

	if ($options{'strings'})
	{
		return @transformations;
	}
	else
	{
		return map { XML::GRDDL::Transformation->new($_, $uri, $self); } @transformations;
	}
}

sub _discover_from_rel_attribute
{
	my ($self, $document, $uri, %options) = @_;
	my @transformations;

	my $profile_found = $options{'force_rel'};
	
	my $xpc = XML::LibXML::XPathContext->new;
	$xpc->registerNs(xhtml => XHTML_NS);
	
	unless ($profile_found)
	{
		my @nodes = $xpc->findnodes('/xhtml:html/xhtml:head[@profile]', $document);
		foreach my $head (@nodes)
		{
			if ($head->getAttribute('profile') =~ m!(^|\s) http://www\.w3\.org/2003/g/data-view\#? (\s|$)!x)
			{
				$profile_found = 1;
				last;
			}
		}
	}
	
	if ($profile_found)
	{
		my $is_html = $document->documentElement->namespaceURI eq XHTML_NS;
		my $rdfa = $self->_rdf_model($document, $uri, $is_html?'application/xhtml+xml':'application/xml');
		my $iter = $rdfa->get_statements(iri($uri), iri(GRDDL_NS.'transformation'), undef);
		while (my $st = $iter->next)
		{
			next unless $st->object->is_resource;
			push @transformations, $st->object->uri;
		}
	}
	
	return @transformations;
}

sub _discover_from_transformation_attribute
{
	my ($self, $document, $uri, %options) = @_;
	my @transformations;

	# Right now just doing this on root element. Supposed to also check others??
	my $attr = $document->documentElement->getAttributeNS(GRDDL_NS, 'transformation');
	my @t = split /\s+/, $attr;
	foreach my $t (@t)
	{
		next unless $t =~ /[a-z0-9\.]/i;
		push @transformations, $self->_resolve_relative_ref($t, $uri);
	}
	
	return @transformations;
}

sub _discover_from_profiles
{
	my ($self, $document, $uri, %options) = @_;
	my @transformations;
	
	my $xpc = XML::LibXML::XPathContext->new;
	$xpc->registerNs(xhtml => XHTML_NS);
		
	my @profiles;
	my @nodes = $xpc->findnodes('/xhtml:html/xhtml:head[@profile]', $document);
	foreach my $head (@nodes)
	{
		my @t = split /\s+/, $head->getAttribute('profile');
		foreach my $t (@t)
		{
			next unless $t =~ /[a-z0-9\.]/i;
			push @profiles, $self->_resolve_relative_ref($t, $uri);
		}		
	}

	foreach my $profile (@profiles)
	{
		my $profile_object = XML::GRDDL::Profile->new($profile, $uri, $self);
		push @transformations, $profile_object->transformations;
	}

	return @transformations;
}

sub _discover_from_namespace
{
	my ($self, $document, $uri, %options) = @_;
	
	my $ns     = $document->documentElement->namespaceURI;
	my $ns_obj = XML::GRDDL::Namespace->new($ns, $uri, $self);
	
	return $ns_obj->transformations;
}

sub _fetch
{
	my ($self, $document, %headers) = @_;
	$self->{'cache'}->{$document} ||= $self->ua->get($document, %headers);
	return $self->{'cache'}->{$document};
}

sub _rdf_model
{
	my ($self, $document, $uri, $type, $nocache) = @_;
	
	if ($nocache || !$self->{'cached-rdf'}->{$uri})
	{
		if ($type eq 'application/xhtml+xml'
		or  $type eq 'text/html'
		or  $type eq 'application/atom+xml'
		or  $type eq 'image/svg+xml')
		{
			my $config = RDF::RDFa::Parser::Config->new(
				$type,
				'1.1',
				initial_context => 'http://www.w3.org/2003/g/data-view',
			);
			my $parser = RDF::RDFa::Parser->new($document, $uri, $config);
			return $parser->graph if $nocache;
			$self->{'cached-rdf'}->{$uri} = $parser->graph;
		}
		else
		{
			if (blessed($document))
			{
				$document = $document->toString;
			}
			my $model  = RDF::Trine::Model->temporary_model;
			my $pclass = $RDF::Trine::Parser::media_types{ $type };
			my $parser = ($pclass && $pclass->can('new'))
			           ? $pclass->new
			           : RDF::Trine::Parser::RDFXML->new;
			$parser->parse_into_model($uri, $document, $model);
			return $model if $nocache;
			$self->{'cached-rdf'}->{$uri} = $model;
		}
	}
	
	return $self->{'cached-rdf'}->{$uri};
}

sub _resolve_relative_ref
{
	my ($self, $ref, $base) = @_;

	return $ref unless $base; # keep relative unless we have a base URI

	if ($ref =~ /^([a-z][a-z0-9\+\.\-]*)\:/i)
	{
		return $ref; # already an absolute reference
	}

	# create absolute URI
	my $abs = URI->new_abs($ref, $base)->canonical->as_string;

	while ($abs =~ m!^(http://.*)(\.\./|\.)+(\.\.|\.)?$!i)
		{ $abs = $1; } # fix edge case of 'http://example.com/../../../'

	return $abs;
}

1;

__END__

=head1 NAME

XML::GRDDL - transform XML and XHTML to RDF

=head1 SYNOPSIS

High-level interface:

 my $grddl = XML::GRDDL->new;
 my $model = $grddl->data($xmldoc, $baseuri);
 # $model is an RDF::Trine::Model

Low-level interface:

 my $grddl = XML::GRDDL->new;
 my @transformations = $grddl->discover($xmldoc, $baseuri);
 foreach my $t (@transformations)
 {
   # $t is an XML::GRDDL::Transformation
   my ($output, $mediatype) = $t->transform($xmldoc);
   # $output is a string of type $mediatype.
 }

=head1 DESCRIPTION

GRDDL is a W3C Recommendation for extracting RDF data from arbitrary
XML and XHTML via a transformation, typically written in XSLT. See
L<http://www.w3.org/TR/grddl/> for more details.

This module implements GRDDL in Perl. It offers both a low level interface,
allowing you to generate a list of transformations associated with the
document being processed, and thus the ability to selectively run the
transformation; and a high-level interface where a single RDF model
is returned representing the union of the RDF graphs generated by
applying all available transformations.

=head2 Constructor

=over 4

=item C<< XML::GRDDL->new >>

The constructor accepts no parameters and returns an XML::GRDDL
object.

=back

=head2 Methods

=over 4

=item C<< $grddl->discover($xml, $base, %options) >>

Processes the document to discover the transformations associated
with it. $xml is the raw XML source of the document, or an
XML::LibXML::Document object. ($xml cannot be "tag soup" HTML,
though you should be able to use L<HTML::HTML5::Parser> to
parse tag soup into an XML::LibXML::Document.) $base is the
base URI for resolving relative references.

Returns a list of L<XML::GRDDL::Transformation> objects.

Options include:

=over 4

=item * B<force_rel> - boolean; interpret XHTML rel="transformation" even in the absence of the GRDDL profile.

=item * B<strings> - boolean; return a list of plain strings instead of blessed objects.

=back

=item C<< $grddl->data($xml, $base, %options) >>

Processes the document, discovers the transformations associated
with it, applies the transformations and merges the results into a
single RDF model. $xml and $base are as per C<discover>.

Returns an RDF::Trine::Model containing the data. Statement contexts
(a.k.a. named graphs / quads) are used to distinguish between data
from the result of each transformation.

Options include:

=over 4

=item * B<force_rel> - boolean; interpret XHTML rel="transformation" even in the absence of the GRDDL profile.

=item * B<metadata> - boolean; include provenance information in the default graph (a.k.a. nil context).

=back

=item C<< $grddl->ua( [$ua] ) >>

Get/set the user agent used for HTTP requests. $ua, if supplied, must be
an LWP::UserAgent.

=back

=head2 Constants

These constants may be exported upon request.

=over

=item C<< GRDDL_NS >>

=item C<< XHTML_NS >>

=back

=head1 FEATURES

XML::GRDDL supports transformations written in XSLT 1.0, and in RDF-EASE.

XML::GRDDL is a good HTTP citizen: Referer headers are included in requests,
and appropriate Accept headers supplied. To be an even better citizen, I
recommend changing the User-Agent header to advertise the name of the
application:

 $grddl->ua->default_header(user_agent => 'MyApp/1.0 ');

Provenance information for GRDDL transformations is returned using the
GRDDL vocabulary at L<http://www.w3.org/2003/g/data-view#>.

Certain XHTML profiles and XML namespaces known not to contain any
transformations, or to contain useless transformations are skipped. See
L<XML::GRDDL::Namespace> and L<XML::GRDDL::Profile> for details. In
particular profiles for RDFa and many Microformats are skipped, as
L<RDF::RDFa::Parser> and L<HTML::Microformats> will typically yield
far superior results.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

Known limitations:

=over 4

=item * Recursive GRDDL doesn't work yet.

That is, the profile documents and namespace documents linked to from
your primary document cannot themselves rely on GRDDL.

=back

=head1 SEE ALSO

L<XML::GRDDL::Transformation>,
L<XML::GRDDL::Namespace>,
L<XML::GRDDL::Profile>,
L<XML::GRDDL::Transformation::RDF_EASE::Functional>,
L<XML::Saxon::XSLT2>.

L<HTML::HTML5::Parser>,
L<RDF::RDFa::Parser>,
L<HTML::Microformats>.

L<JSON::GRDDL>.

L<http://www.w3.org/TR/grddl/>.

L<http://www.perlrdf.org/>.

This module is derived from Swignition L<http://buzzword.org.uk/swignition/>.

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
