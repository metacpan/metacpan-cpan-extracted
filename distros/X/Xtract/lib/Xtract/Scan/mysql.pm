package Xtract::Scan::mysql;

use 5.008005;
use strict;
use DBI 1.57 ':sql_types';
use Xtract::Scan ();

our $VERSION = '0.16';
our @ISA     = 'Xtract::Scan';





######################################################################
# Introspection Methods

sub tables {
	map {
		/`([^`]+)`$/ ? "$1" : $_
	} $_[0]->dbh->tables;
};





######################################################################
# SQL Generation

sub add_table {
	my $self  = shift;
	my $table = shift;
	my $tname = $table->name;
	my $from  = shift || $tname;

	# Capture table metadata from a select on the table
	my $sth = $self->from_dbh->prepare("select * from $from");
	unless ( $sth and $sth->execute ) {
		return $self->SUPER::add_table( $table, $from );
	}

	my @name = @{$sth->{NAME_lc}};
	my @type = @{$sth->{TYPE}};
	my @null = @{$sth->{NULLABLE}};
	my @blob = @{$sth->{mysql_is_blob}};
	$sth->finish;

	# Generate the create fragments
	foreach my $i ( 0 .. $#name ) {
		if ( $blob[$i] ) {
			$type[$i] = 'BLOB';
		} elsif ( $type[$i] == SQL_INTEGER ) {
			$type[$i] = 'INTEGER';
		} elsif ( $type[$i] == SQL_FLOAT ) {
			$type[$i] = 'REAL';
		} elsif ( $type[$i] == SQL_REAL ) {
			$type[$i] = 'REAL';
		} elsif ( $type[$i] == -6 ) {
			$type[$i] = 'INTEGER';
		} else {
			$type[$i] = 'TEXT';
		}
		$null[$i] = $null[$i] ? 'NULL' : 'NOT NULL';
	}

	return (
		create => [
			"CREATE TABLE $tname (\n"
			. join( ",\n",
				map {
					"\t$name[$_] $type[$_] $null[$_]"
				} (0 .. $#name)
			)
			. "\n)"
		],
		select => [
			"SELECT * FROM $from"
		],
		insert => (
			"INSERT INTO $tname VALUES ( "
			. join( ", ",
				map { '?' } @name
			)
			. " )",
		),
		blobs => scalar( grep { $_ } @blob ) ? \@blob : undef,
	);
}

1;
