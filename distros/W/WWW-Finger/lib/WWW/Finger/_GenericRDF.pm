package WWW::Finger::_GenericRDF;

# Below is not a proper WWW::Finger implementation, but is rather a
# framework which real implementations can hook onto by subclassing.

use 5.010;
use common::sense;
use utf8;

use Digest::SHA 0 qw(sha1_hex);
use HTTP::Link::Parser 0.102 qw();
use LWP::UserAgent 0;
use RDF::Query 2.900;
use RDF::Trine 0.135;

use parent qw(WWW::Finger);

BEGIN {
	$WWW::Finger::_GenericRDF::AUTHORITY = 'cpan:TOBYINK';
	$WWW::Finger::_GenericRDF::VERSION   = '0.105';
}

sub _new_from_response
{
	my $class    = shift;
	my $ident    = shift;
	my $response = shift;
	my $self     = bless {}, $class;
	
	my $model  = RDF::Trine::Model->new( RDF::Trine::Store->temporary_store );
	
	$self->{'ident'} = $ident;
	$self->{'graph'} = $model;
	
	$self->_response_into_model($response);
	
	return $self;
}

sub _response_into_model
{
	my $self     = shift;
	my $response = shift;
	my $parser;
	$parser = RDF::Trine::Parser::Turtle->new  if $response->content_type =~ m`(n3|turtle|text/plain)`;
	$parser = RDF::Trine::Parser::RDFJSON->new if $response->content_type =~ m`(json)`;
	$parser = RDF::Trine::Parser::RDFXML->new  unless defined $parser;
	$parser->parse_into_model($response->base, $response->decoded_content, $self->graph);
}

sub _uri_into_model
{
	my $self  = shift;
	my $uri   = shift;
	
	# avoid repetition
	return if $self->{'_uri_into_model::done'}->{"$uri"};
	
	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);
	$ua->env_proxy;
	$ua->default_header('Accept' => 'application/rdf+xml, text/turtle, application/x-rdf+json');
	
	my $response = $ua->get($uri);
	
	if ($response->is_success)
	{
		$self->_response_into_model($response);
		$self->{'_uri_into_model::done'}->{"$uri"}++;
	}
}

sub _simple_sparql
{
	my $self = shift;
	
	my $opts = {};
	if (ref $_[0] eq 'HASH')
	{
		$opts = shift;
	}
	
	my $where = '';
	foreach my $p (@_)
	{
		$where .= " UNION " if length $where;
		$where .= sprintf('{ [] foaf:mbox <%s> ; <%s> ?x . } UNION { [] foaf:mbox_sha1sum <%s> ; <%s> ?x . }',
			(''.$self->{'ident'}),
			$p,
			sha1_hex(''.$self->{'ident'}),
			$p
			);
	}
	my $sparql = "PREFIX foaf: <http://xmlns.com/foaf/0.1/> SELECT DISTINCT ?x WHERE { $where }";
	
	my $iter;
	if ($opts->{'use_endpoint'})
	{
		my $query = RDF::Query::Client->new($sparql);
		$iter = $query->execute($self->endpoint);
	}
	else
	{
		my $query = RDF::Query->new($sparql);
		$iter = $query->execute($self->graph);
	}
	
	my @results;
	
	while (my $row = $iter->next)
	{
		push @results, $row->{'x'}->literal_value
			if $row->{'x'}->is_literal;
		push @results, $row->{'x'}->uri
			if $row->{'x'}->is_resource;
	}
	
	if (wantarray)
	{
		return @results;
	}
	
	if (@results)
	{
		return $results[0];
	}
	
	return undef;
}

sub get
{
	my ($self, @params) = @_;
	return $self->_simple_sparql( map { HTTP::Link::Parser::relationship_uri($_) } @params );
}

sub follow_seeAlso
{
	my $self    = shift;
	my $recurse = shift;
	
	my $sparql = "
	PREFIX dc: <http://purl.org/dc/terms/>
	PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX rel: <http://www.iana.org/assignments/relation/>
	SELECT DISTINCT ?seealso
	WHERE
	{
		{
			?anything rdfs:seeAlso ?seealso .
		}
		UNION
		{
			?anything rel:describedby ?seealso .
			?seealso dc:format <http://www.iana.org/assignments/media-types/application/rdf+xml> .
		}
	}
	";

	my $query  = RDF::Query->new($sparql);
	my $iter   = $query->execute( $self->graph );

	while (my $row = $iter->next)
	{
		$self->_uri_into_model($row->{'seealso'}->uri)
			if $row->{'seealso'}->is_resource;
	}
	
	$self->follow_seeAlso($recurse - 1)
		if $recurse >= 1;
}

sub webid
{
	my $self = shift;
	
	my $where = sprintf('{ ?person foaf:mbox <%s> . } UNION { ?person foaf:mbox_sha1sum <%s> . } UNION { ?person foaf:account <%s> . } UNION { ?person foaf:holdsAccount <%s> . }',
		(''.$self->{'ident'}),
		sha1_hex(''.$self->{'ident'}),
		(''.$self->{'ident'}),
		(''.$self->{'ident'}),
		);
	
	my $sparql = "PREFIX foaf: <http://xmlns.com/foaf/0.1/> SELECT DISTINCT ?person WHERE { $where }";
	my $query  = RDF::Query->new($sparql);
	my $iter   = $query->execute( $self->graph );
	
	while (my $row = $iter->next)
	{
		return $row->{'person'}->uri
			if $row->{'person'}->is_resource;
	}
	
	return undef;
}

sub name
{
	my $self = shift;
	return $self->_simple_sparql(
		'http://xmlns.com/foaf/0.1/name');
}

sub nick
{
	my $self = shift;
	return $self->_simple_sparql(
		'http://xmlns.com/foaf/0.1/nick');
}

sub homepage
{
	my $self = shift;
	return $self->_simple_sparql(
		'http://xmlns.com/foaf/0.1/homepage',
		'http://webfinger.net/rel/profile-page');
}

sub weblog
{
	my $self = shift;
	return $self->_simple_sparql(
		'http://xmlns.com/foaf/0.1/weblog');
}

sub mbox
{
	my $self = shift;
	return $self->_simple_sparql(
		'http://xmlns.com/foaf/0.1/mbox');
}

sub image
{
	my $self = shift;
	return $self->_simple_sparql(
		'http://webfinger.net/rel/avatar',
		'http://xmlns.com/foaf/0.1/img',
		'http://xmlns.com/foaf/0.1/depiction');
}

sub graph
{
	my $self = shift;
	return $self->{'graph'};
}

sub endpoint
{
	my $self = shift;
	my $ep   = $self->_simple_sparql('http://ontologi.es/sparql#endpoint');
	return $ep;
}

1;

__END__

=head1 NAME

WWW::Finger::_GenericRDF - reusable base

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2009-2012 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
