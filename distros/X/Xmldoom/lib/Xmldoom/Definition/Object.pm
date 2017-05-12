
package Xmldoom::Definition::Object;

use Xmldoom::Threads;
use Exception::Class::TryCatch;
use DBIx::Romani::Query::Select;
use DBIx::Romani::Query::Insert;
use DBIx::Romani::Query::Update;
use DBIx::Romani::Query::Delete;
use DBIx::Romani::Query::Where;
use DBIx::Romani::Query::Comparison;
use DBIx::Romani::Query::Variable;
use DBIx::Romani::Query::SQL::Column;
use DBIx::Romani::Query::SQL::Literal;
use Module::Runtime qw(use_module);
use strict;

use Data::Dumper;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $database;
	my $object_name;
	my $table_name;
	my $shared = 0;
	
	if ( ref($args) eq 'HASH' )
	{
		$database    = $args->{definition};
		$object_name = $args->{object_name};
		$table_name  = $args->{table_name};
		$shared      = $args->{shared};
	}
	else
	{
		$database    = $args;
		$object_name = shift;
		$table_name  = shift;
	}

	my $table = $database->get_table( $table_name );
	if ( not defined $table )
	{
		die "Cannot bind an object to a non-existant table.";
	}

	my $self = {
		database            => $database,
		object_name         => $object_name,
		table_name          => $table_name,
		table               => $table,
		props               => [ ],
		class               => undef,

		# generate on demand
		select_query        => undef,
		select_by_key_query => undef,
		insert_query        => undef,
		update_query        => undef,
		delete_query        => undef,
	};

	bless  $self, $class;
	return Xmldoom::Threads::make_shared($self, $shared);
}

sub get_database   { return shift->{database}; }
sub get_table_name { return shift->{table_name}; }
sub get_table      { return shift->{table}; }
sub get_name       { return shift->{object_name}; }
sub get_properties { return shift->{props}; }
sub get_class      { return shift->{class}; }

sub get_property
{
	my ($self, $prop_name) = @_;

	foreach my $prop ( @{$self->{props}} )
	{
		if ( $prop->get_name() eq $prop_name )
		{
			return $prop;
		}
	}

	die sprintf "Unknown property '%s' on object '%s'", $prop_name, $self->get_name();
}

sub get_reportable_properties
{
	my $self = shift;
	my @list = grep { $_->get_reportable() } @{$self->{props}};
	return wantarray ? @list : \@list;
}

sub get_searchable_properties
{
	my $self = shift;
	my @list = grep { $_->get_searchable() } @{$self->{props}};
	return wantarray ? @list : \@list;
}

sub has_property
{
	my ($self, $prop_name) = @_;

	try eval
	{
		$self->get_property( $prop_name );
	};

	my $error = catch;
	if ( $error )
	{
		return 0;
	}

	return 1;
}

sub set_class
{
	my ($self, $class) = @_;

	if ( defined $self->{class} )
	{
		die "You are trying to redefine an object's class!  Why would anyone want to do that?";
	}

	$self->{class} = $class;
}

sub add_property
{
	my ($self, $prop) = @_;

	# TODO: make sure that this property will actually work, ie. are there
	# any autoload name conflicts.

	# poses problems for running in shared memory because conceivably
	# the object definition could be shared and the property not, which will
	# cause it to be copied and be a different object than what was passed in.
	if ( Xmldoom::Threads::is_shared($self) and not Xmldoom::Threads::is_shared($prop) )
	{
		die "Cannot add a non-shared memory proproperty to a shared memory object definition";
	}

	if ( $self->has_property( $prop->get_name() ) )
	{
		die "Cannot add two properties with the same name";
	}

	push @{$self->{props}}, $prop;
}

sub set_custom_property
{
	my ($self, $name, $prop_class) = @_;

	my $index = 0;
	foreach my $prop ( @{$self->get_properties()} )
	{
		if ( $prop->get_name() eq $name )
		{
			if ( $prop->isa('Xmldoom::Definition::Property::PlaceHolder') )
			{
				# All is thrill chillin
				$self->{props}->[$index] = $prop_class->new( $prop->get_prop_args() );
				return;
			}
			else
			{
				die "Property '$name' exists, but is not designated to be a custom property";
			}
		}

		$index ++;
	}

	die "No such property '$name'";
}

sub class_new
{
	my $self = shift;

	my $class = $self->get_class();

	use_module($class);

	return $class->new( @_ );
}

sub class_load
{
	my $self = shift;

	my $class = $self->get_class();

	use_module($class);

	return $class->load( @_ );
}

sub get_select_query
{
	my $self = shift;

	if ( not defined $self->{select_query} )
	{
		my $query = DBIx::Romani::Query::Select->new();
		$query->add_from( $self->{table_name} );

		# add all the columns 
		foreach my $column ( @{$self->{table}->get_columns()} )
		{
			$query->add_result( DBIx::Romani::Query::SQL::Column->new( $self->{table_name}, $column->{name}) );
		}

		$self->{select_query} = $query;
	}

	return $self->{select_query};
}

sub get_select_by_key_query
{
	my $self = shift;

	if ( not defined $self->{select_by_key_query} )
	{
		my $query = $self->get_select_query()->clone();
		my $where = DBIx::Romani::Query::Where->new( $DBIx::Romani::Query::Where::AND );

		foreach my $column ( @{$self->{table}->get_columns()} )
		{
			if ( $column->{primary_key} )
			{
				my $op = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::EQUAL );
				$op->add( DBIx::Romani::Query::SQL::Column->new( $self->{table_name}, $column->{name} ) );
				$op->add( DBIx::Romani::Query::Variable->new( "$self->{table_name}.$column->{name}" ) );
				$where->add( $op );
			}
		}

		$query->set_where( $where );
		$self->{select_by_key_query} = $query;
	}

	return $self->{select_by_key_query};
}

sub get_insert_query
{
	my $self = shift;

	if ( not defined $self->{insert_query} )
	{
		my $query = DBIx::Romani::Query::Insert->new( $self->{table_name} );

		foreach my $column ( @{$self->{table}->get_columns()} )
		{
			$query->set_value( $column->{name}, DBIx::Romani::Query::Variable->new($column->{name}) );
		}

		$self->{insert_query} = $query;
	}

	return $self->{insert_query};
}

sub get_update_query
{
	my $self = shift;

	if ( not defined $self->{update_query} )
	{
		my $query = DBIx::Romani::Query::Update->new( $self->{table_name} );
		my $where = DBIx::Romani::Query::Where->new( $DBIx::Romani::Query::Where::AND );

		foreach my $column ( @{$self->{table}->get_columns()} )
		{
			# add the primary key to the where section
			if ( $column->{primary_key} )
			{
				my $op = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::EQUAL );
				$op->add( DBIx::Romani::Query::SQL::Column->new( undef, $column->{name} ) );
				$op->add( DBIx::Romani::Query::Variable->new( "key.$column->{name}" ) );
				$where->add($op);
			}

			# set all the column values
			$query->set_value( $column->{name}, DBIx::Romani::Query::Variable->new( $column->{name} ) );
		}
		$query->set_where( $where );

		$self->{update_query} = $query;
	}

	return $self->{update_query};
}

sub get_delete_query
{
	my $self = shift;

	if ( not defined $self->{delete_query} )
	{
		my $query = DBIx::Romani::Query::Delete->new( $self->{table_name} );
		my $where = DBIx::Romani::Query::Where->new( $DBIx::Romani::Query::Where::AND );

		foreach my $column ( @{$self->{table}->get_columns()} )
		{
			if ( $column->{primary_key} )
			{
				my $op = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::EQUAL );
				$op->add( DBIx::Romani::Query::SQL::Column->new( undef, $column->{name} ) );
				$op->add( DBIx::Romani::Query::Variable->new( $column->{name} ) );
				$where->add( $op );
			}
		}
		$query->set_where( $where );

		$self->{delete_query} = $query;
	}

	return $self->{delete_query};
}

# A convenience function
sub find_links
{
	my ($self, $object_name) = @_;

	my $database = $self->get_database();
	my $object   = $database->get_object( $object_name );

	return $database->find_links( $self->get_table_name(), $object->get_table_name() );
}

# A convenience function
sub create_db_connection
{
	my $self = shift;

	my $factory = $self->get_database()->get_connection_factory();
	if ( not defined $factory )
	{
		# Programmer error
		die "This database doesn't have a DBIx::Romani::Connection::Factory registered";
	}

	return $factory->create();
}

#
# The following allow you to perform all of the basic database operations that
# CS3::Object performs, except without an actual object, just the raw queries.
#

sub load
{
	my $self = shift;

	# Convenience.
	my $table      = $self->get_table();
	my $table_name = $self->get_table_name();
	my $query      = $self->get_select_by_key_query();

	my %values;

	my $args;
	if ( ref($_[0]) eq 'HASH' )
	{
		$args = shift;
	}

	# parse the arguments into values for the SQL generator
	foreach my $column ( @{$table->get_columns()} )
	{
		if ( $column->{primary_key} )
		{
			my $col_name = $column->{name};
			my $val_name = "$table_name.$col_name";
			my $val;

			if ( $args )
			{
				$val = $args->{$col_name};
			}
			else
			{
				$val = shift;
			}

			if ( not defined $val )
			{
				die "Missing required key value \"$col_name\"";
			}

			$values{$val_name} = DBIx::Romani::Query::SQL::Literal->new( $val );
		}
	}

	my $conn;

	my $data = try eval
	{
		$conn = $self->create_db_connection();

		my $stmt = $conn->prepare( $query );
		my $rs   = $stmt->execute( \%values );

		if ( $rs->next() )
		{
			return $rs->get_row();
		}
		else
		{
			# uh oh!
			die "Can't find an object with that primary key!";
		}
	};

	do
	{
		$conn->disconnect() if defined $conn;
	};

	catch my $err;
	$err->rethrow() if $err;

	return $data;
}

sub search_rs
{
	my $self = shift;
	my $criteria = shift;

	my $query = $criteria->generate_query_for_object( $self->get_database(), $self->get_name() );

	my $conn;
	my $rs;

	# connect and query
	try eval
	{
		$conn = $self->create_db_connection();
		#printf STDERR "Search(): %s\n", $conn->generate_sql($query);
		$rs = $conn->prepare( $query )->execute();
	};

	catch my $err;
	if ( $err )
	{
		$conn->disconnect() if defined $conn;
		$err->rethrow();
	}

	return $rs;
}

sub search
{
	my $self  = shift;
	my $rs    = $self->search_rs( @_ );
	
	my @ret;

	# unravel our result set
	while ( $rs->next() )
	{
		push @ret, $rs->get_row();
	}

	return wantarray ? @ret : \@ret;
}

sub search_attrs_rs
{
	my $self     = shift;
	my $criteria = shift;

	my @attrs;

	my $table_name = $self->get_table_name();

	# build object specific attrs
	foreach my $attr ( @_ )
	{
		push @attrs, "$table_name/$attr";
	}

	my $query = $criteria->generate_query_for_attrs( $self->get_database(), \@attrs );

	my $conn;
	my $rs;

	# connect and query
	try eval
	{
		$conn = $self->create_db_connection();
		#printf STDERR "Search(): %s\n", $conn->generate_sql($query);
		$rs = $conn->prepare( $query )->execute();
	};

	if ( my $err = catch )
	{
		$conn->disconnect() if defined $conn;
		$err->rethrow();
	}

	return $rs;
}

sub search_attrs
{
	my $self  = shift;
	my $rs    = $self->search_attrs_rs( @_ );
	
	my @ret;

	# unravel our result set
	while ( $rs->next() )
	{
		push @ret, $rs->get_row();
	}

	return wantarray ? @ret : \@ret;
}

sub search_distinct_attrs_rs
{
	my $self     = shift;
	my $criteria = shift;

	my @attrs;

	my $table_name = $self->get_table_name();

	# build object specific attrs
	foreach my $attr ( @_ )
	{
		push @attrs, "$table_name/$attr";
	}

	my $query = $criteria->generate_query_for_attrs( $self->get_database(), \@attrs );

	# we are searching distinctly...
	$query->set_distinct(1);

	my $conn;
	my $rs;

	# connect and query
	try eval
	{
		$conn = $self->create_db_connection();
		#printf STDERR "SearchDistinct(): %s\n", $conn->generate_sql($query);
		$rs = $conn->prepare( $query )->execute();
	};

	catch my $err;
	if ( $err )
	{
		$conn->disconnect() if defined $conn;
		$err->rethrow();
	}

	return $rs;
}

sub search_distinct_attrs
{
	my $self  = shift;
	my $rs    = $self->search_attrs_rs( @_ );
	
	my @ret;

	# unravel our result set
	while ( $rs->next() )
	{
		push @ret, $rs->get_row();
	}

	return wantarray ? @ret : \@ret;
}

sub count
{
	my $self     = shift;
	my $criteria = shift;

	my $query = $criteria->generate_query_for_object_count( $self->get_database(), $self->get_name() );

	my $conn;
	my $ret;

	try eval
	{
		$conn = $self->create_db_connection();
		
		#printf "Search(): %s\n", $conn->generate_sql($query);
		my $stmt = $conn->prepare( $query );
		my $rs   = $stmt->execute();

		if ( $rs->next() )
		{
			my $t = $rs->get_row();
			$ret = $t->{count};
		}
	};

	do
	{
		$conn->disconnect() if defined $conn;
	};

	catch my $err;
	$err->rethrow() if $err;

	return $ret;
}

1;

