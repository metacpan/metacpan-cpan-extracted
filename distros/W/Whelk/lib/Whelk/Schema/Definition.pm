package Whelk::Schema::Definition;
$Whelk::Schema::Definition::VERSION = '0.06';
use Whelk::StrictBase;
use Carp;
use Kelp::Util;
use Scalar::Util qw(blessed);
use Storable qw(dclone);
use Data::Dumper;
use JSON::PP;

# no import loop, load Whelk::Schema for child classes
require Whelk::Schema;

attr name => undef;
attr '?required' => !!1;
attr '?description' => undef;

sub create
{
	my ($class, $args) = @_;

	return $class->_build($args);
}

sub new
{
	my ($class, %args) = @_;

	# don't allow to set the name through the constructor. This would not
	# correctly register the schema. Schemas are correctly built and registered
	# through Whelk::Schema factory.
	delete $args{name};

	my $self = $class->SUPER::new(%args);

	$self->_resolve;
	return $self;
}

sub _bool
{
	return pop() ? JSON::PP::true : JSON::PP::false;
}

sub _resolve { }

sub _build
{
	my ($self, $item) = @_;

	if (blessed $item && $item->isa(__PACKAGE__)) {
		return $item;
	}
	if (ref $item eq 'SCALAR') {
		return Whelk::Schema->get_by_name($$item);
	}
	elsif (ref $item eq 'ARRAY') {
		my ($type, @rest) = @$item;
		my $ret = $self->_build($type)->clone(@rest);
		return $ret;
	}
	elsif (ref $item eq 'HASH') {
		my $type = delete $item->{type};
		croak 'no schema definition type specified'
			unless defined $type;

		my $class = __PACKAGE__;
		$type = ucfirst $type;

		return Kelp::Util::load_package("${class}::${type}")->new(%$item);
	}
	else {
		croak 'can only build a definition from SCALAR, ARRAY or HASH';
	}
}

sub clone
{
	my ($self, %more_data) = @_;
	my $class = ref $self;

	# NOTE: since cloning uses the constructor, the name is automatically
	# removed from the resulting object.

	my $data = dclone({%{$self}});
	$data = Kelp::Util::merge($data, \%more_data, 1);
	return $class->new(%$data);
}

sub empty
{
	return !!0;
}

sub has_default
{
	return !!0;
}

sub inhale_exhale
{
	my ($self, $data, $error_sub) = @_;

	$self->inhale_or_error($data, $error_sub);
	return $self->exhale($data);
}

sub inhale_or_error
{
	my ($self, $data, $error_sub) = @_;

	my $inhaled = $self->inhale($data);
	if (defined $inhaled) {
		$error_sub->($inhaled)
			if ref $error_sub eq 'CODE';

		# generic error in case $error_sub was not passed or did not throw
		my $class = ref $self;
		die "incorrect data for $class ($inhaled): " . Dumper($data);
	}

	return undef;
}

sub openapi_schema
{
	my ($self, $openapi_obj, %hints) = @_;

	if ($self->name && !$hints{full}) {
		return {
			'$ref' => $openapi_obj->location_for_schema($self->name),
		};
	}
	else {
		return $self->openapi_dump($openapi_obj, %hints);
	}
}

sub openapi_dump
{
	my ($self, $obj, %hints) = @_;
	...;
}

sub exhale
{
	my ($self, $value) = @_;
	...;
}

sub inhale
{
	my ($self, $value) = @_;
	...;
}

1;

__END__

=pod

=head1 NAME

Whelk::Schema::Definition - Base class for a Whelk type

=head1 SYNOPSIS

	my $definition = Whelk::Schema->build(
		name => {
			type => 'integer',
		}
	);

=head1 DESCRIPTION

Definition is a base class for schemas. L<Whelk::Schema> is just a factory and
register for definitions. This class is abstract and does not do anything by
itself, but a number of subclasses exist which implement different OpenAPI
types.

Definitions use names I<inhale> to describe data validation and I<exhale> for
data coercion. Inhaling is recursively checking the entire input to see if it
conforms to the definition. Exhaling is recursively adjusting the entire output
structure so that it has all the values in line with the definition (for
example, changing a C<boolean> field to a real boolean on endpoint output).
Exhaling is not a standalone process, as it assumes data was inhaled previously
- exhaling without inhaling can lead to problems like warnings or even fatal
errors.

Inhaling will short-circuit if it encounters an error and return a string which
describes where and what type of problem it encountered. For example, it may
return C<'boolean'> if a definition was boolean and the value was a string. For
the same boolean definition, the error may also be C<'defined'> if the value
was not defined - the string is not always the name of the type, but rather
which Whelk assumption has failed (which may be a more basic assumption than
the actual type). For nested types like objects it will return something like
C<< 'object[key]->boolean' >>. It should be pretty obvious where the problem is
based on those strings, but since it short circuits it may require a couple of
runs to weed out all the errors.

=head1 ATTRIBUTES

There attributes are common for all definitions.

=head2 name

Name of this schema, cannot be set in the constructor - is only set through
creating a named schema in L<Whelk::Schema/build>.

=head2 required

Whether this definition is required. It's needed for cases where it is nested
inside an object or inside C<parameters> for an endpoint.

=head2 description

OpenAPI description of this definition.

=head1 METHODS

=head2 create

Constructs a definition. Unlike C<new> which only accepts a hash, it does all
the tricks described in L<Whelk::Schema/Defining a schema>. Should not be
called directly, use L<Whelk::Schema/build> instead.

=head2 clone

	my $new = $definition->clone(%more_data);

Clones this definition and optionally merges its contents with C<%more_data>,
if present. The merge is recursive is the done in the same way Kelp config
files are merged. It's used for extending schemas using C<< [\'schema_name',
%args] >> syntax. There should be no need to ever call this directly.

=head2 empty

	my $is_empty = $definition->empty;

Whether this definition is empty. It is a special measure to check for
C<Whelk::Schema::Definition::Empty>, which is implementing C<204 No Content>
responses.

=head2 has_default

Whether this definition has a default value.

=head2 inhale

	my $error_or_undef = $definition->inhale($data);

Must be implemented in a subclass.

Inhales data to see if it likes it. See L</DESCRIPTION> for more data on
inhaling and exhaling.

=head2 exhale

	my $adjusted_data = $definition->exhale($data);

Must be implemented in a subclass.

Exhales the data in form described in the definition. See L</DESCRIPTION> for
more data on inhaling and exhaling.

=head2 inhale_or_error

	$definition->inhale_or_error($data, $error_sub = sub {});

Calls L</inhale> and calls C<$error_sub> if it failed. The sub will get passed
the return value of C<inhale> as its only argument. If the sub is not passed or
does not throw an exception, a stock exception will be thrown with the error
and dumped C<$data>.

=head2 inhale_exhale

	my $adjusted_data = $definition->inhale_exhale($data, $error_sub = sub {});

Both L</inhale> and L</exhale> in one call. Uses L</inhale_or_error> under the
hood, so inhaling errors will throw an exception.

=head2 openapi_dump

	my $perl_struct = $definition->openapi_dump($obj, %hints);

Must be implemented in a subclass.

Returns the structure which describes this type for the OpenAPI document.
Should not be called directly, as it is called by L</openapi_schema>.

=head2 openapi_schema

	my $perl_struct = $definition->openapi_schema($obj, %hints);

Returns the structure which describes this type for the OpenAPI document. It
usually just calls L</openapi_dump>.

C<$obj> should be an object of L<Whelk::OpenAPI> or similar. It should at least
implement method C<location_for_schema>.

C<%hints> are special hints which change how the schema is produced. Currently,
just a couple hints are defined:

If C<full> hint is present and true, the top level definition will be dumped in
full, even if it is a named schema. If not, it will be made a reference to a
predefined schema.

Special C<parameters> hint will change how C<object> is treated, since objects
are used to define all types of parameters of OpenAPI.

