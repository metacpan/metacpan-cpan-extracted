
package Xmldoom::ORB::Definition::JSON;

use Xmldoom::ORB::Definition;
use JSON qw/ objToJson /;
use strict;

sub generate
{
	my $database = shift;

	my $data = [ ];

	#foreach my $object ( @{$database->get_objects()} )
	while ( my ($object_name, $object) = each %{$database->get_objects()} )
	{
		push @$data, {
			name => $object->get_name(),
			%{Xmldoom::ORB::Definition::generate_object_hash($object)}
		};
		#$data->{$object->get_name()} = Xmldoom::ORB::Definition::generate_object_hash($object);
	}

	return objToJson($data);
}

1;

