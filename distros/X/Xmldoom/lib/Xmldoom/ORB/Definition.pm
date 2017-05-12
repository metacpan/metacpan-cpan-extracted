
package Xmldoom::ORB::Definition;

use Xmldoom::ORB::Definition::JSON;
use strict;

use Data::Dumper;

sub generate_object_hash
{
	my $object = shift;

	my $data = {
		attributes => [ ],
		key_names  => [ ],
		properties => [ ],
	};

	foreach my $column ( @{$object->get_table()->get_columns()} )
	{
		my $type = $object->get_table()->get_column_type( $column->{name} );

		my $attr_data = {
			name    => $column->{name},
			default => undef,
		};

		if ( $type->{type} eq 'string' or $type->{type} eq 'date' )
		{
			if ( defined $column->{default} )
			{
				$attr_data->{default} = $column->{default};
			}
			else
			{
				$attr_data->{default} = "";
			}
		}
		elsif ( ($type->{type} eq 'integer' or $type->{type} eq 'float')
				and defined $column->{default} )
		{
			$attr_data->{default} = $column->{default};
		}

		push @{$data->{attributes}}, $attr_data;

		# add to the keys if necessary
		if ( $column->{primary_key} )
		{
			push @{$data->{key_names}}, $column->{name};
		}
	}

	foreach my $prop ( @{$object->get_properties()} )
	{
		if ( not $prop->isa('Xmldoom::Definition::Property::Simple') and
			 not $prop->isa('Xmldoom::Definition::Property::Object') )
		{
			# TODO: Then it is a 'custom' property which needs to be called 
			# into the ORB to get/set it.
			next;
		}
		
		my $prop_data = {
			name      => $prop->get_name(),
			get_names => $prop->get_autoload_get_list(),
			set_names => $prop->get_autoload_set_list(),
		};

		if ( $prop->isa('Xmldoom::Definition::Property::Simple') )
		{
			$prop_data->{type}       = 'simple';
			$prop_data->{attribute}  = $prop->get_attribute();
			$prop_data->{trans_to}   = $prop->get_trans_to();
			$prop_data->{trans_from} = $prop->get_trans_from();
		}
		elsif ( $prop->isa('Xmldoom::Definition::Property::Object' ) )
		{
			$prop_data->{type}        = 'object';
			$prop_data->{object_name} = $prop->get_object_name();
			$prop_data->{object_type} = $prop->get_type();
			$prop_data->{connections} = [ ];

			my $link = $prop->get_link();
		
			# TODO: hock for inter-table, where (for now) we don't want to 
			# pass many-to-many links to Javascript.
			if ( $link->get_relationship() ne 'many-to-many' )
			{
				foreach my $key ( @{$link->get_foreign_keys()} )
				{
					foreach my $ref ( @{$key->get_column_names()} )
					{
						push @{$prop_data->{connections}}, {
							self  => $ref->{local_column},
							other => $ref->{foreign_column},
						};
					}
				}
			}
		}

		push @{$data->{properties}}, $prop_data;
	}

	return $data;
}

sub generate
{
	my ($database, $type) = (shift, shift);

	if ( not defined $type )
	{
		# TODO: this should default to XML, however, I haven't written that
		# yet!
	}

	if ( $type eq 'json' )
	{
		return Xmldoom::ORB::Definition::JSON::generate($database);
	}
	else
	{
		die "Can't generate ORB definition for unknown type '$type'";
	}
}

1;

