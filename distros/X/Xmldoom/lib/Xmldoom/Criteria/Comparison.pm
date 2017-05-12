
package Xmldoom::Criteria::Comparison;

use Xmldoom::Criteria;
use DBIx::Romani::Query::Where;
use DBIx::Romani::Query::Comparison;
use strict;

use Data::Dumper;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $lval;
	my $rval;
	my $type;

	if ( ref($args) eq 'HASH' )
	{
		$lval = $args->{lval};
		$rval = $args->{rval};
		$type = $args->{type};
	}
	else
	{
		$lval = $args;
		$rval = shift;
		$type = shift;
	}

	if ( not defined $type )
	{
		$type = $Xmldoom::Criteria::EQUAL;
	}

	if ( ref($rval) ne 'ARRAY' )
	{
		if ( defined $rval )
		{
			$rval = [ $rval ];
		}
		else
		{
			$rval = [ ];
		}
	}

	my $rval_count = scalar @$rval;

	# validate the number of rvals
	if ( $type eq $Xmldoom::Criteria::BETWEEN )
	{
		if ( $rval_count != 2 )
		{
			# Programmer Error
			die "BETWEEN comparisons must have 2 rvals";
		}
	}
	elsif ( $type eq $Xmldoom::Criteria::IN or 
	        $type eq $Xmldoom::Criteria::NOT_IN )
	{
		if ( $rval_count < 2 )
		{
			# Programmer Error
			die "IN comparisons must have at least 2 rvals";
		}
	}
	elsif ( $type eq $Xmldoom::Criteria::IS_NULL or 
	        $type eq $Xmldoom::Criteria::IS_NOT_NULL )
	{
		if ( $rval_count != 0 )
		{
			# Programmer Error
			die "IS NULL and IS NOT NULL comparisons cannot have any rvals";
		}
	}
	elsif ( $rval_count != 1 )
	{
		# Programmer Error
		die "Comparison '$type' must have 1 and only 1 rval";
	}

	my $self = {
		lval => $lval,
		rval => $rval,
		type => $type,
	};

	bless  $self, $class;
	return $self;
}

sub get_lval { return shift->{lval}; }
sub get_rval { return shift->{rval}; }
sub get_type { return shift->{type}; }

sub get_query_lval
{
	my ($self, $database) = @_;
	return $self->get_lval()->get_query_lval( $database );
}

sub get_query_rval
{
	my ($self, $database, $lval) = @_;

	my $multis = (scalar @{$self->get_rval()} > 1);

	my @rvals;
	foreach my $rval ( @{$self->get_rval()} )
	{
		if ( $multis and not $rval->isa( 'Xmldoom::Criteria::Literal' ) )
		{
			die "Cannot have multiple rvalues that aren't literals";
		}

		push @rvals, $rval->get_query_rval( $database, $self->get_lval() );
	}

	return \@rvals;
}

sub generate
{
	my ($self, $database) = @_;

	my $lval_list = $self->get_query_lval( $database );
	my $rval_list = $self->get_query_rval( $database );

	my $where = DBIx::Romani::Query::Where->new( $DBIx::Romani::Query::Where::AND );

	# turn our list of lvals into a list of operators
	foreach my $lval ( @$lval_list )
	{
		my $op;
		$op = DBIx::Romani::Query::Comparison->new( $self->get_type() );
		$op->add( $lval );

		$where->add( $op );
	}

	# Ok, this makes no sense.  Don't even try to understand it unless
	# your were recently elected Christ and Buddah was ecstatic that you
	# knew his name.
	foreach my $rvals ( @$rval_list )
	{
		if ( scalar @$rvals != scalar @{$where->get_values()} )
		{
			die "Must have an equal number of lvalues and rvalues in a Comparison.";
		}

		foreach my $rval ( @$rvals )
		{
			foreach my $op ( @{$where->get_values()} )
			{
				$op->add( $rval );
			}
		}
	}

	# reduce me, baby.
	if ( scalar @{$where->get_values()} == 1 )
	{
		# if there is only one, then return only that
		return $where->get_values()->[0];
	}

	return $where;
}

sub get_tables
{
	my ($self, $database) = @_;

	my @tables;

	foreach my $table_name ( @{$self->get_lval()->get_tables( $database )} )
	{
		push @tables, $table_name;
	}

	# rval's only go into the from_table list
	foreach my $rval ( @{$self->get_rval()} )
	{
		foreach my $table_name ( @{$rval->get_tables( $database )} )
		{
			push @tables, $table_name;
		}
	}

	return \@tables;
}

sub clone
{
	my $self = shift;

	#my $lval = $self->get_lval()->clone();
	#my @rval = map { $_->clone() } @{$self->get_rval()};

	#return Xmldoom::Criteria::Comparison->new( $lval, \@rval, $self->get_type() );
	return Xmldoom::Criteria::Comparison->new( $self->get_lval(), $self->get_rval(), $self->get_type() );
}

1;

