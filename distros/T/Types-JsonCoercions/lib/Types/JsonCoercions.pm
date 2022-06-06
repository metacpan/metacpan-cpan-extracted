use 5.008009;
use strict;
use warnings;

package Types::JsonCoercions;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Type::Library 1.004
	-base,
	-declare => qw( ArrayRefJ HashRefJ RefJ StrJ );
use Types::Standard 1.004 qw( Str Ref ArrayRef HashRef );

our $JSON;

sub _code_to_load_package {
	my ( $me, $pkg, $keyword ) = ( shift, @_ );
	$keyword ||= 'do';
	return sprintf(
		'%s { require %s; q[%s] }',
		$keyword,
		$pkg,
		$pkg,
	);
}

sub _code_for_json_encoder {
	my ( $me ) = ( shift );
	return sprintf(
		'$%s::JSON ||= ( %s or %s )->new',
		$me,
		$me->_code_to_load_package( 'JSON::MaybeXS', 'eval' ),
		$me->_code_to_load_package( 'JSON::PP' ),
	);
}

my $meta = __PACKAGE__->meta;

my $ToJson = $meta->add_coercion( {
	name     => 'ToJSON',
	frozen   => 1,
	type_coercion_map => [
		Ref, sprintf( q{ ( %s )->encode( $_ ) }, __PACKAGE__->_code_for_json_encoder ),
	],
} );

my $FromJson = $meta->add_coercion( {
	name     => 'FromJSON',
	frozen   => 1,
	type_coercion_map => [
		Str, sprintf( q{ ( %s )->decode( $_ ) }, __PACKAGE__->_code_for_json_encoder ),
	],
} );

$meta->add_type( {
	name     => StrJ,
	parent   => Str->plus_coercions( $ToJson ),
	coercion => 1,
} );

$meta->add_type( {
	name     => RefJ,
	parent   => Ref->plus_coercions( $FromJson ),
	coercion => 1,
	constraint_generator => sub {
		Ref->of( @_ )->plus_coercions( $FromJson );
	},
} );

$meta->add_type( {
	name     => HashRefJ,
	parent   => HashRef->plus_coercions( $FromJson ),
	coercion => 1,
	constraint_generator => sub {
		HashRef->of( @_ )->plus_coercions( $FromJson );
	},
} );

$meta->add_type( {
	name     => ArrayRefJ,
	parent   => ArrayRef->plus_coercions( $FromJson ),
	coercion => 1,
	constraint_generator => sub {
		ArrayRef->of( @_ )->plus_coercions( $FromJson );
	},
} );

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::JsonCoercions - coercions to and from JSON

=head1 SYNOPSIS

  package Person {
    use Moo;
    use Types::Standard -types,
    use Types::JsonCoercions -types;
    
    has nicknames => (
      is => 'ro',
      isa => ArrayRefJ[Str],
      coerce => 1,
      required => 1,
    );
  }

  my $alice => Person->new( nicknames => [ 'Ali' ] );
  my $bob   => Person->new( nicknames => '["Bob","Rob"]' );

=head1 DESCRIPTION

This module provides coercions to/from JSON for some of the types
from L<Types::Standard>.

=head2 Coercions

You can export coercions using:

  use Types::JsonCoercions -coercions;
  # or
  use Types::JsonCoercions qw( ToJSON FromJSON );

And they can be applied to existing type constraints like:

  isa => ArrayRef->plus_coercions( FromJSON ),
  coerce => 1,

This also works with parameterized types:

  isa => ArrayRef->of( HashRef )->plus_coercions( FromJSON ),
  coerce => 1,

The B<FromJSON> coercion can be added to any arrayref-like or hashref-like
type constraints, and will coerce strings via a JSON decoder.

The B<ToJSON> coercion can be added to string-like type constraints, and
will coerce references via a JSON encoder.

=head2 Types

You can export the types like:

  use Types::JsonCoercions -types;
  # or
  use Types::JsonCoercions qw( StrJ RefJ ArrayRefJ HashRefJ );

The type constraint B<StrJ> is provided as a shortcut for
C<< Str->plus_coercions( ToJSON ) >>.

The type constraints B<RefJ>, B<ArrayRefJ>, and B<HashRefJ> are provided
as shortcuts for C<< Ref->plus_coercions( FromJSON ) >>, etc.

B<RefJ>, B<ArrayRefJ>, and B<HashRefJ> are parameterizable as per the types
in L<Types::Standard>, so B<< ArrayRefJ[Int] >> should just work.

=head2 JSON Encoder/Decoder

This module will use L<JSON::MaybeXS> if it is installed, and will
otherwise fall back to L<JSON::PP>.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Types-JsonCoercions>.

=head1 SEE ALSO

L<Types::Standard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
