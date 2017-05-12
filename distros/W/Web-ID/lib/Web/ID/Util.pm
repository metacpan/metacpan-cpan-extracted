package Web::ID::Util;

use 5.010;
use strict;
use utf8;

BEGIN {
	$Web::ID::Util::AUTHORITY = 'cpan:TOBYINK';
	$Web::ID::Util::VERSION   = '1.927';
}

use match::simple qw/match/;
use Carp qw/confess/;
use Math::BigInt 0 try => 'GMP';
use RDF::Trine::NamespaceMap;
use List::MoreUtils qw(:all !true !false);

use Exporter::Tiny;
our @EXPORT = qw(
	make_bigint_from_node get_trine_model u uu
	true false read_only read_write
);
our @EXPORT_OK = (
	@EXPORT,
	grep {!/^(true|false)$/} @List::MoreUtils::EXPORT_OK
);
our @ISA = qw( Exporter::Tiny );

use constant {
	read_only  => 'ro',
	read_write => 'rw',
};

use constant {
	true  => !!1, 
	false => !!0,
};

sub u (;$)
{
	state $namespaces //= RDF::Trine::NamespaceMap->new({
		rdf	=> 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
		rdfs	=> 'http://www.w3.org/2000/01/rdf-schema#',
		owl	=> 'http://www.w3.org/2002/07/owl#',
		xsd	=> 'http://www.w3.org/2001/XMLSchema#',
		foaf	=> 'http://xmlns.com/foaf/0.1/',
		cert	=> 'http://www.w3.org/ns/auth/cert#',
		rsa	=> 'http://www.w3.org/ns/auth/rsa#',
	});
	
	if (@_)
	{
		my $rv = $namespaces->uri(@_)
			or confess "couldn't expand term $_[0]";
		return $rv;
	}
	
	return $namespaces;
}

sub uu ($)
{
	return u(shift)->uri;
}

sub get_trine_model
{
	my ($uri, $model) = @_;
	
	$model //= "RDF::Trine::Model"->new;
	eval {
		"RDF::Trine::Parser"->parse_url_into_model($uri, $model);
	};
	
	return $model;
}

sub make_bigint_from_node
{
	my ($node, %opts) = @_;
	
	state $test_hex = [
		uu('cert:hex'),
		uu('xsd:hexBinary'),
	];
	
	state $test_unsigned = [
		uu('cert:decimal'),
		uu('cert:int'),
		uu('xsd:unsignedLong'),
		uu('xsd:unsignedInt'),
		uu('xsd:unsignedShort'),
		uu('xsd:unsignedByte'),
		uu('xsd:positiveInteger'),
		uu('xsd:nonNegitiveInteger'),
	];
	
	state $test_signed = [
		uu('xsd:integer'),
		uu('xsd:negitiveInteger'),
		uu('xsd:nonPositiveInteger'),
		uu('xsd:long'),
		uu('xsd:short'),
		uu('xsd:int'),
		uu('xsd:byte'),
	];
	
	state $test_decimal = uu('xsd:decimal');
	
	if ($node->is_literal)
	{
		for ($node->literal_datatype)
		{
			if (match $_, $test_hex)
			{
				( my $hex = $node->literal_value ) =~ s/[^0-9A-F]//ig;
				return "Math::BigInt"->from_hex("0x$hex");
			}
			
			if (match $_, $test_unsigned)
			{
				( my $dec = $node->literal_value ) =~ s/[^0-9]//ig;
				return "Math::BigInt"->new("$dec");
			}
			
			if (match $_, $test_signed)
			{
				( my $dec = $node->literal_value ) =~ s/[^0-9-]//ig;
				return "Math::BigInt"->new("$dec");
			}
			
			if (match $_, $test_decimal)
			{
				my ($dec, $frac) = split /\./, $node->literal_value, 2;
				warn "Ignoring fractional part of xsd:decimal number."
					if defined $frac;
				
				$dec =~ s/[^0-9-]//ig;
				return "Math::BigInt"->new("$dec");
			}
			
			if (match $_, undef)
			{
				$opts{'fallback'} = $node;
			}
		}
	}
	
	if (defined( my $node = $opts{'fallback'} )
	and $opts{'fallback'}->is_literal)
	{
		if ($opts{'fallback_type'} eq 'hex')
		{
			(my $hex = $node->literal_value) =~ s/[^0-9A-F]//ig;
			return "Math::BigInt"->from_hex("0x$hex");
		}
		else # dec
		{
			my ($dec, $frac) = split /\./, $node->literal_value, 2;
			warn "Ignoring fractional part of xsd:decimal number."
				if defined $frac;
				
			$dec =~ s/[^0-9]//ig;
			return "Math::BigInt"->new("$dec");
		}
	}
	
	return;
}


__PACKAGE__
__END__

=head1 NAME

Web::ID::Util - utility functions used in Web-ID

=head1 DESCRIPTION

These are utility functions which I found useful building Web-ID.
Many of them may also be useful creating the kind of apps that
Web-ID is used to authenticate for.

Here is a very brief summary. By B<default>, they're B<all> exported
to your namespace. (This module uses L<Exporter::Tiny> so you get
pretty good control over what gets exported.)

=over

=item C<true> - constant for true

=item C<false> - constant for false

=item C<read_only> - constant for string 'ro' (nice for Moose/Mouse)

=item C<read_write> - constant for string 'rw' (nice for Moose/Mouse)

=item C<< get_trine_model($url) >> - fetches a URL and parses RDF into
an L<RDF::Trine::Model>

=item C<< u($curie) >> - expands a CURIE, returning an
L<RDF::Trine::Node::Resource>

=item C<< uu($curie) >> - as per C<< u($curie) >>, but returns string

=item C<< u() >> - called with no CURIE, returns the
L<RDF::Trine::NamespaceMap> used to map CURIEs to URIs

=item C<< make_bigint_from_node($node, %options) >> - makes a L<Math::BigInt>
object from a numeric L<RDF::Trine::Node::Literal>. Supports most datatypes
you'd care about, including hexadecimally ones. 

Supported options are C<fallback> which provides a fallback node which will
be used when C<< $node >> is non-literal; and C<fallback_type> either 'dec'
or 'hex' which is used when parsing the fallback node, or if C<< $node >>
is a plain literal. (The actual datatype of the fallback node is ignored for
hysterical raisins.)

=back

Additionally, any function from L<List::MoreUtils> can be exported by request,
except C<true> and C<false> as they conflict with the constants above.

  use Web::ID::Utils qw(:default uniq);

=head1 BUGS

I don't wanna hear about them unless they cause knock-on bugs for
L<Web::ID> itself.

=head1 SEE ALSO

L<Exporter::Tiny>,
L<Web::ID>,
L<Acme::24>.

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

