#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use DBI;
BEGIN {
	# Skip for legitimate reasons first
	unless ( $^O eq 'MSWin32' ) {
		plan( skip_all => 'Not on Win32' );
	}
	unless ( grep { $_ eq 'ODBC' } DBI->available_drivers ) {
		plan( skip_all => 'DBI driver ODBC is not available' );
	}
	plan( skip_all => 'Skipping ODBC driver test' );
	# plan( tests => 10 );
}
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use File::Remove          'clear';
use Xtract                ();

# Command row data
my @data = (
	[ 1, 'a', 'one'   ],
	[ 2, 'b', 'two'   ],
	[ 3, 'c', 'three' ],
	[ 4, 'd', 'four'  ],
);

# Locate the output database
my $output = catfile('t', 'output.sqlite');
File::Remove::clear($output);

# Connect to the source database
my $source = DBI->connect("DBI:ODBC:Book1", undef, undef, {
	ReadOnly   => 1,
	PrintError => 1,
	RaiseError => 1,
} );
isa_ok( $source, 'DBI::db' );

# Create the Publish object
my $xtract = new_ok( 'Xtract' => [
	to   => $output,
	from => "DBI:ODBC:Book1",
] );
is( $xtract->to, $output, '->to ok' );
ok( $xtract->from, '->from ok' );
isa_ok( $xtract->from_dbh, 'DBI::db', '->sqlite ok' );

# Find the available tables
my @tables = grep { /table1/ } $xtract->from_tables;
is( scalar(@tables), 1, 'Found 1 table' );

# Clone a table completely
ok(
	$xtract->table( 'simple3', $tables[0] ),
	'Created simple3 table',
);

# Clean up
ok( $xtract->to_finish, '->finish ok' );
is_deeply(
	$xtract->dbh->selectall_arrayref('select * from simple3'),
	\@data,
	'simple3 data ok',
);
