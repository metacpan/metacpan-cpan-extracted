
package Xmldoom::Schema::Table;

use Xmldoom::Schema::Column;
use Xmldoom::Schema::ForeignKey;
use Xmldoom::Threads;
use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $parent;
	my $name;

	if ( ref($args) eq 'HASH' )
	{
		$parent = $args->{parent};
		$name   = $args->{name};
	}
	else
	{
		$parent = $args;
		$name   = shift;
	}

	my $self = {
		parent       => $parent,
		name         => $name,
		columns      => [ ],
		foreign_keys => [ ]
	};

	bless  $self, $class;
	return Xmldoom::Threads::make_shared($self, $args->{shared});
}

sub DESTROY
{
	my $self = shift;

	# we don't need no stinking weak references!
	$self->{parent} = undef;
}

sub get_schema { return shift->{parent}; }
sub get_name   { return shift->{name}; }

sub get_columns
{
	my $self = shift;
	my $args = shift;

	# deal with the simplest case
	if ( not defined $args )
	{
		return $self->{columns};
	}

	my $names;
	my $primary_key = 0;
	my $data_only   = 0;

	if ( ref($args) eq 'ARRAY' )
	{
		$names = $args;
	}
	elsif ( ref($args) eq 'HASH' )
	{
		$primary_key = $args->{primary_key} if defined $args->{primary_key};
		$data_only   = $args->{data_only}   if defined $args->{data_only};
	}

	my @cols;
	foreach my $col ( @{$self->{columns}} )
	{
		if ( defined $names )
		{
			# only add those colums matched in the names list
			foreach my $name ( @$names )
			{
				if ( $col->get_name() eq $name )
				{
					push @cols, $col;
					last;
				}
			}
		}
		else
		{
			if ( $primary_key and $col->is_primary_key() )
			{
				# only the primary key
				push @cols, $col;
			}
			elsif ( $data_only and not $col->is_primary_key() )
			{
				# only the data
				push @cols, $col;
			}
		}
	}
	
	return \@cols;
}

sub get_column_names
{
	my $self = shift;

	my $columns = $self->get_columns(@_);
	my @ret = map { $_->get_name() } @$columns;

	return \@ret;
}

sub get_column
{
	my ($self, $name) = @_;

	my @cols = grep { $_->{name} eq $name } @{$self->{columns}};
	if ( scalar @cols != 1 )
	{
		return undef;
	}

	return $cols[0];
}

sub get_primary_key
{
	my $self = shift;

	my @columns;

	foreach my $col ( @{$self->{columns}} )
	{
		if ( $col->{primary_key} )
		{
			push @columns, $col;
		}
	}

	return \@columns;
}

sub get_column_type 
{
	my ($self, $name) = @_;

	my $column  = $self->get_column($name);
	if ( defined $column )
	{
		return $column->get_data_type();
	}
	return undef;
}

sub get_foreign_keys { return shift->{foreign_keys}; }

# TODO: this function operates like before but before it was broken!
sub get_foreign_key
{
	my ($self, $name) = @_;
	
	foreach my $key ( @{$self->get_foreign_keys()} )
	{
		my $pair_name = $key->get_foreign_pair_name( $name );

		if ( defined $pair_name )
		{
			return {
				foreign_table  => $key->get_reference_table_name(),
				local_column   => $name,
				foreign_column => $pair_name
			};
		}
	}

	return undef;
}

sub add_column
{
	my $self;
	my @args;

	# sneak the parent argument in.
	if ( ref($_[1]) eq 'HASH' )
	{
		$self = shift;
		@args = ( $_[1] );
		$args[0]->{parent} = $self;
	}
	else
	{
		$self = $_[0];
		@args = @_;
	}

	my $col = Xmldoom::Schema::Column->new(@_);

	if ( $self->get_column( $col->{name} ) )
	{
		die "Table already has a column named \"$col->{name}\"";
	}

	push @{$self->{columns}}, $col;
}

sub add_foreign_key
{
	my $self = shift;
	my $args = shift;

	if ( ref($args) eq 'HASH' )
	{
		$args->{parent} = $self;
	}
	else
	{
		$args = {
			parent          => $self,
			reference_table => $args,
			local_columns   => shift,
			foreign_columns => shift
		};
	}

	push @{$self->{foreign_keys}}, Xmldoom::Schema::ForeignKey->new($args);
}

1;

