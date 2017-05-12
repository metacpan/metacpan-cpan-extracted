
package Xmldoom::Criteria;

use Xmldoom::Criteria::Search;
use Xmldoom::Criteria::ExplicitJoinVisitor;
use Xmldoom::Threads;
use DBIx::Romani::Query::SQL::Column;
use strict;

use Data::Dumper;

# Search types
our $AND = 'AND';
our $OR  = 'OR';

# comparison types
our $EQUAL         = '=';
our $NOT_EQUAL     = '<>';
our $GREATER_THAN  = '>';
our $GREATER_EQUAL = '>=';
our $LESS_THAN     = '<';
our $LESS_EQUAL    = '<=';
our $LIKE          = 'LIKE';
our $NOT_LIKE      = 'NOT LIKE';
our $ILIKE         = 'ILIKE';
our $NOT_ILIKE     = 'NOT ILIKE';
our $BETWEEN       = 'BETWEEN';
our $IN            = 'IN';
our $NOT_IN        = 'NOT IN';
our $IS_NULL       = 'IS NULL';
our $IS_NOT_NULL   = 'IS NOT NULL';

sub new
{
	my $class = shift;
	my $args  = shift;

	my $parent;
	my $shared;

	if ( ref($args) eq 'HASH' )
	{
		$parent = $args->{parent};
		$shared = $args->{shared};
	}
	else
	{
		$parent = $args;
	}
	
	my $self = {
		parent   => $parent,
		search   => Xmldoom::Criteria::Search->new({ type => 'AND' }),
		order_by => [ ],
		group_by => [ ],
		limit    => undef,
		offset   => undef,
	};

	bless $self, $class;

	# we want to move into shared memory as soon as possible
	$self = Xmldoom::Threads::make_shared($self, $shared);

	return $self;
}

sub get_parent   { return shift->{parent}; }
sub get_type     { return "AND"; }
sub get_order_by { return shift->{order_by}; }
sub get_group_by { return shift->{order_by}; }
sub get_limit    { return shift->{limit}; }
sub get_offset   { return shift->{offset}; }

sub set_parent
{
	my ($self, $parent) = @_;
	$self->{parent} = $parent;
}

sub set_limit
{
	my ($self, $limit, $offset) = @_;
	$self->{limit}  = $limit;
	$self->{offset} = $offset;
}

sub add
{
	my $self = shift;
	$self->{search}->add( @_ );
}

sub add_attr
{
	my $self = shift;
	$self->{search}->add_attr( @_ );
}

sub add_prop
{
	my $self = shift;
	$self->{search}->add_prop( @_ );
}

sub join_attr
{
	my $self = shift;
	$self->{search}->join_attr( @_ );
}

sub join_prop
{
	my $self = shift;
	$self->{search}->join_prop( @_ );
}

sub add_order_by_attr
{
	my ($self, $attr, $dir) = @_;
	my ($table_name, $column) = split '/', $attr;

	my %order_by = (
		attr  => {
			table_name => $table_name,
			column     => $column,
		},
		value => {
			dir => $dir,
		}
	);

	push @{$self->{order_by}}, \%order_by;
}

sub add_order_by_prop
{
	my ($self, $prop, $dir) = @_;
	my ($object_name, $prop_name) = split '/', $prop;

	my %order_by = (
		prop  => {
			object_name => $object_name,
			prop_name   => $prop_name,
		},
		value => {
			dir => $dir,
		}
	);

	push @{$self->{order_by}}, \%order_by;
}

# A convenience alias.
sub add_order_by
{
	my $self = shift;
	$self->add_order_by_prop(@_);
}

sub add_group_by_attr
{
	my ($self, $attr) = @_;
	my ($table_name, $column) = split '/', $attr;

	my %group_by = (
		attr  => {
			table_name => $table_name,
			column     => $column,
		}
	);

	push @{$self->{group_by}}, \%group_by;
}

sub add_group_by_prop
{
	my ($self, $prop) = @_;
	my ($object_name, $prop_name) = split '/', $prop;

	my %group_by = (
		prop  => {
			object_name => $object_name,
			prop_name   => $prop_name,
		}
	);

	push @{$self->{group_by}}, \%group_by;
}

# A convenience alias.
sub add_group_by
{
	my $self = shift;
	$self->add_group_by_prop(@_);
}

sub _setup_query
{
	my ($self, $database, $query) = @_;

	my $search;

	if ( defined $self->{parent} )
	{
		$search = $self->{search}->clone();

		# add the values of its primary keys to the criteria
		foreach my $col ( @{$self->{parent}->_get_definition()->get_table()->get_columns()} )
		{
			if ( $col->{primary_key} )
			{
				my $attr_name = join '/', $self->{parent}->_get_definition()->get_table_name(), $col->{name};
				# we use key instead of the attr values, in case they were changed, we
				# should still query against the current database value.
				$search->add_attr( $attr_name, $self->{parent}->{key}->{$col->{name}} );
			}
		}
	}
	else
	{
		$search = $self->{search};
	}

	# add the from stuff
	foreach my $table_name ( @{$search->get_tables($database)} )
	{
		$query->add_from( $table_name );
	}

	# build the where clause
	$query->set_where( $search->generate($database) );

	# set the limit and offset
	$query->set_limit( $self->{limit}, $self->{offset} );
}

sub _apply_order_by_to_query
{
	my ($self, $database, $query) = @_;

	foreach my $order_by ( @{$self->{order_by}} )
	{
		if ( defined $order_by->{attr} )
		{
			# add the table to the query
			$query->add_from( $order_by->{attr}->{table_name} );
			
			# add, yo.
			my $value = DBIx::Romani::Query::SQL::Column->new({
				table => $order_by->{attr}->{table_name},
				name  => $order_by->{attr}->{column}
			});
			$query->add_order_by({ value => $value, dir => $order_by->{value}->{dir} });
		}
		elsif ( defined $order_by->{prop} )
		{
			my $object = $database->get_object( $order_by->{prop}->{object_name} );
			if ( not defined $object )
			{
				die "Unable to find object '$order_by->{prop}->{object_name}' in order_by";
			}

			my $prop   = $object->get_property( $order_by->{prop}->{prop_name} );
			if ( not defined $prop )
			{
				die "Unable to find property '$order_by->{prop}->{prop_name}' in object '$order_by->{prop}->{prop_name}' in order_by";
			}

			# TODO: this should really "visit" the returned lval to determine what
			# tables this includes ...
			$query->add_from( $object->get_table_name() );

			foreach my $lval ( @{$prop->get_query_lval()} )
			{
				$query->add_order_by({ value => $lval, dir => $order_by->{value}->{dir} });
			}
		}
	}
}

# TODO: This was just copied from _apply_order_by_to_query.  These two should be 
# merged if possible somehow.
sub _apply_group_by_to_query
{
	my ($self, $database, $query) = @_;

	foreach my $group_by ( @{$self->{group_by}} )
	{
		if ( defined $group_by->{attr} )
		{
			# add the table to the query
			$query->add_from( $group_by->{attr}->{table_name} );
			
			# add, yo.
			my $value = DBIx::Romani::Query::SQL::Column->new({
				table => $group_by->{attr}->{table_name},
				name  => $group_by->{attr}->{column}
			});
			$query->add_group_by( $value );
		}
		elsif ( defined $group_by->{prop} )
		{
			my $object = $database->get_object( $group_by->{prop}->{object_name} );
			if ( not defined $object )
			{
				die "Unable to find object '$group_by->{prop}->{object_name}' in group_by";
			}

			my $prop   = $object->get_property( $group_by->{prop}->{prop_name} );
			if ( not defined $prop )
			{
				die "Unable to find property '$group_by->{prop}->{prop_name}' in object '$group_by->{prop}->{prop_name}' in group_by";
			}

			# TODO: this should really "visit" the returned lval to determine what
			# tables this includes ...
			$query->add_from( $object->get_table_name() );

			foreach my $lval ( @{$prop->get_query_lval()} )
			{
				$query->add_group_by( $lval );
			}
		}
	}
}

sub _join_to_tables
{
	my ($self, $database, $query) = @_;

	# if there is only one table of this query then we don't have to worry at all.
	if ( scalar @{$query->get_from()} == 1 )
	{
		return;
	}

	# get a list of exiplicit joins on the existings query
	my $visitor = Xmldoom::Criteria::ExplicitJoinVisitor->new();
	my $explicit_joins;
	if ( $query->get_where() )
	{
		$explicit_joins = $query->get_where()->visit( $visitor );
	}
	#print Dumper $explicit_joins;

	my $where       = DBIx::Romani::Query::Where->new();
	my @tables      = @{$query->get_from()};
	my $main_table  = shift @tables;
	my %joined_hash = ( $main_table => 1 );
	my %tables_hash = map { $_ => 1 } @tables;

	while( scalar keys %tables_hash > 0 )
	{
		my $joined = 0;

		# go through the list of unconnected tables
		foreach my $table_name ( keys %tables_hash )
		{
			my $links = [ ];
			my $new_link;

			# look for connections to already connected tables
			foreach my $other_table_name ( keys %joined_hash )
			{
				$links = [ @$links, @{$database->find_links( $table_name, $other_table_name )} ];
			}

			# reduce the overlapping links
			$links = Xmldoom::Definition::Link::reduce_shortest( $links );

			# if there are no links, then we look to see if an explicit link exists
			if ( scalar @$links == 0 )
			{
				foreach my $explicit ( @$explicit_joins )
				{
					if ( $explicit->{local_table} eq $table_name and
						 $joined_hash{$explicit->{foreign_table}} )
					{
						# cool!  We've got an explicit link to one of the joined tables.
						$joined = 1;
						last;
					}
				}
			}
			elsif ( scalar @$links > 1 )
			{
				# attempt to disambiguate the multiple links using the explicit joins.

				LINK: foreach my $link ( @$links )
				{
					my $is_already_explicit = 1;

					# check to see if all of the foreign keys in this link, are covered by
					# a pre-existing explicit link.
					foreach my $fn ( @{$link->get_foreign_keys()} )
					{
						foreach my $ref ( @{$fn->get_column_names()} )
						{
							my $has_this_one = 0;

							foreach my $explicit ( @$explicit_joins )
							{
								if ( $ref->{local_table} eq $explicit->{local_table} and
									 $ref->{local_column} eq $explicit->{local_column} and
									 $ref->{foreign_table} eq $explicit->{foreign_table} and
									 $ref->{foreign_column} eq $explicit->{foreign_column} )
								{
									$has_this_one = 1;
								}
							}

							if ( not $has_this_one )
							{
								$is_already_explicit = 0;
								next LINK;
							}
						}
					}

					if ( $is_already_explicit )
					{
						# we are explicitly joined already, yo!
						$joined = 1;
						last;
					}
				}

				if ( not $joined )
				{
					# This is an error!  A serious error, yo!
					die "There are multiple ways in which these tables could be linked, so an explicit join must be used to select one of them."

					#print STDERR "WARNING: There are multiple ways in which these tables could be linked, but no explicit join was given so the first available link was chosen.\n";
					#$new_link = $links->[0];
				}
			}
			else
			{
				# We only have the one possible link, so attempt to automatically join on that.
				$new_link = $links->[0];
			}
			
			if ( defined $new_link )
			{
				# join the two tables
				foreach my $fn ( @{$new_link->get_foreign_keys()} )
				{
					foreach my $ref ( @{$fn->get_column_names()} )
					{
						my $is_already_explicit = 0;

						foreach my $explicit ( @$explicit_joins )
						{
							if ( $ref->{local_table} eq $explicit->{local_table} and
								 $ref->{local_column} eq $explicit->{local_column} and
								 $ref->{foreign_table} eq $explicit->{foreign_table} and
								 $ref->{foreign_column} eq $explicit->{foreign_column} )
							{
								$is_already_explicit = 1;
							}
						}

						if ( not $is_already_explicit )
						{
							my $join = DBIx::Romani::Query::Comparison->new();

							# NOTE: We do this in reverse than expected order because we looping
							# essentially backwards.  The first item on the list of foriegn tables
							# is thought to be our master table...

							$join->add( DBIx::Romani::Query::SQL::Column->new( $ref->{foreign_table}, $ref->{foreign_column} ) );
							$join->add( DBIx::Romani::Query::SQL::Column->new( $ref->{local_table}, $ref->{local_column} ) );
							$where->add( $join );

							# add to the from list if we are dealing with a many-to-many link
							$query->add_from( $ref->{foreign_table} );

							# also, remove this from the unjoined tables and add them to the 
							# the joined list!
							$joined_hash{$ref->{foreign_table}} = 1;
							delete $tables_hash{$ref->{foreign_table}};
						}
					}
				}

				$joined = 1;
			}

			if ( $joined )
			{
				# we mark this table as joined and restart
				$joined_hash{$table_name} = 1;
				delete $tables_hash{$table_name};
				last;
			}
		}

		if ( not $joined )
		{
			die "Unable to join the following tables: " . join(', ', keys %tables_hash);
		}
	}

	# merge the old where statement with the connection one
	if ( scalar @{$where->get_values()} > 0 )
	{
		my $old_where = $query->get_where();
		if ( $old_where )
		{
			$where->add ( $old_where );
		}
		$query->set_where( $where );
	}
}

sub generate_query_for_object
{
	my ($self, $database, $object_name) = @_;

	my $definition = $database->get_object( $object_name );
	my $query      = $definition->get_select_query()->clone();

	# setup the query
	$self->_setup_query( $database, $query );

	# add the order by
	$self->_apply_order_by_to_query( $database, $query );
	
	# add the group by
	$self->_apply_group_by_to_query( $database, $query );

	# make sure all the appropriate connections exist
	$self->_join_to_tables( $database, $query );

	return $query;
}

sub generate_query_for_object_count
{
	my ($self, $database, $object_name) = @_;

	my $definition = $database->get_object( $object_name );

	my $query      = $definition->get_select_query()->clone();
	my $table      = $definition->get_table();
	my $table_name = $definition->get_table_name();

	# make a query for COUNT() of the objects first primary key
	$query->clear_result();
	foreach my $column ( @{$table->get_columns()} )
	{
		if ( $column->{primary_key} )
		{
			my $count = DBIx::Romani::Query::Function::Count->new();
			$count->add( DBIx::Romani::Query::SQL::Column->new( $table_name, $column->{name} ) );
			$query->add_result( $count, 'count' );

			# we're cool
			last;
		}
	}
	
	# setup the query
	$self->_setup_query( $database, $query );

	# make sure all the appropriate connections exist
	$self->_join_to_tables( $database, $query );

	# we don't want to limit or offset on a count query
	$query->clear_limit();

	return $query;
}

sub generate_query_for_attrs
{
	my ($self, $database, $attrs) = (shift, shift, shift);

	# we can put on the list, or use an array hash
	if ( ref($attrs) ne 'ARRAY' )
	{
		$attrs = [ $attrs, @_ ];
	}

	my $query = DBIx::Romani::Query::Select->new();

	foreach my $attr ( @$attrs )
	{
		my ($table_name, $column) = split '/', $attr;

		# add the column to the result list
		$query->add_result( DBIx::Romani::Query::SQL::Column->new( $table_name, $column ) );

		# add to the table list
		$query->add_from( $table_name );
	}

	# setup the query
	$self->_setup_query( $database, $query );

	# add the order by stuff
	$self->_apply_order_by_to_query( $database, $query );

	# add the group by
	$self->_apply_group_by_to_query( $database, $query );

	# make sure all the appropriate connections exist
	$self->_join_to_tables( $database, $query );

	return $query;
}

sub generate_description
{
	my $self = shift;

	return $self->{search}->generate_description( @_ );
}

sub clone
{
	my $self   = shift;
	my $parent = shift;

	if ( not defined $parent )
	{
		$parent = $self->get_parent();
	}
	
	my $criteria = Xmldoom::Criteria->new( $parent );

	# copy all the deep information
	$criteria->{search} = $self->{search}->clone();
	foreach my $order_by ( @{$self->get_order_by()} )
	{
		push @{$criteria->{order_by}}, $order_by;
	}
	foreach my $group_by ( @{$self->get_group_by()} )
	{
		push @{$criteria->{group_by}}, $group_by;
	}

	# shallow mallow
	$criteria->set_limit( $self->get_limit(), $self->get_offset() );

	return $criteria;
}

1;

