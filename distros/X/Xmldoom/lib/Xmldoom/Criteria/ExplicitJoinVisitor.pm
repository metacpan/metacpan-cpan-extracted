
package Xmldoom::Criteria::ExplicitJoinVisitor;

use DBIx::Romani::Query::Comparison;
use strict;

use Data::Dumper;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $self = {
	};

	bless  $self, $class;
	return $self;
}

sub visit_select
{
	my ($self, $select) = @_;

	my $where = $select->get_where();
	if ( $where )
	{
		return $where->visit( $self );
	}

	return undef;
}

sub visit_sql_column
{
	my ($self, $column) = @_;

	return [ $column->get_table(), $column->get_name() ];
}

sub visit_sql_literal
{
	my ($self, $literal) = @_;

	return undef;
}

sub visit_variable
{
	my ($self, $variable) = @_;

	return undef;
}

sub visit_null
{
	my ($self, $null) = @_;

	return undef;
}

sub visit_comparison
{
	my ($self, $comp) = @_;

	my $type = $comp->get_type();

	if ( $type eq $DBIx::Romani::Query::Comparison::EQUAL )
	{
		my $lval = $comp->get_lvalue()->visit( $self );
		my $rval = $comp->get_rvalue()->visit( $self );

		if ( defined $lval and defined $rval )
		{
			return [
				{
					local_table    => $lval->[0],
					local_column   => $lval->[1],
					foreign_table  => $rval->[0],
					foreign_column => $rval->[1]
				},
				{
					local_table    => $rval->[0],
					local_column   => $rval->[1],
					foreign_table  => $lval->[0],
					foreign_column => $lval->[1]
				}
			];
		}
	}

	return undef;
}

sub visit_operator
{
	my ($self, $operator) = @_;

	return undef;
}

sub visit_where
{
	my ($self, $where) = @_;

	my @joins;
	
	foreach my $value ( @{$where->get_values()} )
	{
		my $join = $value->visit( $self );

		if ( defined $join )
		{
			if ( ref($join) eq 'ARRAY' )
			{
				@joins = ( @joins, @$join );
			}
			else
			{
				push @joins, $join;
			}
		}
	}

	return \@joins;
}

sub visit_ttt_function
{
	my ($self, $ttt) = @_;

	return undef;
}

sub visit_ttt_operator
{
	my ($self, $ttt) = @_;
	
	return undef;
}

sub visit_ttt_keyword
{
	my ($self, $ttt) = @_;

	return undef;
}

sub visit_ttt_join
{
	my ($self, $ttt) = @_;

	return undef;
}

sub visit_function_count
{
	my ($self, $func) = @_;

	return undef;
}

sub visit_function_now
{
	my ($self, $func) = @_;

	return undef;
}

1;

