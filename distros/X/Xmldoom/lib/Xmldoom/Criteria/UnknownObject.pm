
package Xmldoom::Criteria::UnknownObject;

use Carp;
use strict;

sub new
{
	my $class = shift;
	my $key   = shift;

	my $self = {
		key => $key
	};

	bless  $self, $class;
	return $self;
}

sub create_object
{
	my $self = shift;
	my $args = shift;

	my $database;
	my $object_name;

	if ( ref($args) eq 'HASH' )
	{
		$database    = $args->{database};
		$object_name = $args->{object};
	}
	else
	{
		$database    = $args;
		$object_name = shift;
	}

	my $definition = $database->get_object( $object_name );
	my $class      = $definition->get_class();

	#print STDERR "CREATING UNKNOWN: $class $object_name\n";

	my $object = $class->load( $self->{key} );

	return $object;
}

1;

