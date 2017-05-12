package WWW::Finger::Fingerpoint;

use 5.010;
use common::sense;
use utf8;

use Carp 0;
use Digest::SHA 0 qw[sha1_hex];
use HTTP::Link::Parser 0.102 qw[:standard];
use LWP::UserAgent 0;
use RDF::Query::Client 0.106;
use RDF::Trine 0.135;
use URI 0;

use parent qw[WWW::Finger];

BEGIN {
	$WWW::Finger::Fingerpoint::AUTHORITY = 'cpan:TOBYINK';
	$WWW::Finger::Fingerpoint::VERSION   = '0.105';
}

use constant rel_fingerpoint => 'http://ontologi.es/sparql#fingerpoint';

sub speed { 90 }

sub new
{
	my $class = shift;
	my $ident = shift or croak "Need to supply an e-mail address\n";
	my $self  = bless {}, $class;
		
	$ident = "mailto:$ident"
		unless $ident =~ /^[a-z0-9\.\-\+]+:/i;
	$ident = URI->new($ident);
	return undef
		unless $ident->scheme eq 'mailto';
	
	$self->{'ident'} = $ident;
	my ($user, $host) = split /\@/, $ident->to;
	
	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);
	$ua->env_proxy;
	
	my $httphost = "http://$host/";
	my $response = $ua->head($httphost);
	return undef
		unless $response->is_success;
	
	my $linkdata = HTTP::Link::Parser::parse_links_to_rdfjson($response);
	my $sparql   = $linkdata->{ $httphost }->{ (rel_fingerpoint) }->[0]->{'value'};

	unless (defined $sparql)
	{
		$response = $ua->get($httphost,
			'Accept' => 'application/xhtml+xml;q=1.0, text/html;q=0.9, */*;q=0.1');
		return undef
			unless $response->is_success;
		if ($response->header('content-type') =~ m`^(text/html|application/xhtml+xml|application/xml|text/xml)`i)
		{
			$sparql = URI->new_abs($1, URI->new($httphost))
				if $response->content =~ m`<[Ll][Ii][Nn][Kk]\s+[Rr][Ee][Ll]="[^"]*http://ontologi\.es/sparql#fingerpoint[^"]*"\s+[Hh][Rr][Ee][Ff]="([^"]+)"\s*/?>`;
		}
	}

	return undef
		unless defined $sparql && length $sparql;
	
	$self->{'endpoint'} = $sparql;
	
	my $sha1 = sha1_hex($ident);
	my $sparql_query = "PREFIX foaf: <http://xmlns.com/foaf/0.1/>
	PREFIX wot: <http://xmlns.com/wot/0.1/>
	SELECT DISTINCT *
	WHERE {
		{
			{ ?person foaf:mbox <$ident> . }
			UNION
			{ ?person foaf:mbox_sha1sum \"$sha1\" . }
			UNION
			{ ?person foaf:account <$ident> . }
			UNION
			{ ?person foaf:holdsAccount <$ident> . }
		}
		OPTIONAL { ?person foaf:name ?name . }
		OPTIONAL { ?person foaf:nick ?nick . }
		OPTIONAL { ?person foaf:homepage ?homepage . }
		OPTIONAL { ?person foaf:mbox ?mbox . }
		OPTIONAL { ?person foaf:weblog ?weblog . }
		OPTIONAL { ?person foaf:img ?image . }
		OPTIONAL { ?k wot:pubkeyAddress ?key ; wot:identity ?person . }
	}";
	my @fields = qw(name homepage mbox weblog image key);
	
	my $query  = RDF::Query::Client->new($sparql_query);
	my $result = $query->execute($self->endpoint, {QueryMethod=>'POST'});
	my $webid;

	BINDING: while (my $binding = $result->next)
	{
		$webid = $binding->{'person'}->uri
			if  $binding->{'person'}
			and $binding->{'person'}->is_resource
			and !defined $webid;
			
		FIELD: foreach my $field (@fields)
		{
			next FIELD unless $binding->{$field};
			
			if ($binding->{$field}->is_resource)
				{ $self->{'data'}->{$field}->{ $binding->{$field}->uri } = 1; }
			elsif ($binding->{$field}->is_literal)
				{ $self->{'data'}->{$field}->{ $binding->{$field}->literal_value } = 1; }
		}
	}
	
	foreach my $field (@fields)
	{
		$self->{'data'}->{$field} = [ keys %{ $self->{'data'}->{$field} } ];
	}
	
	$self->{'webid'} = $webid;
	
	return $self;
}

sub graph
{
	my $self = shift;
	
	unless (defined $self->{'graph'})
	{
		my $ident = $self->{'ident'}.'';
		my $sha1 = sha1_hex($ident);
		my $model = RDF::Trine::Model->new( RDF::Trine::Store->temporary_store );
		my $query  = RDF::Query::Client->new("
			PREFIX foaf: <http://xmlns.com/foaf/0.1/>
			DESCRIBE ?person
			WHERE
			{
				{ ?person foaf:mbox <$ident> . }
				UNION
				{ ?person foaf:mbox_sha1sum \"$sha1\" . }
				UNION
				{ ?person foaf:account <$ident> . }
				UNION
				{ ?person foaf:holdsAccount <$ident> . }
			}");
		my $result = $query->execute($self->endpoint, {QueryMethod=>'POST'});
		if ($result)
		{
			while (my $st = $result->next)
			{
				$model->add_statement($st);
			}
			$self->{'graph'} = $model;
		}		
	}
	
	return $self->{'graph'};
}

sub get
{
	my ($self, @params) = @_;
	return WWW::Finger::_GenericRDF::_simple_sparql(
		$self,
		{use_endpoint=>1},
		map { HTTP::Link::Parser::relationship_uri($_) } @params );
}

sub endpoint
{
	my $self = shift;
	return $self->{'endpoint'};
}

sub webid
{
	my $self = shift;
	return $self->{'webid'};
}

sub _data
{
	my $self = shift;
	my $k    = shift;
	if (wantarray)
	{
		return @{ $self->{'data'}->{$k} }
			if defined $self->{'data'}->{$k};
	}
	else
	{
		return $self->{'data'}->{$k}->[0]
			if defined $self->{'data'}->{$k}->[0];
	}
	return undef;
}

sub name
{
	my $self = shift;
	return $self->_data('name');
}

sub nick
{
	my $self = shift;
	return $self->_data('nick');
}

sub mbox
{
	my $self = shift;
	return $self->_data('mbox');
}

sub image
{
	my $self = shift;
	return $self->_data('image');
}

sub homepage
{
	my $self = shift;
	return $self->_data('homepage');
}

sub weblog
{
	my $self = shift;
	return $self->_data('weblog');
}

sub key
{
	my $self = shift;
	return $self->_data('key');
}

1;

__END__

=head1 NAME

WWW::Finger::Fingerpoint - Investigate E-mail Addresses using Fingerpoint

=head1 SYNOPSIS

  ## Using WWW::Finger
  
  use WWW::Finger;
  
  my $finger = WWW::Finger->new("joe@example.com");
  
  if ($finger)
  {
    if ($finger->isa('WWW::Finger::Fingerpoint'))
    {
      print "WWW::Finger used WWW::Fingerpoint\n";
    }
    print $finger->name . "\n";  # print person's name.
 }

  ## Using WWW::Finger::Fingerpoint directly
  
  use RDF::Query::Client;
  use WWW::Finger::Fingerpoint;
  
  my $fingerpoint = WWW::Finger::Fingerpoint->new("joe@example.com");
  
  if ($fingerpoint->webid)
  {
    my $sparql  = sprintf(
      "SELECT * WHERE {<%s> <http://xmlns.com/foaf/0.1/homepage> ?page.}",
      $fingerpoint->webid);
    my $query   = RDF::Query::Client->new($sparql);
    my $results = $query->execute($fingerpoint->endpoint);
	 while (my $row = $results->next)
    {
      print "Found page: " . $row->{'page'}->uri . "\n";
    }
  }
  
=head1 DESCRIPTION

As well as the standard WWW::Finger methods, WWW::Finger::Fingerpoint provides this
additional method:

=over

=item C<< get($p1, $p2, ...) >>

$p1, $p2 and are RDF predicate URIs. Returns a list of values which are non-bnode
objects of triples where the predicate URI is one of the parameters and the 
subject URI is the person/agent fingered.

  # Returns phone numbers...
  $finger->get('http://xmlns.com/foaf/0.1/phone',
               'http://rdf.data-vocabulary.org/#tel');

=back

=head1 SEE ALSO

L<WWW::Finger>.

L<RDF::Query::Client>, L<RDF::Trine>.

L<http://buzzword.org.uk/2009/fingerpoint/spec>.

L<http://www.perlrdf.org/>.

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
