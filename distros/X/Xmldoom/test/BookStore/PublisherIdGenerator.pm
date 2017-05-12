
package test::BookStore::PublisherIdGenerator;
use base qw(DBIx::Romani::IdGenerator);

use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $self = $class->SUPER::new($args);

	# grab the info that we get from the object.
	$self->{object}      = $args->{object};
	$self->{column_name} = $args->{column_name};
	$self->{table_name}  = $args->{table_name};

	return $self;
}

sub is_before_insert
{
	return 1;
}

sub is_after_insert
{
	return 0;
}

sub get_id_method
{
	die "max()";
}

sub get_id
{
	my $self = shift;
	my $conn = $self->get_conn();

	my $id;

	#$conn->execute_update("LOCK TABLE " . $self->{table_name});

	my $rs = $conn->execute_query( "SELECT MAX(" . $self->{column_name} . ") + 1 AS id FROM " . $self->{table_name} );

	if ( $rs->next() )
	{
		my $row = $rs->get_row();
		$id = $row->{id};
	}

	#$conn->execute_update("UNLOCK TABLE " . $self->{table_name});

	return $id;
}

1;

