
package Xmldoom::Definition::Property::Object;
use base qw(Xmldoom::Definition::Property);

use DBIx::Romani::Query::Variable;
use DBIx::Romani::Query::SQL::Column;
use Module::Runtime qw(use_module);
use Scalar::Util qw(weaken isweak);
use Exception::Class::TryCatch;
use strict;

use Data::Dumper;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $parent;
	my $prop_name;
	my $object_name;
	my $set_name;
	my $get_name;
	my $options_prop;
	my $options_criteria;
	my $options_dependent;
	my $inclusive;
	my $inter_table;
	my $key_attributes;

	if ( ref($args) eq 'HASH' )
	{
		$parent            = $args->{parent};
		$prop_name         = $args->{name};
		$object_name       = $args->{object_name};
		$set_name          = $args->{set_name};
		$get_name          = $args->{get_name};
		$options_prop      = $args->{options_property};
		$options_criteria  = $args->{options_criteria};
		$options_dependent = $args->{options_dependent};
		$inclusive         = $args->{inclusive};
		$inter_table       = $args->{inter_table};
		$key_attributes    = $args->{key_attributes};
	}
	else
	{
		$parent      = $args;
		$prop_name   = shift;
		$object_name = shift;

		$args = {
			parent => $parent,
			name   => $prop_name,
		};
	}

	# create ourself
	my $self = $class->SUPER::new( $args );

	#
	# Find our link to the object
	#

	my $links = $parent->find_links( $object_name );
	my $link;

	if ( scalar @$links == 0 )
	{
		die $self->{name} . ": There is no link between " . $parent->get_name() . " and " . $object_name . ".  Did you forget to setup a foreign-key?";
	}
	elsif ( scalar @$links > 1 )
	{
		if ( not defined $key_attributes and not defined $inter_table )
		{
			die $self->{name} . ": It is ambiguous which connection to the foreign object is intended in this property.  You must specify a <key/> section to your <object/> property.";
		}
		else
		{
			foreach my $possible ( @$links )
			{
				if ( defined $key_attributes and $possible->is_start_column_names( $key_attributes ) or
				     defined $inter_table    and $possible->get_start()->get_reference_table_name() )
				{
					$link = $possible;
					last;
				}
			}

			if ( not $link )
			{
				die "It is ambiguous which connection to the foreign object is intended in this property.  The <key/> section or inter_table='...' of this <object/> property is insufficient to disambiguate.";
			}
		}
	}
	else
	{
		if ( defined $key_attributes )
		{
			print STDERR "WARNING: Specifying a key attributes for this object property when it is not ambiguous!\n";
		}

		$link = $links->[0];
	}
	
	if ( defined $inter_table and $link->get_relationship() ne 'many-to-many' )
	{
		die "You set inter_table='...' on this property but it isn't a many-to-many relationship";
	}

	# we need to know how this object relates the other
	my $rel_string;
	if ( defined $link )
	{
		$rel_string = $link->get_relationship();
	}
	else
	{
		# TODO: a hack for inter-table what not
		$rel_string = "many-to-many";
	}

	# get the component parts
	my @rel_parts;
	@rel_parts = split /-/, $rel_string;
	@rel_parts = ( $rel_parts[0], $rel_parts[2] );

	# conditionally prepare autoload names based on property type
	my $prop_type;
	if ( $rel_parts[1] eq 'one' )
	{
		$set_name  = "set_$prop_name" if not defined $set_name;
		$get_name  = "get_$prop_name" if not defined $get_name;
		$prop_type = "inherent";
	}
	elsif ( $rel_parts[1] eq 'many' )
	{
		$set_name  = "add_$prop_name"    if not defined $set_name;
		$get_name  = "get_${prop_name}s" if not defined $get_name;
		$prop_type = "external";
	}

	# store all of our infos
	$self->{object_name}       = $object_name;
	$self->{options_prop}      = $options_prop;
	$self->{options_criteria}  = $options_criteria;
	$self->{options_dependent} = $options_dependent;
	$self->{inclusive}         = $inclusive || 0;
	$self->{inter_table}       = $inter_table;
	$self->{link}              = $link;
	$self->{prop_type}         = $prop_type;
	$self->{set_name}          = $set_name;
	$self->{get_name}          = $get_name;
	$self->{relationship}      = \@rel_parts;

	bless  $self, $class;
	return $self;
}

sub get_type        { return shift->{prop_type}; }
sub get_object_name { return shift->{object_name}; }
sub get_link        { return shift->{link}; }

sub get_autoload_get_list
{
	return [ shift->{get_name} ];
}

sub get_autoload_set_list
{
	return [ shift->{set_name} ];
}

sub get_object_definition
{
	my $self = shift;

	return $self->get_parent()->get_database()->get_object( $self->{object_name} );
}

sub get_object_class
{
	my $self = shift;

	my $class = $self->get_object_definition()->get_class();

	if ( not defined $class )
	{
		die "The object '$self->{object_name}' isn't attached to a Perl class.  Maybe you forgot to 'use' its module?";
	}

	use_module($class);

	return $class;
}

sub get_data_type
{
	my $self = shift;
	my $args = shift;

	my $object;
	my $include_options;

	if ( ref($args) eq 'HASH' )
	{
		$object          = $args->{object};
		$include_options = $args->{include_options};
	}

	my $value = {
		type        => 'object',
		object_name => $self->{object_name},
	};

	# get the selectable options, baby.
	if ( $self->{inclusive} and defined $self->{options_prop} and $include_options )
	{
		$value->{options} = $self->get_options($object);
	}

	return $value;
}

sub get_options
{
	my $self = shift;
	my $object = shift;

	my @options;
	
	if ( defined $self->{options_prop} )
	{
		my $criteria;
		my $parent;

		# use this object as the parent, if the options are dependent on it.
		if ( $self->{options_dependent} )
		{
			$parent = $object;
		}

		# use the options criteria if specified
		if ( defined $self->{options_criteria} )
		{
			$criteria = $self->{options_criteria}->clone( $parent );
		}
		else
		{
			$criteria = Xmldoom::Criteria->new( $parent );
		}

		my $class = $self->get_object_class();

		my $rs = $class->SearchRS( $criteria );
		while ( $rs->next() )
		{
			my $obj  = $rs->get_object();

			push @options, {
				value       => $obj->_get_key(),
				description => $obj->_get_property_value( $self->{options_prop} )
			};
		}
	}

	return \@options;
}

sub get
{
	my ($self, $object, $args, $object_data) = (shift, shift, shift, shift);

	my $database = $self->get_parent()->get_database();
	my $class    = $self->get_object_class();

	if ( $self->get_type() eq 'inherent' )
	{
		if ( defined $object_data->{unsaved_object} and $object_data->{unsaved_object}->{new} )
		{
			return $object_data->{unsaved_object};
		}
		else
		{
			# clear the unsaved object, if it actually exists
			if ( defined $object_data->{unsaved_object} )
			{
				$object_data->{unsaved_object} = undef;
			}
			
			# simply load the data
			my $object_key = { };
			foreach my $conn ( @{$self->{link}->get_column_names()} )
			{
				$object_key->{$conn->{foreign_column}} = $object->_get_attr($conn->{local_column});
			}

			my $data;
			try eval
			{
				$data = $self->get_object_definition()->load( $object_key );
			};
			if ( my $err = catch )
			{
				return undef;
			}

			# return the appropriate object
			return $class->new(undef, {
				data        => $data,
				parent      => $object,
				parent_link => $self->{link}
			});
		}
	}
	elsif ( $self->get_type() eq 'external' )
	{
		my @ret;

		if ( defined $object_data )
		{
			# check the list for undef objects (because they are weak references)
			# and objects that have been saved.
			foreach my $unsaved ( @{$object_data->{unsaved_list}} )
			{
				if ( defined $unsaved and $unsaved->{new} )
				{
					push @ret, $unsaved;
				}
			}
			if ( scalar @{$object_data->{unsaved_list}} != scalar @ret )
			{
				# copy into unsaved if there were any changes
				$object_data->{unsaved_list} = [ @ret ];
			}
		}

		if ( not $object->{new} )
		{
			my $criteria = Xmldoom::Criteria->new( $object );

			# pass any arguments as property equations on the criteria.
			if ( $self->{relationship}->[1] eq 'many' )
			{
				if ( ref($args) eq 'HASH' )
				{
					while( my ($key, $val) = each %$args )
					{
						my $prop = sprintf "%s/%s", $self->{object_name}, $key;
						$criteria->add( $prop, $val );
					}
				}
			}

			# if this is many-to-many, then we manually join the tables because
			# we want to make sure the selected connection is used.
			if ( $self->{link}->get_relationship() eq 'many-to-many' )
			{
				foreach my $fn ( @{$self->{link}->get_foreign_keys()} )
				{
					foreach my $ref ( @{$fn->get_column_names()} )
					{
						$criteria->join_attr(
							sprintf( "%s/%s", $ref->{local_table}, $ref->{local_column} ),
							sprintf( "%s/%s", $ref->{foreign_table}, $ref->{foreign_column} )
						);
					}
				}
			}

			# execute
			@ret = $class->Search( $criteria );
		}

		return wantarray ? @ret : \@ret;
	}
}

sub get_value_description
{
	my ($self, $value) = @_;

	my $prop = $value->_get_property( $self->{options_prop} );

	return $prop->get();
}

sub set
{
	my ($self, $object, $args, $object_data) = @_;

	if ( $self->get_type() eq 'inherent' )
	{
		# we are simply setting a value
		my $value = $args;

		# link the attributes of the value to ours
		foreach my $conn ( @{$self->{link}->get_column_names()} )
		{
			$object->_link_attr( $conn->{local_column}, $value, $conn->{foreign_column} );
		}

		# this object will be saved in the same transaction as us so that no
		# changes are lost.
		$object->_add_dependent( $value );

		# if this value is unsaved, we need to hang onto it
		if ( $value->{new} )
		{
			$object_data->{unsaved_object} = $value;
			weaken $object_data->{unsaved_object};
		}
	}
	elsif ( $self->get_type() eq 'external' )
	{
		# Here we accept an array of hashs (or a single hash), to "add", creating
		# and returning new objects for each.

		if ( ref($args) ne 'ARRAY' )
		{
			$args = [ $args ];
		}

		my $database = $self->get_parent()->get_database();
		my $class    = $self->get_object_class();
		my @ret;

		# create new objects
		foreach my $props ( @$args )
		{
			push @ret, $class->new($props, { parent => $object });
		}

		# create the unsaved objects list
		if ( not defined $object_data->{unsaved_list} )
		{
			$object_data->{unsaved_list} = [ ];
		}

		# add weak references to these new objects in the unsaved objects list
		foreach my $child ( @ret )
		{
			push @{$object_data->{unsaved_list}}, $child;
			weaken $object_data->{unsaved_list}->[-1];
		}

		if ( scalar @$args == 1 )
		{
			return $ret[0];
		}

		return wantarray ? @ret : \@ret;
	}
}

sub get_query_lval
{
	my $self = shift;

	my @ret;
	foreach my $conn ( @{$self->{link}->get_start()->get_column_names()} )
	{
		push @ret, DBIx::Romani::Query::SQL::Column->new( $conn->{local_table}, $conn->{local_column} );
	}

	return \@ret;
}

sub get_query_rval
{
	my ($self, $value) = @_;

	my @ret;
	foreach my $conn ( @{$self->{link}->get_start()->get_column_names()} )
	{
		push @ret, DBIx::Romani::Query::SQL::Literal->new( $value->_get_attr($conn->{foreign_column}) );
	}

	return \@ret;
}

sub autoload
{
	my ($self, $object, $func_name) = (shift, shift, shift);

	if ( $func_name eq $self->{set_name} )
	{
		$self->set($object, @_);
	}
	elsif ( $func_name eq $self->{get_name} )
	{
		return $self->get($object, @_);
	}
	else
	{
		die "$func_name is not defined by this property";
	}
}

1;

