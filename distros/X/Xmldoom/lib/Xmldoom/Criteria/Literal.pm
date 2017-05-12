
package Xmldoom::Criteria::Literal;

use Xmldoom::Object;
use DBIx::Romani::Query::SQL::Literal;
use strict;

sub new
{
	my $class = shift;

	my $value = shift;

	my $self = {
		value => $value,
	};

	bless  $self, $class;
	return $self;
}

sub get_value
{
	my ($self, $database, $lval) = @_;

	# create the actual object when dealing with an unknown.
	if ( ref($self->{value}) and $self->{value}->isa('Xmldoom::Criteria::UnknownObject') )
	{
		my $object = $database->get_object( $lval->get_object_name() );
		my $prop   = $object->get_property( $lval->get_property_name() );

		$self->{value} = $self->{value}->create_object( $database, $prop->get_object_name() );
	}

	return $self->{value};
}

sub get_query_lval
{
	my ($self, $database) = @_;

	die "Literal cannot be used as an lval";
}

sub get_query_rval
{
	my ($self, $database, $lval) = @_;

	my $value = $self->get_value( $database, $lval );

	if ( $lval->isa( 'Xmldoom::Criteria::Property' ) )
	{
		my $object = $database->get_object( $lval->get_object_name() );
		my $prop   = $object->get_property( $lval->get_property_name() );

		# here we "cast" the literal into the correct type
		return $prop->get_query_rval( $value );
	}
	else
	{
		return [ DBIx::Romani::Query::SQL::Literal->new( $value ) ];
	}
}

sub get_tables
{
	# literals don't have any tables!
	return [ ];
}

sub clone
{
	my $self = shift;

	return Xmldoom::Criteria::Literal->new( $self->get_value() );
}

1;

