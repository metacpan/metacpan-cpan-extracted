
package Xmldoom::Criteria::Attribute;

use DBIx::Romani::Query::SQL::Column;
use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $table_name;
	my $column_name;

	if ( ref($args) eq 'HASH' )
	{
		$table_name  = $args->{table_name};
		$column_name = $args->{column_name};
	}
	else
	{
		($table_name, $column_name) = split '/', $args;
	}

	my $self = {
		table_name  => $table_name,
		column_name => $column_name
	};

	bless  $self, $class;
	return $self;
}

sub get_table_name  { return shift->{table_name}; }
sub get_column_name { return shift->{column_name}; }

sub get_query_lval
{
	my ($self, $database) = @_;

	# TODO: we could validate if the table/column pair actually exists

	return [ DBIx::Romani::Query::SQL::Column->new( $self->get_table_name(), $self->get_column_name() ) ];
}

# really, there are only lvalues for attribute
sub get_query_rval
{
	my ($self, $database, $lval) = @_;
	
	if ( not $lval->isa( 'Xmldoom::Criteria::Attribute' ) )
	{
		die "An Attribute rvalue cannot be cast into anyother type.";
	}

	return $self->get_query_lval( $database );
}

sub get_tables
{
	my ($self, $database) = @_;

	return [ $self->get_table_name() ];
}

sub clone
{
	my $self = shift;

	return Xmldoom::Criteria::Attribute->new({
		table_name  => $self->get_table_name(),
		column_name => $self->get_column_name()
	});
}

1;

