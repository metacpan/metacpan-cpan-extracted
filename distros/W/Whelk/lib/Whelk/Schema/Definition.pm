package Whelk::Schema::Definition;
$Whelk::Schema::Definition::VERSION = '0.02';
use Kelp::Base;
use Carp;
use Kelp::Util;
use Scalar::Util qw(blessed);
use Storable qw(dclone);
use JSON::PP;

# no import loop, load Whelk::Schema for child classes
require Whelk::Schema;

attr name => undef;
attr required => !!1;
attr description => undef;

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
		$error_sub->($inhaled);
		die 'inhale_or_error error subroutine did not throw an exception';
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
	my ($self) = @_;
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

