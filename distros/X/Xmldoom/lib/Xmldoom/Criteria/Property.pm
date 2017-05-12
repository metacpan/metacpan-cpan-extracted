
package Xmldoom::Criteria::Property;

use Xmldoom::Criteria;
use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $object_name;
	my $property_name;

	if ( ref($args) eq 'HASH' )
	{
		$object_name   = $args->{object_name};
		$property_name = $args->{property_name};
	}
	else
	{
		($object_name, $property_name) = split '/', $args;
	}

	my $self = {
		object_name   => $object_name,
		property_name => $property_name
	};

	bless  $self, $class;
	return $self;
}

sub get_object_name   { return shift->{object_name}; }
sub get_property_name { return shift->{property_name}; }

sub get_query_lval
{
	my ($self, $database) = @_;

	my $object = $database->get_object( $self->get_object_name() );
	my $prop   = $object->get_property( $self->get_property_name() );

	if ( $prop->get_type() eq 'external' )
	{
		die "Cannot search against an external property!";
	}

	return $prop->get_query_lval();
}

sub get_query_rval
{
	my ($self, $database, $lval) = @_;

	if ( not $lval->isa( 'Xmldoom::Criteria::Property' ) )
	{
		die "A Property rvalue cannot be cast into anyother type.";
	}

	return $self->get_query_lval( $database );
}

sub get_tables
{
	my ($self, $database) = @_;

	my $object = $database->get_object( $self->get_object_name() );
	my $prop   = $object->get_property( $self->get_property_name() );

	return $prop->get_tables();
}

sub clone
{
	my $self = shift;

	return Xmldoom::Criteria::Property->new({
		object_name   => $self->get_object_name(),
		property_name => $self->get_property_name()
	});
}

1;

