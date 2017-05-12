package Web::ID::SAN::Email;

use 5.010;
use utf8;

our $WWW_Finger = 0;

BEGIN {
	$Web::ID::SAN::Email::AUTHORITY = 'cpan:TOBYINK';
	$Web::ID::SAN::Email::VERSION   = '1.927';
	
	eval {
		no warnings;
		require WWW::Finger;
		WWW::Finger->VERSION('0.100');
		$WWW_Finger++;
	}
}

use Web::ID::Types -types;
use Web::ID::Util;

use Moose;
use namespace::sweep;
extends "Web::ID::SAN";

has '+type' => (default => 'rfc822Name');

has finger => (
	is          => read_only,
	isa         => Finger | Undef,
	lazy        => true,
	builder     => '_build_finger',
);

sub _build_finger
{
	my ($self) = @_;
	return WWW::Finger->new($self->value);
}

around _build_model => sub
{
	my ($orig, $self) = @_;
	
	if (my $finger = $self->finger)
	{
		if ($finger->endpoint)
		{
			my $store = "RDF::Trine::Store::SPARQL"->new($finger->endpoint);
			return Model->new($store);
		}
		return $finger->graph;
	}
	
	$self->$orig();
};

around associated_keys => sub
{
	my ($orig, $self) = @_;
	my @keys = $self->$orig;
	
	my $results = $self->_query->execute( $self->model );
	RESULT: while (my $result = $results->next)
	{
		my $modulus = make_bigint_from_node(
			$result->{modulus},
			fallback      => $result->{hexModulus},
			fallback_type =>'hex',
		);
		my $exponent = make_bigint_from_node(
			$result->{exponent},
			fallback      => $result->{decExponent},
			fallback_type =>'dec',
		);
				
		my $key = $self->key_factory->(
			modulus  => $modulus,
			exponent => $exponent,
		);
		push @keys, $key if $key;
	}
	
	return @keys;
};

sub _query
{
	my ($self) = @_;
	my $email = 'mailto:' . $self->value;
	return "RDF::Query"->new( sprintf(<<'SPARQL', (($email)x4)) );
PREFIX cert: <http://www.w3.org/ns/auth/cert#>
PREFIX rsa: <http://www.w3.org/ns/auth/rsa#>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
SELECT
	?webid
	?modulus
	?exponent
	?decExponent
	?hexModulus
WHERE
{
	{
		?webid foaf:mbox <%s> .
		?key
			cert:identity ?webid ;
			rsa:modulus ?modulus ;
			rsa:public_exponent ?exponent .
	}
	UNION
	{
		?webid
			foaf:mbox <%s> ;
			cert:key ?key .
		?key
			rsa:modulus ?modulus ;
			rsa:public_exponent ?exponent .
	}
	UNION
	{
		?webid foaf:mbox <%s> .
		?key
			cert:identity ?webid ;
			cert:modulus ?modulus ;
			cert:exponent ?exponent .
	}
	UNION
	{
		?webid
			foaf:mbox <%s> ;
			cert:key ?key .
		?key
			cert:modulus ?modulus ;
			cert:exponent ?exponent .
	}
	OPTIONAL { ?modulus cert:hex ?hexModulus . }
	OPTIONAL { ?exponent cert:decimal ?decExponent . }
}
SPARQL
}

__PACKAGE__
__END__

=head1 NAME

Web::ID::SAN::Email - represents subjectAltNames that are e-mail addresses

=head1 DESCRIPTION

This module uses L<WWW::Finger> (if installed) to attempt to locate some
RDF data about the holder of the given e-mail address. It is probably not
especially interoperable with other WebID implementations.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Web-ID>.

=head1 SEE ALSO

L<Web::ID>,
L<Web::ID::SAN>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

