use 5.008;
use strict;
use warnings;

package Types::UUID;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use Type::Library -base;
use Type::Tiny ();
use Types::Standard qw( Undef Str InstanceOf );
use UUID::Tiny qw( :std );

our @EXPORT = qw( Uuid );

{
	package #
		Types::UUID::_Constraint;
	our @ISA = "Type::Tiny";
	sub generate {
		shift;
		UUID::Tiny::create_uuid_as_string(@_);
	}
	sub generator {
		shift;
		my @args = @_;
		sub { UUID::Tiny::create_uuid_as_string(@args) }
	}
}

my $type = __PACKAGE__->add_type(
	'Types::UUID::_Constraint'->new(
		name       => 'Uuid',
		parent     => Str,
		constraint => \&is_uuid_string,
		inlined    => sub {
			return (
				Str->inline_check($_),
				"UUID::Tiny::is_uuid_string($_)",
			);
		},
	),
);

$type->coercion->add_type_coercions(
	Undef             ,=>  q[UUID::Tiny::create_uuid_as_string()],
	Str               ,=>  q[eval{ UUID::Tiny::uuid_to_string(UUID::Tiny::string_to_uuid($_)) }],
	InstanceOf['URI'] ,=>  q[eval{ UUID::Tiny::uuid_to_string(UUID::Tiny::string_to_uuid(q().$_)) }],
);

$type->coercion->freeze;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::UUID - type constraints for UUIDs

=head1 SYNOPSIS

   package FroobleStick;
   
   use Moo;
   use Types::UUID;
   
   has identifier => (
      is      => 'lazy',
      isa     => Uuid,
      coerce  => 1,
      builder => Uuid->generator,
   );

=head1 DESCRIPTION

L<Types::UUID> is a type constraint library suitable for use with
L<Moo>/L<Moose> attributes, L<Kavorka> sub signatures, and so forth.

=head2 Type

Currently the module only provides one type constraint, which is
exported by default.

=over

=item C<Uuid>

A valid UUID string, as judged by the C<< is_uuid_string() >> function
provided by L<UUID::Tiny>.

This constraint has coercions from C<Undef> (generates a new UUID),
C<Str> (fixes slightly broken-looking UUIDs, adding missing dashes;
also accepts base-64-encoded UUIDs) and L<URI> objects using the
C<< urn:uuid: >> URI scheme.

=back

=head2 Methods

The C<Uuid> type constraint is actually blessed into a subclass of
L<Type::Tiny>, and provides an aditional method:

=over

=item C<< Uuid->generate >>

Generates a new UUID. C<< Uuid->coerce(undef) >> would also work, but
looks a little odd.

=item C<< Uuid->generator >>

Returns a coderef which generates a new UUID. For an example usage, see
the L</SYNOPSIS>.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Types-UUID>.

=head1 SEE ALSO

L<Type::Tiny::Manual>, L<UUID::Tiny>.

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

