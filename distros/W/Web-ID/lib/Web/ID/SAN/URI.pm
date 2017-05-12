package Web::ID::SAN::URI;

use 5.010;
use utf8;

BEGIN {
	$Web::ID::SAN::URI::AUTHORITY = 'cpan:TOBYINK';
	$Web::ID::SAN::URI::VERSION   = '1.927';
}

use Web::ID::Types -types;
use Web::ID::Util;

use Moose;
use namespace::sweep;
extends 'Web::ID::SAN';

has '+type' => (default => 'uniformResourceIdentifier');

override uri_object => sub
{
	my ($self) = @_;
	return Uri->coerce($self->value);
};

around _build_model => sub
{
	my ($orig, $self) = @_;
	my $model = $self->$orig;
	return get_trine_model($self->value => $model);
};

around associated_keys => sub
{
	my ($orig, $self) = @_;
	my @keys = $self->$orig;
	
	my $results = $self->_query->execute( $self->model );
	RESULT: while (my $result = $results->next)
	{
		# trim any whitespace around modulus
		# (HACK for MyProfile WebIDs)
		# Should probably be in ::Util.
		$result->{modulus}->[0] =~ s/(^\s+)|(\s+$)//g;
		
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
	return "RDF::Query"->new( sprintf(<<'SPARQL', (($self->uri_object)x4)) );
PREFIX cert: <http://www.w3.org/ns/auth/cert#>
PREFIX rsa: <http://www.w3.org/ns/auth/rsa#>
SELECT
	?modulus
	?exponent
	?decExponent
	?hexModulus
WHERE
{
	{
		?key
			cert:identity <%s> ;
			rsa:modulus ?modulus ;
			rsa:public_exponent ?exponent .
	}
	UNION
	{
		<%s> cert:key ?key .
		?key
			rsa:modulus ?modulus ;
			rsa:public_exponent ?exponent .
	}
	UNION
	{
		?key
			cert:identity <%s> ;
			cert:modulus ?modulus ;
			cert:exponent ?exponent .
	}
	UNION
	{
		<%s> cert:key ?key .
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

Web::ID::SAN::URI - represents subjectAltNames that are URIs

=head1 DESCRIPTION

subjectAltNames such as these are the foundation of the whole WebID idea.

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

