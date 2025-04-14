package Whelk::Schema;
$Whelk::Schema::VERSION = '1.04';
use Kelp::Base -strict;
use Whelk::Schema::Definition;
use Carp;

our @CARP_NOT = qw(Whelk::Endpoint);

my %registered;

use constant NO_DEFAULT => sub { undef };

sub build_if_defined
{
	my ($class, $args) = @_;

	return undef unless defined $args;
	return $class->build($args);
}

sub build
{
	my ($class, @input) = @_;

	if (@input == 1) {
		croak 'usage: build($args)'
			unless ref $input[0];

		unshift @input, undef;
	}
	else {
		croak 'usage: build(name => $args)'
			unless @input == 2 && !ref $input[0] && ref $input[1];
	}

	my ($name, $args) = @input;
	my $self = Whelk::Schema::Definition->create($args);

	if ($name) {
		$self->name($name);

		croak "trying to reuse schema name " . $self->name
			if $registered{$self->name};

		$registered{$self->name} = $self;
	}

	return $self;
}

sub get_or_build
{
	my ($class, $name, $args) = @_;

	return $registered{$name}
		if $registered{$name};

	return $class->build($name, $args);
}

sub get_by_name
{
	my ($class, $name) = @_;

	croak "no such referenced schema '$name'"
		unless $registered{$name};

	return $registered{$name};
}

sub all_schemas
{
	my ($class) = @_;

	return [values %registered];
}

1;

__END__

=pod

=head1 NAME

Whelk::Schema - Whelk validation language

=head1 SYNOPSIS

	# build from scratch
	Whelk::Schema->build(
		name => {
			type => 'string',
		}
	);

	# build by extending
	Whelk::Schema->build(
		new_name => [
			\'name_to_extend',
			%more_args
		],
	);

=head1 DESCRIPTION

Whelk schema is an easy validation language for defining validations similar to
JSON Schema. It's designed to be a bit more concise and crafted specifically
for Whelk needs.

Whelk schema is used everywhere in Whelk: not only in C<< Whelk::Schema->build
>> calls but also in C<request>, C<response> and C<parameters> keys in
endpoints. Only L</build> allows defining named schemas.

A named schema is global and should have an unique name. The module will not
allow overriding a named schema. All named schemas will be put into the OpenAPI
document, in C<compontents/schemas> object, using their defined names.

=head2 Defining a schema

There are a couple of ways to define a schema, listed below. All of them can be
used at every nesting level, so for example you can use a reference to a schema
inside C<properties> of an C<object> schema created with hash.

=head3 New schema using hash reference

	{ # new schema, level 0
		type => 'array',
		items => { # new schema, level 1
			type => 'object',
			properties => { # reused schema, level 2
				some_field => \'named_schema'
			},
		},
	}

By passing a C<HASH> reference you are creating a completely new schema.
C<type> field is required and must be one of the available types, in lowercase.

Schema declared this way will be put into the OpenAPI document as-is, without
referencing any other schema.

=head3 Reusing schemas with scalar reference

	# reusing a named schema
	\'name'

By passing a C<SCALAR> reference you are reusing a named schema. The name must
exist beforehand or else an exception will be raised.

Schema declared this way will be put into the OpenAPI document as a reference
to a schema inside C<components/schemas> object.

=head3 Extending schemas with array reference

	# extending a named schema
	[
		\'name',
		required => !!0,
	]

By passing an C<ARRAY> reference you are extending an named schema. The first
argument must be a C<SCALAR> reference with the name of the schema to extend.
Rest of the arguments are configuration which should be replaced in the
extended schema. C<type> cannot be replaced.

Schema declared this way will be put into the OpenAPI document as-is, without
referencing any other schema.

=head3 Reusable schemas without OpenAPI trace

All methods above will leave a trace in your OpenAPI output, which may not be
what you want. If you for example just want to use a list of properties across
a couple of objects, you may want to use a regular hash instead:

	my %common_fields = (
		name => {
			type => 'string',
		},
		age => {
			type => 'integer',
		},
	);

	Whelk::Schema->build(
		person => {
			type => 'object,
			properties => {
				%common_fields,
				id => {
					type => 'integer',
					nullable => !!1,
				},
			},
		}
	);

This should work well as presented, but since Whelk does not usually deep-clone
its input before using it, some nested parts of C<%common_fields> may get
changed or blessed. Don't rely on its contents being exactly as you defined it,
or deep-clone it yourself before passing it to Whelk.

=head2 Where to define the schemas?

It is not important where your schemas are defined, as long as they are defined
before they are used. Whelk provides C<schemas> method as syntax sugar, which
will be called just once for each controller. That does not mean schemas must
be defined there, they may as well be called at the package level (during
package compilation) or anywhere else.

You can use it to your advantage when creating schemas which should be used for
the entire application, not just for one controller. It can safely be put in a
separate package, or even in the C<app.psgi> itself (even though it's surely
not a good place to keep them).

=head2 Available types

Each new schema must have a C<type> defined. All types share these common configuration values:

=over

=item * required

Boolean - whether the value is required to be present. C<true> by default.

=item * nullable

Boolean - whether the value can be null (but present). C<false> by default.

=item * description

String - an optional description used for the schema in the OpenAPI document.

=item * rules

An array reference of hashes. See L</Extra rules>.

=back

=head3 null

A forced C<undef> value.

No special configuration.

=head3 empty

This is a special type used to implement C<204 No Content> responses. It is
only valid at the root of C<response> and should not be used in any other
context.

No special configuration.

=head3 string

A string type. The value must not be a reference and the output will be coerced
to a string value. Unlike JSON schema, this also accepts numbers.

Extra configuration fields:

=over

=item * default

A default value to be used when there is no value. Also assumes C<< required => !!0 >>.

CAUTION: Whelk does not differentiate null value and no value. If you specify
default, a received null value will get replaced with that default. To
explicitly say that there is no default, use C<Whelk::Schema::NO_DEFAULT>.

=item * example

An optional example used for the schema in the OpenAPI document.

=back

=head3 boolean

A boolean type. Will coerce the output value to JSON::PP::true and
JSON::PP::false objects.

Same extra configuration as in L</string>.

=head3 number

A numeric type. Will coerce the output value to a number. Unlike JSON schema,
this also accepts strings as long as they contain something which looks like a
number.

Same extra configuration as in L</string>.

=head3 integer

Same as L</number>, but will not accept numbers with fractions.

=head3 array

This is an array type, which will only accept array references.

Extra configuration fields:

=over

=item * items

An optional type to use for each of the array elements. This is a nested
schema, and all ways to define a schema discussed in L</Defining a schema> will
work.

=item * lax

This is a special boolean flag used to accept array C<parameters> of type
C<query> and C<header>. If present and true, the type will also accept a
non-array input and turn it into an array with one element. Should probably
only use it within C<parameters> structure of the endpoint.

=back

=head3 object

This is a hash type, which will only accept hash references. Unlike JSON
schema, it's C<required> is not an array of required elements - instead the
required elements will be taken from C<required> flag of its C<properties>.

Extra configuration fields:

=over

=item * properties

An optional dictionary to use for the keys in the object. If it's not
specified, the object can contain anything. This is a nested schema, and all
ways to define a schema discussed in L</Defining a schema> will work.

=item * strict

This is a special boolean flag used to make any schema which does contain extra
keys as those specified in C<properties> incorrect. By default, the hash can
contain any number of extra keys and will be considered correct. Note that the
schema will still only copy the keys which were defined, so this is usually not
required.

=back

=head2 Extra rules

Whelk does not define a full JSONSchema spec with all its rules. To allow
configuration, you can specify extra rules when needed which will be used
during validation and may optionally add some keys to the OpenAPI spec of that
field. While all field types allow defining extra rules, it makes little sense
to use them for types C<boolean>, C<null> and C<empty> - rules will do nothing
for them.

An example of adding some rules is showcased below:

	{
		type => 'integer',
		rules => [
			{
				openapi => {
					minimum => '5',
				},
				hint => '(>=5)',
				code => sub {
					my $value = shift;

					return $value >= 5;
				},
			},
		],
	}

As shown, a C<rules> array reference may be defined, containing hash
references. Each rule (represented by a hash reference) must contain C<hint> (a
very short error message notifying the end user what's wrong), C<code> (a sub
reference, which will be passed the value and must return C<true> if the value
is valid) and optionally C<openapi> (a hash reference, containing keys which
will be added to OpenAPI document).

There may be multiple rules in each field, and each rule can contain multiple
C<openapi> keys (but only a single C<code> and C<hint>). This system is very
bare-bones and a bit verbose, but it makes it very easy to write your own
library of validations, implementing the parts of JSONSchema you need (or even
the full schema - please publish to CPAN if you do!). Just write a function
which will return a given hash reference and it becomes quite powerful:

	sub greater_or_equal
	{
		my ($arg) = @_;

		return {
			openapi => {
				minimum => $arg,
			},
			hint => "(>=$arg)",
			code => sub { shift() >= $arg },
		};
	}

	... then
	{
		type => 'integer',
		rules => [
			greater_or_equal(5),
		],
	}

=head1 METHODS

This is a list of factory methods implemented by C<Whelk::Schema>.

=head2 build

Builds a schema and returns L<Whelk::Schema::Definition>.

=head2 build_if_defined

Same as L</build>, but will not throw an exception if an undef is passed.
Instead, returns undef.

=head2 get_by_name

Gets a named schema by name and returns L<Whelk::Schema::Definition>.

=head2 get_or_build

A mix of L</build> and L</get_by_name>. Tries to get a schema by name, and
builds it if it was not defined yet.

=head2 all_schemas

Returns all named schemas defined thus far.

=head1 SEE ALSO

L<Whelk::Manual>

