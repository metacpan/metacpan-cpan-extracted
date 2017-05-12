package Web::ID;

use 5.010;
use utf8;

BEGIN {
	$Web::ID::AUTHORITY = 'cpan:TOBYINK';
	$Web::ID::VERSION   = '1.927';
}

use Web::ID::Types -types;
use Web::ID::Certificate;
use Web::ID::Util qw(:default uniq);

use Moose;
use namespace::sweep;

has certificate => (
	is          => read_only,
	isa         => Certificate,
	required    => true,
	coerce      => true,
);

has uri => (
	is          => read_only,
	isa         => Uri,
	lazy_build  => true,
	coerce      => true,
);

has profile => (
	is          => read_only,
	isa         => Model,
	lazy_build  => true,
);

has valid => (
	is          => read_only,
	isa         => Bool,
	lazy_build  => true,
);

has first_valid_san => (
	is          => read_only,
	isa         => San | Undef,
	lazy_build  => true,
);

sub _build_valid
{
	my ($self) = @_;
	return false unless $self->certificate->timely;
	return true if defined $self->first_valid_san;
	return false;
}

sub _build_uri
{
	my ($self) = @_;
	$self->first_valid_san->uri_object;
}

sub _build_profile
{
	my ($self) = @_;
	$self->first_valid_san->model;
}

sub _build_first_valid_san
{
	my ($self) = @_;
	my $cert   = $self->certificate;
	my @sans   = @{ $cert->subject_alt_names };
	
	foreach my $san (@sans)
	{
		foreach my $key ( $san->associated_keys )
		{
			return $san if $key->rsa_equal($cert);
		}
	}
	
	return undef;
}

sub node
{
	my ($self) = @_;
	"RDF::Trine::Node::Resource"->new($self->uri.'');
}

sub get
{
	my $self = shift;
	my @pred = map {
		if (blessed $_ and $_->isa("RDF::Trine::Node"))   {   $_ }
		else                                              { u $_ }
	} @_;
	
	my @results = uniq
		map { $_->is_resource ? $_->uri : $_->literal_value }
		grep { $_->is_literal or $_->is_resource }
		$self->profile->objects_for_predicate_list($self->node, @pred);
	
	wantarray ? @results : $results[0];
}

__PACKAGE__
__END__

=head1 NAME

Web::ID - implementation of WebID (a.k.a. FOAF+SSL)

=head1 SYNOPSIS

 my $webid = Web::ID->new(certificate => $pem_encoded_x509);
 if ($webid->valid)
 {
   say "Authenticated as: ", $webid->uri;
 }

=head1 DESCRIPTION

WebID is a simple authentication protocol based on TLS (Transaction
Layer Security, better known as Secure Socket Layer, SSL) and the
Semantic Web. This module provides a Perl implementation for
authenticating clients using WebID.

For more information see the L<Web::ID::FAQ> document.

Bundled with this module are L<Plack::Middleware::Auth::WebID>, a
plugin for L<Plack> to perform WebID authentication on HTTPS
connections; and L<Web::ID::Certificate::Generator>, a module that
allows you to generate WebID-enabled certificates that can be
installed into web browsers.

=head2 Constructor

=over

=item C<< new >>

Standard Moose-style constructor. 

=back

=head2 Attributes

=over

=item C<< certificate >>

A L<Web::ID::Certificate> object representing and x509 certificate,
though a PEM-encoded string will be coerced.

This is usually the only attribute you want to pass to the constructor.
Allow the others to be built automatically.

=item C<< first_valid_san >>

Probably fairly uninteresting. This is the first subjectAltName value
found in the certificate that could be successfully authenticated
using Web::ID. An L<Web::ID::SAN> object.

=item C<< uri >>

The URI associated with the first valid SAN. A L<URI> object.

This is a URI you can use to identify the person, organisation or
robotic poodle holding the certificate.

=item C<< profile >>

Data about the certificate holder. An L<RDF::Trine::Model> object.
Their FOAF file (probably).

=item C<< valid >>

Boolean.

=back

=head2 Methods

=over

=item C<< node >>

Returns the same as C<uri>, but as an L<RDF::Trine::Node> object.

=item C<< get(@predicates) >>

Queries the C<profile> for triples of the form:

  $self->node $predicate $x .

And returns literal and URI values for $x, as strings.

C<< $predicate >> should be an L<RDF::Trine::Node>, or a string. If a
string, it will be expanded using L<RDF::Trine::NamespaceMap>, so you 
can do stuff like:

  my $name   = $webid->get('foaf:name', 'rdfs:label');
  my @mboxes = $webid->get('foaf:mbox');

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Web-ID>.

=head1 SEE ALSO

L<Web::ID::FAQ>.

L<Web::ID::Certificate>,
L<Plack::Middleware::Auth::WebID>.

L<RDF::ACL> provides an access control system that complements WebID.

L<CGI::Auth::FOAF_SSL> is the spiritual ancestor of this module though
they share very little code, and have quite different APIs.

General WebID information:
L<http://webid.info/>,
L<http://www.w3.org/wiki/WebID>,
L<http://www.w3.org/2005/Incubator/webid/spec/>,
L<http://lists.foaf-project.org/mailman/listinfo/foaf-protocols>.

Mailing list for general Perl RDF/SemWeb discussion and support:
L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 THANKS

Thanks to Kjetil Kjernsmo (cpan:KJETILK) for persuading me to port my old
CGI-specific implementaton of this to Plack.

Thanks Kjetil Kjernsmo (again), Florian Ragwitz (cpan:FLORA), and
Jonas Smedegaard for help with testing and advice on dependencies.

Thanks to Henry Story, Melvin Carvalho, Simon Reinhardt, Bruno Harbulot,
Ian Jacobi and many others for developing WebID from a poorly thought
out idea to a clever, yet simple and practical authentication protocol.

Thanks to Gregory Williams (cpan:GWILLIAMS), Tatsuhiko Miyagawa
(cpan:MIYAGAWA) and the Moose Cabal for providing really good platforms
(RDF::Trine, Plack and Moose respectively) to build this on.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

