use 5.008;
use strict;
use warnings;

package Types::URI;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.006';

use URI;
use URI::file;
use URI::data;
use URI::WithBase;
use URI::FromHash;

use Type::Library -base, -declare => qw( Uri FileUri DataUri Iri );

use Types::Path::Tiny  qw( Path );
use Types::Standard    qw( InstanceOf ScalarRef HashRef Str );
use Types::UUID        qw( Uuid );

my $TrineNode = InstanceOf['RDF::Trine::Node::Resource'];
my $TrineNS   = InstanceOf['RDF::Trine::Namespace'];
my $XmlNS     = InstanceOf['XML::Namespace'];

__PACKAGE__->meta->add_type({
	name        => Iri,
	parent      => InstanceOf['IRI'],
	# Need to define coercions below to break circularity of
	# Uri and Iri.
});

__PACKAGE__->meta->add_type({
	name        => Uri,
	parent      => InstanceOf[qw/ URI URI::WithBase /],
	coercion    => [
		Uuid        ,=> q{ "URI"->new("urn:uuid:$_") },
		Str         ,=> q{ "URI"->new($_) },
		Path        ,=> q{ "URI::file"->new($_) },
		ScalarRef   ,=> q{ do { my $u = "URI"->new("data:"); $u->data($$_); $u } },
		HashRef     ,=> q{ "URI"->new(URI::FromHash::uri(%$_)) },
		$TrineNode  ,=> q{ "URI"->new($_->uri_value) },
		$TrineNS    ,=> q{ "URI"->new($_->uri->uri_value) },
		$XmlNS      ,=> q{ "URI"->new($_->uri) },
		Iri         ,=> q{ "URI"->new($_->as_string) },
	],
});

Iri->coercion->add_type_coercions(
	Uuid        ,=> q{ do { require IRI; "IRI"->new("urn:uuid:$_") } },
	Str         ,=> q{ do { require IRI; "IRI"->new($_) } },
	Path        ,=> q{ do { require IRI; my $u = "URI::file"->new($_); "IRI"->new($u->as_string) } },
	ScalarRef   ,=> q{ do { require IRI; my $u = "URI"->new("data:"); $u->data($$_); "IRI"->new($u->as_string) } },
	HashRef     ,=> q{ do { require IRI; "IRI"->new(URI::FromHash::uri(%$_)) } },
	$TrineNode  ,=> q{ do { require IRI; "IRI"->new($_->uri_value) } },
	$TrineNS    ,=> q{ do { require IRI; "IRI"->new($_->uri->uri_value) } },
	$XmlNS      ,=> q{ do { require IRI; "IRI"->new($_->uri) } },
	Uri         ,=> q{ do { require IRI; "IRI"->new($_->as_string) } },
);

__PACKAGE__->meta->add_type({
	name        => FileUri,
	parent      => Uri,
	constraint  => sub { $_->isa('URI::file') },
	inlined     => sub { InstanceOf->parameterize('URI::file')->inline_check($_[1]) },
	coercion    => [
		Str         ,=> q{ "URI::file"->new($_) },
		Path        ,=> q{ "URI::file"->new($_) },
		HashRef     ,=> q{ "URI"->new(URI::FromHash::uri(%$_)) },
		$TrineNode  ,=> q{ "URI"->new($_->uri_value) },
		$TrineNS    ,=> q{ "URI"->new($_->uri->uri_value) },
		$XmlNS      ,=> q{ "URI"->new($_->uri) },
		Iri         ,=> q{ "URI"->new($_->as_string) },
	],
});

__PACKAGE__->meta->add_type({
	name        => DataUri,
	parent      => Uri,
	constraint  => sub { $_->isa('URI::data') },
	inlined     => sub { InstanceOf->parameterize('URI::data')->inline_check($_[1]) },
	coercion    => [
		Str         ,=> q{ do { my $u = "URI"->new("data:"); $u->data($_); $u } },
		ScalarRef   ,=> q{ do { my $u = "URI"->new("data:"); $u->data($$_); $u } },
		HashRef     ,=> q{ "URI"->new(URI::FromHash::uri(%$_)) },
		$TrineNode  ,=> q{ "URI"->new($_->uri_value) },
		$TrineNS    ,=> q{ "URI"->new($_->uri->uri_value) },
		$XmlNS      ,=> q{ "URI"->new($_->uri) },
		Iri         ,=> q{ "URI"->new($_->as_string) },
	],
});

__PACKAGE__->meta->make_immutable; # returns true

__END__

=pod

=encoding utf-8

=head1 NAME

Types::URI - type constraints and coercions for URIs

=head1 SYNOPSIS

   package FroobleDocument;
   
   use Moose;
   use Types::URI -all;
   
   has source => (
      is      => 'ro',
      isa     => Uri,
      coerce  => 1,
   );

=head1 DESCRIPTION

L<Types::URI> is a type constraint library suitable for use with
L<Moo>/L<Moose> attributes, L<Kavorka> sub signatures, and so forth.

=head2 Types

This module provides some type constraints broadly compatible with
those provided by L<MooseX::Types::URI>, plus a couple of extra type
constraints.

=over

=item C<Uri>

A class type for L<URI>/L<URI::WithBase>. Coercions from:

=over

=item from C<Uuid>

Coerces to a URI in the C<< urn:uuid: >> schema. (See L<Types::UUID>.)

=item from C<Str>

Uses L<URI/new>.

=item from C<Path>

Uses L<URI::file/new>. (See L<Types::Path::Tiny>.)

=item from C<ScalarRef>

Uses L<URI::data/new>.

=item from C<HashRef>

Coerces using L<URI::FromHash>.

=item from C<Iri>

Uses L<URI/new>.

=item from L<RDF::Trine::Node::Resource>, L<RDF::Trine::Namespace>, L<XML::Namespace>

Uses L<URI/new>.

=back

=item C<FileUri>

A subtype of C<Uri> covering L<URI::file>. Coercions from:

=over

=item from C<Str>

Uses L<URI::file/new>.

=item from C<Path>

Uses L<URI::file/new>. (See L<Types::Path::Tiny>.)

=item from C<HashRef>

Coerces using L<URI::FromHash>.

=item from C<Iri>

Uses L<URI/new>.

=item from L<RDF::Trine::Node::Resource>, L<RDF::Trine::Namespace>, L<XML::Namespace>

Uses L<URI/new>.

=back

=item C<DataUri>

A subtype of C<Uri> covering L<URI::data>. Coercions from:

=over

=item from C<Str>

Uses L<URI::data/new>.

=item from C<ScalarRef>

Uses L<URI::data/new>.

=item from C<HashRef>

Coerces using L<URI::FromHash>.

=item from C<Iri>

Uses L<URI/new>.

=item from L<RDF::Trine::Node::Resource>, L<RDF::Trine::Namespace>, L<XML::Namespace>

Uses L<URI/new>.

=back

=item C<Iri>

A class type for L<IRI>. Coercions as per C<Uri> above, plus can coerce
from C<Uri>.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Types-URI>.

=head1 SEE ALSO

L<MooseX::Types::URI>,
L<Type::Tiny::Manual>,
L<URI>,
L<URI::file>,
L<URI::data>,
L<URI::FromHash>,
L<RDF::Trine::Node::Resource>,
L<IRI>.

L<Types::UUID>,
L<Types::Path::Tiny>,
L<Types::Standard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

