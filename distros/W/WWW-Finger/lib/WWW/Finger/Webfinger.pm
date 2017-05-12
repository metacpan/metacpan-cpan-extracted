package WWW::Finger::Webfinger;

use 5.010;
use common::sense;
use utf8;

use Carp 0;
use HTTP::LRDD 0.104;
use LWP::UserAgent 0;
use RDF::Query 2.900;
use RDF::Trine 0.135 qw[iri];
use URI 0;
use URI::Escape 0;
use XRD::Parser 0.102;

use parent qw(WWW::Finger::_GenericRDF);

BEGIN {
	$WWW::Finger::Webfinger::AUTHORITY = 'cpan:TOBYINK';
	$WWW::Finger::Webfinger::VERSION   = '0.105';
}

sub speed { 100 }

sub new
{
	my $class = shift;
	my $ident = shift or croak "Need to supply an account address\n";
	my $self  = bless {}, $class;

	$ident = "acct:$ident"
		unless $ident =~ /^[a-z0-9\.\-\+]+:/i;
	$ident = URI->new($ident);
	return undef
		unless $ident->scheme =~ /^(mailto|acct|xmpp)$/;
	$self->{'ident'} = $ident;

	my $lrdd = HTTP::LRDD->new('http://lrdd.net/rel/descriptor', 'describedby', 'lrdd', 'webfinger');
	my @d = $lrdd->discover($ident);
	$self->{'graph'} = $lrdd->process_all($ident);
	
	$self->follow_seeAlso(0);
	
	return undef
		unless $self->{'graph'}->count_statements(iri($ident),undef,undef)
		||     $self->{'graph'}->count_statements(undef,undef,iri($ident));
	
	return $self;
}

sub _simple_sparql
{
	my $self = shift;
	my $where = '';
	foreach my $p (@_)
	{
		$where .= " UNION " if length $where;
		$where .= sprintf('{ <%s> <%s> ?x . } '
				. 'UNION { ?z xrd:alias <%s> ; <%s> ?x . } '
				. 'UNION { ?z <http://xmlns.com/foaf/0.1/account> <%s> ; <%s> ?x . } '
				. 'UNION { ?z <http://xmlns.com/foaf/0.1/holdsAccount> <%s> ; <%s> ?x . }',
			(''.$self->{'ident'}), $p,
			(''.$self->{'ident'}), $p,
			(''.$self->{'ident'}), $p,
			(''.$self->{'ident'}), $p,
			);
	}
	
	my $sparql = "PREFIX xrd: <http://ontologi.es/xrd#> SELECT DISTINCT ?x WHERE { $where }";
	my $query  = RDF::Query->new($sparql);
	my $iter   = $query->execute( $self->{'graph'} );
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
	
	return;
}

sub webid
{
	return (shift)->SUPER::webid(@_);
}

1;

__END__

=head1 NAME

WWW::Finger::Webfinger - WWW::Finger module for Webfinger

=head1 DESCRIPTION

Webfinger is currently a very unstable specification, with implementation details
changing all the time. Given this instability, it seems prudent to describe the
protocol, as implemented by this package.

Given an e-mail-like identifier, the package will prepend "acct:" to it, assuming that
the identifier doesn't already have a URI scheme. This identifier will now be called
[ident].

The package looks up the host-meta file associated with the host for [ident].
It is assumed to be formatted according to the draft-hammer-hostmeta-05
Internet Draft L<http://tools.ietf.org/html/draft-hammer-hostmeta-05> and
XRD Working Draft 10 <http://www.oasis-open.org/committees/download.php/35274/xrd-1.0-wd10.html>.
Both these drafts are dated 19 November 2009.

A link template will be extracted from the host-meta for the host using either
of the following two relationships: L<http://lrdd.net/rel/descriptor>,
L<http://www.iana.org/assignments/relation/lrdd>. (Neither is prioritised, so
if both exist and have different templates, hilarity will ensue.)

The token "{uri}" in the link template will be replaced with the URL-encoded
version of [ident] to create an account descriptor URI.

The account descriptor URI is fetched via HTTP GET with an Accept header
asking for RDF/XML, Turtle, RDF/JSON or XRD. The result is parsed for account
description data if it has status code 200 (OK).

The following relationships/properties are understood in the account
description:

=over

=item * http://xmlns.com/foaf/0.1/name

=item * http://xmlns.com/foaf/0.1/homepage

=item * http://webfinger.net/rel/profile-page

=item * http://xmlns.com/foaf/0.1/weblog

=item * http://xmlns.com/foaf/0.1/mbox

=item * http://webfinger.net/rel/avatar

=item * http://xmlns.com/foaf/0.1/img

=item * http://xmlns.com/foaf/0.1/depiction

=item * http://ontologi.es/sparql#endpoint

=back

As well as the standard WWW::Finger methods, WWW::Finger::Webfinger provides this
additional method:

=over

=item C<< get($p1, $p2, ...) >>

$p1, $p2 and are RDF predicate URIs, XRD Link@rel values, or XRD Property@type values

  # Returns phone numbers...
  $finger->get('http://xmlns.com/foaf/0.1/phone',
               'http://rdf.data-vocabulary.org/#tel');
  
  # Salmon-style magic keys
  $finger->get('magic-public-key');

=back

=head1 SEE ALSO

L<WWW::Finger>, L<XRD::Parser>, L<HTTP::LRDD>.

L<http://code.google.com/p/webfinger/>.

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
