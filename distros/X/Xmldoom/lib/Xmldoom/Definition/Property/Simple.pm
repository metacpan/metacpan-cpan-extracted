
package Xmldoom::Definition::Property::Simple;
use base qw(Xmldoom::Definition::Property);

use strict;

use Data::Dumper;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $parent;
	my $prop_name;
	my $attr_name;
	my $trans_to;
	my $trans_from;
	my $set_name;
	my $get_name;
	my $options;
	my $options_table;
	my $options_column;
	my $options_criteria;
	my $inclusive;

	if ( ref($args) eq 'HASH' )
	{
		$parent           = $args->{parent};
		$prop_name        = $args->{name};
		$attr_name        = $args->{attribute};
		$trans_to         = $args->{trans_to};
		$trans_from       = $args->{trans_from};
		$set_name         = $args->{set_name};
		$get_name         = $args->{get_name};
		$options          = $args->{options};
		$options_table    = $args->{options_table};
		$options_column   = $args->{options_column};
		$options_criteria = $args->{options_criteria};
		$inclusive        = $args->{inclusive};
	}
	else
	{
		$parent    = $args;
		$prop_name = shift;
		$attr_name = shift;

		# if you don't know, then there is no need to know.
		$args = {
			parent => $parent,
			name   => $prop_name,
		};
	}

	# allow a short form when we want the property name
	# to be the same as the attribute name.
	if ( not defined $attr_name )
	{
		$attr_name = $prop_name;
	}

	# TODO: use the $parent variable to check if we are creating a valid 
	# property with a valid attribute.

	# the default get/set names
	if ( not defined $set_name )
	{
		$set_name = "set_$prop_name";
	}
	if ( not defined $get_name )
	{
		$get_name = "get_$prop_name";
	}

	# init our members
	my $self = $class->SUPER::new( $args );
	$self->{attr_name}        = $attr_name;
	$self->{trans_to}         = $trans_to;
	$self->{trans_from}       = $trans_from;
	$self->{set_name}         = $set_name;
	$self->{get_name}         = $get_name;
	$self->{options}          = $options   || [ ];
	$self->{options_table}    = $options_table;
	$self->{options_column}   = $options_column;
	$self->{options_criteria} = $options_criteria;
	$self->{inclusive}        = $inclusive || 0;

	bless  $self, $class;
	return $self;
}

sub get_type       { return "inherent"; }
sub get_attribute  { return shift->{attr_name}; }
sub get_trans_to   { return shift->{trans_to}; }
sub get_trans_from { return shift->{trans_from}; }

sub get_autoload_get_list
{
	return [ shift->{get_name} ];
}

sub get_autoload_set_list
{
	return [ shift->{set_name} ];
}

sub get_data_type
{
	my $self = shift;
	my $args = shift;

	my $include_options = 0;

	if ( ref($args) eq 'HASH' )
	{
		$include_options = $args->{include_options};
	}

	my $table  = $self->get_parent()->get_table();
	my $column = $table->get_column( $self->{attr_name} );
	my $value  = $table->get_column_type( $self->{attr_name} );

	if ( not defined $value )
	{
		die "Unable to determine datatype of column $self->{attr_name} of type $column->{type}";
	}

	# pass these along
	$value->{hints}   = $self->{hints};
	$value->{default} = $self->{default};

	# if inclusive options are set we want to return a list of those...
	if ( $self->{inclusive} and $include_options )
	{
		# copy the manual ones in
		$value->{options} = [ @{$self->{options}} ];

		# check to see if we need to pull anything from the database
		if ( defined $self->{options_table} and defined $self->{options_column} )
		{
			my $foreign_key = $self->get_parent()->get_table()->get_foreign_key( $self->{attr_name} );
			my $value_attr  = join '/', $foreign_key->{foreign_table}, $foreign_key->{foreign_column};
			my $desc_attr   = join '/', $self->{options_table}, $self->{options_column};
			my $database    = $self->get_parent()->get_database();

			my $criteria;

			if ( $self->{options_criteria} )
			{
				$criteria = $self->{options_criteria}->clone();
			}
			else
			{
				$criteria = Xmldoom::Criteria->new();
			}

			my $rs = $database->SearchRS( $criteria, $value_attr, $desc_attr );

			$value->{options} = [ ];
			while ( $rs->next() )
			{
				my $row = $rs->get_row();

				my $val   = $row->{$foreign_key->{foreign_column}};
				my $desc  = $row->{$self->{options_column}};

				my $set = 0;

				# check to see if we manually set this one and then use that one
				foreach my $manual_opt ( @{$self->{options}} )
				{
					if ( $manual_opt->{value} eq $value )
					{
						$set = 1;
					}
				}

				# add this guy from the database
				if ( not $set )
				{
					push @{$value->{options}}, { value => $val, description => $desc };
				}
			}
		}
	}

	return $value;
}

sub get_value_description
{
	my ($self, $value) = @_;

	# first try the options that we have manually added to property
	foreach my $opt ( @{$self->{options}} )
	{
		if ( $opt->{value} eq $value )
		{
			return $opt->{description};
		}
	}

	# second, attempt to pull from a translation table if information to do so
	# is available.
	if ( defined $self->{options_table} and defined $self->{options_column} )
	{
		my $database   = $self->get_parent()->get_database();
		my $table_name = $self->get_parent()->get_table_name();
		my $self_attr  = join '/', $table_name, $self->{attr_name};
		my $desc_attr  = join '/', $self->{options_table}, $self->{options_column};

		# TODO: should we here use the $self->{options_criteria}.
		# our criteria is that this properties attribute must equal the given value!
		my $criteria = Xmldoom::Criteria->new();
		$criteria->add_attr( $self_attr, $value );

		# grab the value
		my $rs = $database->SearchRS( $criteria, $desc_attr );
		if ( $rs->next() )
		{
			my $row = $rs->get_row();
			return $row->{$self->{options_column}};
		}
	}

	return undef;
}

sub trans_to
{
	my ($self, $value) = @_;

	if ( $self->{trans_to} )
	{
		if ( not exists $self->{trans_to}->{$value} )
		{
			die sprintf "Trying to use invalid value '$value' for the '%s' property", $self->get_name();
		}

		$value = $self->{trans_to}->{$value};
	}

	return $value;
}

sub trans_from
{
	my ($self, $value) = @_;

	if ( $self->{trans_from} )
	{
		$value = $self->{trans_from}->{$value};
	}

	return $value;
}

sub get
{
	my ($self, $object) = @_;

	return $self->trans_from( $object->_get_attr($self->{attr_name}) );
}

sub set
{
	my ($self, $object, $value) = @_;

	$object->_set_attr( $self->{attr_name}, $self->trans_to($value) );
}

sub get_query_lval
{
	my $self = shift;

	my $table_name  = $self->{parent}->get_table_name();
	my $column_name = $self->{attr_name};

	return [ DBIx::Romani::Query::SQL::Column->new( $table_name, $column_name ) ];
}

sub get_query_rval
{
	my ($self, $value) = @_;

	return [ DBIx::Romani::Query::SQL::Literal->new( $self->trans_to($value) ) ];
}

sub autoload
{
	my ($self, $object, $func_name, $value) = @_;

	if ( $func_name eq $self->{set_name} )
	{
		$self->set($object, $value);
	}
	elsif ( $func_name eq $self->{get_name} )
	{
		return $self->get($object);
	}
	else
	{
		die "$func_name is not defined by this property";
	}
}

1;

