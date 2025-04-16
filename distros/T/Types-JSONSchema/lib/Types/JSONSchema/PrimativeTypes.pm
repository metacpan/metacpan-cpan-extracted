use 5.036;
use strict;
use warnings;
use experimental 'builtin';

package Types::JSONSchema::PrimativeTypes;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001000';

use Type::Library
	-base,
	-declare => qw/
		JNull
		JBoolean
		JObject
		JArray
		JNumber
		JString
		
		JTrue
		JFalse
		JInteger
		JAny
		
		JSPrimativeName
		JSPrimativeType
	/;
use Types::Common -all;
use Type::Utils;

declare JNull,
	as Undef;

declare JBoolean,
	as InstanceOf[ 'boolean', 'JSON::PP::Boolean', 'JSON::XS::Boolean' ]
	| ScalarRef[ Enum[ 0, 1 ] ]
	| Value->create_child_type(
		name       => 'PerlNativeBoolean',
		constraint => sub { builtin::is_bool($_) },
		inlined    => sub { my $var = pop; qq{do{ use experimental 'builtin'; builtin::is_bool($var) }} },
	);

declare JTrue,
	as JBoolean,
	where { ( 'SCALAR' eq ( ref $_ or '' ) ) ? $$_ : $_ },
	inline_as {
		my $var = $_;
		my $parent = $_[0]->parent->inline_check( $var );
		qq{$parent and ( 'SCALAR' eq ( ref $var or '' ) ) ? \${$var} : $var}
	};

declare JFalse,
	as JBoolean,
	where { ( 'SCALAR' eq ( ref $_ or '' ) ) ? !$$_ : !$_ },
	inline_as {
		my $var = $_;
		my $parent = $_[0]->parent->inline_check( $var );
		qq{$parent and ( 'SCALAR' eq ( ref $var or '' ) ) ? !\${$var} : !$var}
	};

declare JObject,
	as HashRef;

declare JArray,
	as ArrayRef;

declare JNumber,
	as Num,
	where { builtin::created_as_number( $_ ) },
	inline_as { ( Value->inline_check($_), qq{do{ use experimental 'builtin'; builtin::created_as_number( $_ ) }} ) };

declare JInteger,
	as JNumber,
	where { int($_) == $_ },
	inline_as { ( undef, qq{int($_) == $_} ) };

declare JString,
	as Str,
	where { builtin::created_as_string( $_ ) },
	inline_as { ( Value->inline_check($_), qq{do{ use experimental 'builtin'; builtin::created_as_string( $_ ) }} ) };

declare JAny,
	as JNull | JBoolean | JObject | JArray | JNumber | JString;

my %primative_name_to_type = (
	null     => JNull,
	boolean  => JBoolean,
	object   => JObject,
	array    => JArray,
	number   => JNumber,
	string   => JString,
);

declare JSPrimativeName,
	as Enum[ sort keys %primative_name_to_type ];

declare JSPrimativeType,
	as InstanceOf->of('Type::Tiny')->with_attribute_values(
		library => Enum[ 'Types::JSONSchema::PrimativeTypes' ],
		name    => Enum[ sort map $_->name, values %primative_name_to_type ],
	);

coerce JSPrimativeType,
	from JSPrimativeName, via { $primative_name_to_type{$_} },
	from Enum['integer'], via { JInteger };

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::JSONSchema::PrimativeTypes - primative types supported by JSON

=head1 SYNOPSIS

  use Types::JSONSchema::PrimativeTypes -all;
  
  assert_JNumber( 55.5 );
  assert_JBoolean( \1 );
  assert_JObject( [] );     # dies

=head1 DESCRIPTION

This is a L<Type::Library> exporting L<Type::Tiny> type constraints.

=head2 Types

=head3 Primative Types

Note that the primative types are disjoint. Any given value can only
satisfy at most one of them. The string "1" is a B<JString>, but
I<not> a B<JBoolean> or a B<JNumber>.

=over

=item B<JNull>

Accepts undef only.

=item B<JBoolean>

Accepts C<builtin::true>, C<builtin::false>, and instances of L<boolean>,
L<JSON::PP::Boolean>, or L<JSON::XS::Boolean>. Also accepts C<< \0 >> and
C<< \1 >> which are supposed to be interpreted as false and true respectively,
though Perl will interpret C<< \0 >> as true, making C<is_JTrue> and
C<is_JFalse> useful!

=item B<JNumber>

Any valid number. This type I<does> differentiate between "1" and 1
using the C<created_as_number> and C<created_as_string> functions from
L<builtin>.

=item B<JString>

Accepts any string. This type I<does> differentiate between "1" and 1
using the C<created_as_number> and C<created_as_string> functions from
L<builtin>.

=item B<JArray>

Accepts any unblessed arrayref.

=item B<JObject>

Accepts any unblessed hashref.

=back

=head3 Derived Types

=over

=item B<JTrue>

Subtype of B<JBoolean> for true values only. Accepts the following values:
C<< boolean::true >>, C<< JSON::PP::true >>, C<< JSON::XS::true >>,
C<< builtin::true >> (or C<< !!1 >> which is the same thing), and C<< \1 >>.

C<< if is_JTrue($value) >> is safer than C<< if $value >> because it
will recognize C<< \0 >> as being false.

=item B<JFalse>

Subtype of B<JBoolean> for false values only. Accepts the following values:
C<< boolean::false >>, C<< JSON::PP::false >>, C<< JSON::XS::false >>,
C<< builtin::false >> (or C<< !!0 >> which is the same thing), and C<< \0 >>
(which Perl would normally interpret as being true!).

C<< if is_JFalse($value) >> is safer than C<< if !$value >> because it
will recognize C<< \0 >> as being false.

=item B<JInteger>

Any B<JNumber> with no fractional part. 1 and 1.000 are both considered
integers.

=item B<JAny>

The union of all primative types.

=back

=head3 Internal Types

=over

=item B<JSPrimativeName>

Mostly for internal use. Accepts the literal strings "null", "boolean",
"number", "string", "array", and "object".

=item B<JSPrimativeType>

Mostly for internal use. Accepts a blessed L<Type::Tiny> object corresponding
to one of the six primative types. Has a coercion from B<JSPrimativeName>
and also coerces "integer" to B<JInteger>.

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-types-jsonschema/issues>.

=head1 SEE ALSO

L<Types::JSONSchema>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
