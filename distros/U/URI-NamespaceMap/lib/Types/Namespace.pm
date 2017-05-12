package Types::Namespace;
use strict;
use warnings;

use Type::Library -base, -declare => qw( Uri Iri Namespace NamespaceMap );
use Types::Standard qw( HashRef InstanceOf );
use Types::URI qw();

our $VERSION = '1.00';

=head1 NAME

Types::Namespace - type constraints for dealing with namespaces

=head1 SYNOPSIS

  package Namespace::Counter {
    use Moo;  # or Moose
    use Types::Namespace qw( Namespace );

    has ns => (
      is => "ro",
      isa => Namespace,
      required => 1,
    );

    sub count_uses_in_document { ... }
  }

=head1 DESCRIPTION

L<Types::URI> is a type constraint library suitable for use with
L<Moo>/L<Moose> attributes, L<Kavorka> sub signatures, and so forth.

=head1 TYPES

=over

=item C<< Namespace >>

A class type for L<URI::Namespace>.

Can coerce from L<URI>, L<IRI>, L<Path::Tiny>, and strings.

=item C<< NamespaceMap >>

A class type for L<URI::NamespaceMap>.

Can coerce from a hashref of C<< prefix => URI >> pairs.

=item C<< Uri >>, C<< Iri >>

These namespaces are re-exported from L<Types::URI>, but with an
additional coercion from the C<< Namespace >> type.

=back

=head1 FURTHER DETAILS

See L<URI::NamespaceMap> for further details about authors, license, etc.

=cut

__PACKAGE__->add_type(
	name       => Uri,
	parent     => Types::URI::Uri,
	coercion   => [
		@{ Types::URI::Uri->coercion->type_coercion_map },
		InstanceOf['URI::Namespace'] ,=> q{ $_->uri() },
	],
);

__PACKAGE__->add_type(
	name       => Iri,
	parent     => Types::URI::Iri,
	coercion   => [
		@{ Types::URI::Iri->coercion->type_coercion_map },
		InstanceOf['URI::Namespace'] ,=> q{ $_->iri() },
	],
);

__PACKAGE__->add_type(
	name       => Namespace,
	parent     => InstanceOf['URI::Namespace'],
	coercion   => [
		Iri->coercibles ,=> q{ "URI::Namespace"->new($_) },
	],
);

__PACKAGE__->add_type(
	name       => NamespaceMap,
	parent     => InstanceOf['URI::NamespaceMap'],
	coercion   => [
		HashRef ,=> q{ "URI::NamespaceMap"->new(namespace_map => $_) }
	],
);

require URI::Namespace;
require URI::NamespaceMap;

1;
