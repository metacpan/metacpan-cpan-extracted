
package Xmldoom::Schema::ForeignKey;

use Xmldoom::Threads;
use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $parent;
	my $reference_table;
	my $local_columns;
	my $foreign_columns;

	if ( ref($args) eq 'HASH' )
	{
		$parent          = $args->{parent};
		$reference_table = $args->{reference_table};
		$local_columns   = $args->{local_columns};
		$foreign_columns = $args->{foreign_columns};
	}

	# make sure that the count of the two array's is the same.
	if ( scalar @$local_columns != scalar @$foreign_columns )
	{
		die "A foreign-key must have the same number of local and foreign columns";
	}

	my $self = {
		parent          => $parent,
		reference_table => $reference_table,
		local_columns   => $local_columns,
		foreign_columns => $foreign_columns
	};

	bless  $self, $class;
	return Xmldoom::Threads::make_shared($self, $args->{shared});
}

sub DESTROY
{
	my $self = shift;

	$self->{parent} = undef;
}

sub get_table                { return shift->{parent}; }
sub get_table_name           { return shift->{parent}->get_name(); }
sub get_reference_table_name { return shift->{reference_table}; }
sub get_local_column_names   { return shift->{local_columns}; }
sub get_foreign_column_names { return shift->{foreign_columns}; }

sub get_reference_table
{
	my $self = shift;
	return $self->get_table()->get_schema()->get_table( $self->{reference_table} );
}

sub get_local_columns
{
	my $self = shift;
	return $self->get_table()->get_columns( $self->{local_columns} );
}

sub get_foreign_columns
{
	my $self = shift;
	return $self->get_reference_table()->get_columns( $self->{foreign_columns} );
}

sub _is_list
{
	my ($list1, $list2) = @_;

	# quickest check, the lengths!
	if ( scalar @$list1 != scalar @$list2 )
	{
		return 0;
	}

	name1: foreach my $name1 ( @$list1 )
	{
		foreach my $name2 ( @$list2 )
		{
			if ( $name1 eq $name2 )
			{
				next name1;
			}
		}
		return 0;
	}

	return 1;
}

sub is_local_column_names
{
	my ($self, $names) = @_;
	return _is_list($self->{local_columns}, $names);
}

sub is_foreign_column_names
{
	my ($self, $names) = @_;
	return _is_list($self->{foreign_columns}, $names);
}

# TODO: this function was create soley for Table::get_foreign_key() which is 
# broken anyway, so the usefulness of this function is debatable.
sub get_foreign_pair_name
{
	my ($self, $name) = @_;

	my @pair = grep { $_->{local_column} eq $name } @{$self->get_column_names()};

	if ( scalar @pair > 0 )
	{
		return $pair[0]->{foreign_column};
	}

	return undef;
}

sub get_column_names
{
	my $self = shift;

	my @ret;
	my $count = scalar @{$self->{local_columns}};

	for( my $i = 0; $i < $count; $i++ )
	{
		push @ret, {
			local_column   => $self->{local_columns}->[$i],
			foreign_column => $self->{foreign_columns}->[$i],

			# for compatibility:
			local_table    => $self->get_table_name(),
			foreign_table  => $self->get_reference_table_name()
		};
	}

	return \@ret;
}

sub get_columns
{
	my $self = shift;

	my $local_table   = $self->get_table();
	my $foreign_table = $self->get_reference_table();

	my @ret;
	my $count = scalar @{$self->{local_columns}};

	for( my $i = 0; $i < $count; $i++ )
	{
		push @ret, {
			local_column   => $local_table->get_column( $self->{local_columns}->[$i] ),
			foreign_column => $foreign_table->get_column( $self->{foreign_columns}->[$i] )
		};
	}

	return \@ret;
}

sub equals
{
	my ($self, $fkey) = @_;

	return ( $self->{parent} == $fkey->{parent} and
		     $self->{reference_table} eq $fkey->{reference_table} and
		     _is_list($self->{local_columns}, $fkey->{local_columns}) and
		     _is_list($self->{foreign_columns}, $fkey->{foreign_columns}) );

}

sub clone_reverse
{
	my $self = shift;

	return Xmldoom::Schema::ForeignKey->new({
		parent          => $self->get_reference_table(),
		reference_table => $self->get_table_name(),
		local_columns   => $self->get_foreign_column_names(),
		foreign_columns => $self->get_local_column_names()
	});
}

1;

