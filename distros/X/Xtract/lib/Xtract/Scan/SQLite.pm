package Xtract::Scan::SQLite;

use 5.008005;
use strict;
use Xtract::Scan ();

our $VERSION = '0.16';
our @ISA     = 'Xtract::Scan';





######################################################################
# Introspection Methods

sub tables {
	grep {
		! /^sqlite_/
	} map {
		/"([^\"]+)"$/ ? "$1" : $_
	} $_[0]->dbh->tables;
};





######################################################################
# SQL Generation

sub add_table {
	my $self  = shift;
	my $table = shift;
	my $tname = $table->name;
	my $from  = shift || $tname;

	# With a direct table copy, we can interrogate types from the
	# source table directly (hopefully).
	my $info = eval {
		$self->dbh->column_info(
			'', 'main', $from, '%'
		)->fetchall_arrayref( {} );
	};
	unless ( $@ eq '' and $info ) {
		# Fallback to the generic approach
		return $self->SUPER::add_table( $table => $from );
	}

	# Generate the column metadata
	my @type = ();
	my @bind = ();
	foreach my $column ( @$info ) {
		$column->{TYPE_NAME} = uc $column->{TYPE_NAME};
		my $name = $column->{COLUMN_NAME};
		my $type = defined($column->{COLUMN_SIZE})
			? "$column->{TYPE_NAME}($column->{COLUMN_SIZE})"
			: $column->{TYPE_NAME};
		my $null = $column->{NULLABLE} ? "NULL" : "NOT NULL";
		push @type, "$name $type $null";
		push @bind, $column->{TYPE_NAME} eq 'BLOB' ? 1 : 0;
	}

	return (
		create => [
			"CREATE TABLE $tname (\n"
			. join( ",\n", map { "\t$_" } @type )
			. "\n)"
		],
		select => [
			"SELECT * FROM $from"
		],
		insert => (
			"INSERT INTO $tname VALUES ( "
			. join( ", ",
				map { '?' } @$info
			)
			. " )",
		),
		blobs  => scalar( grep { $_ } @bind ) ? \@bind : undef,
	);
}

1;
