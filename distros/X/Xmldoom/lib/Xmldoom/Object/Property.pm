
package Xmldoom::Object::Property;

use Scalar::Util qw(weaken);
use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $definition;
	my $object;

	if ( ref($args) eq 'HASH' )
	{
		$definition = $args->{definition};
		$object     = $args->{object};
	}
	else
	{
		$definition = $args;
		$object     = shift;
	}

	my $self = {
		definition  => $definition,
		object      => $object,
		object_data => { },
	};

	if ( defined $self->{object} )
	{
		weaken( $self->{object} );
	}

	bless  $self, $class;
	return $self;
}

sub get_definition { return shift->{definition}; }
sub get_name       { return shift->{definition}->get_name(); }
sub get_type       { return shift->{definition}->get_type(); }

sub get_data_type
{
	my $self = shift;
	my $args = shift;

	if ( ref($args) ne 'HASH' )
	{
		$args = { };
	}

	# we want to pass our object along, in case the property
	# options are dependent.
	$args->{object} = $self->{object};

	return $self->{definition}->get_data_type($args);
}

sub get_options
{
	my $self = shift;

	return $self->{definition}->get_options($self->{object});
}

sub set
{
	my $self = shift;
	my $args = shift;
	$self->{definition}->set( $self->{object}, $args, $self->{object_data} );
}

sub get
{
	my $self = shift;
	my $args = shift;
	return $self->{definition}->get( $self->{object}, $args, $self->{object_data} );
}

sub get_hint
{
	my ($self, $name) = @_;
	return $self->{definition}->get_hint( $name );
}

sub get_pretty
{
	my $self = shift;

	my $value = $self->{definition}->get( $self->{object}, $self->{object_data} );
	my $desc  = $self->{definition}->get_value_description( $value );

	if ( defined $desc )
	{
		$value = $desc;
	}

	return $value;
}

sub get_autoload_list
{
	my $self = shift;

	return [
		@{$self->{definition}->get_autoload_get_list()},
		@{$self->{definition}->get_autoload_set_list()}
	];
}

sub autoload
{
	my ($self, $func_name, $arg) = (shift, shift, shift);
	return $self->{definition}->autoload( $self->{object}, $func_name, $arg, $self->{object_data} );
}

1;

