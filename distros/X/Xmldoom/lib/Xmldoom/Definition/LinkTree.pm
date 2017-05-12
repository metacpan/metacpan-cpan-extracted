
package Xmldoom::Definition::LinkTree;

use Xmldoom::Definition::Link;
use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $self =
	{
		links => { }
	};

	bless  $self, $class;
	return $self;
}

sub clear { shift->{links} = { }; }

sub _add_if_not_present
{
	my ($list, $link) = @_;

	# return if it already exists
	foreach my $other ( @$list )
	{
		if ( $link->equals( $other ) )
		{
			return;
		}
	}

	push @$list, $link;
}

sub add_link
{
	my ($self, $link) = @_;

	my $table1 = $link->get_start_table_name();
	my $table2 = $link->get_end_table_name();

	# create slots in the links hash
	if ( not defined $self->{links}->{$table1} )
	{
		$self->{links}->{$table1} = { };
	}
	if ( not defined $self->{links}->{$table1}->{$table2} )
	{
		$self->{links}->{$table1}->{$table2} = [ ];
	}
	if ( not defined $self->{links}->{$table2} )
	{
		$self->{links}->{$table2} = { };
	}
	if ( not defined $self->{links}->{$table2}->{$table1} )
	{
		$self->{links}->{$table2}->{$table1} = [ ];
	}

	# add both the forward and backward version
	_add_if_not_present($self->{links}->{$table1}->{$table2}, $link);
	_add_if_not_present($self->{links}->{$table2}->{$table1}, $link->clone_reverse());
}

sub get_links
{
	my ($self, $table1, $table2, $start_columns) = @_;

	if ( not defined $self->{links}->{$table1} )
	{
		return undef;
	}
	if ( not defined $table2 )
	{
		return $self->{links}->{$table1};
	}
	if ( not defined $self->{links}->{$table1}->{$table2} )
	{
		return undef;
	}

	my $links = $self->{links}->{$table1}->{$table2};

	if ( defined $start_columns )
	{
		my @temp;
		foreach my $link ( @$links )
		{
			if ( $link->is_start_column_names( $start_columns ) )
			{
				push @temp, $link;
			}
		}
		$links = \@temp;
	}

	return $links;
}

1;

