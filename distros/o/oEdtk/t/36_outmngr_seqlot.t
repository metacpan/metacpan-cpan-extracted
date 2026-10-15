#!/usr/bin/perl
#
# Tests for the lot-sequence generation (_get_seqlot) of oEdtk::Outmngr when
# SQLite is the main database. SQLite has no SEQUENCE, so oEdtk::DBAdmin
# emulates EDTK_IDLOT with the edtk_idlot_seq counter table (create_lot_sequence,
# called by schema_Create) and _get_seqlot reads it back.
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Test::More;
use DBI;
use File::Temp     qw(tempdir);
use Date::Calc     qw(Today Week_of_Year Day_of_Week);
use oEdtk::DBAdmin qw(schema_Create);
use oEdtk::Outmngr ();

my $dir  = tempdir( 'oedtk_seqlot_XXXXXX', CLEANUP => 1 );
my $file = "$dir/main.db";
my $dbh  = DBI->connect( "dbi:SQLite:dbname=$file", '', '',
	{ RaiseError => 1, PrintError => 0, AutoCommit => 1 } );

schema_Create($dbh);

# The counter table must exist and hold a single row.
ok(
	oEdtk::DBAdmin::_table_exists( $dbh, 'edtk_idlot_seq' ),
	'schema_Create creates edtk_idlot_seq on SQLite'
);
my ($nrows) = $dbh->selectrow_array('select count(*) from edtk_idlot_seq');
is( $nrows, 1, 'edtk_idlot_seq starts with exactly one row' );

# Expected prefix: ISO week (2 digits) + day-of-week (1 digit), computed in Perl.
my ( $y, $m, $d ) = Today();
my ($week) = Week_of_Year( $y, $m, $d );
my $prefix = sprintf( '%02d%d', $week, Day_of_Week( $y, $m, $d ) );

my $a = oEdtk::Outmngr::_get_seqlot($dbh);
my $b = oEdtk::Outmngr::_get_seqlot($dbh);
like( $a, qr/^\d{6}$/, '_get_seqlot: 6-digit lot id on SQLite' );
is( substr( $a, 0, 3 ), $prefix,            '_get_seqlot: ISO week + day-of-week prefix' );
is( substr( $a, 0, 3 ), substr( $b, 0, 3 ), '_get_seqlot: stable prefix within the same day' );
is( int( substr( $b, -3 ) ) - int( substr( $a, -3 ) ),
	1, '_get_seqlot: sequence increments by one' );

# Re-running schema_Create must not reset the counter (idempotent setup).
schema_Create($dbh);
my $c = oEdtk::Outmngr::_get_seqlot($dbh);
is( int( substr( $c, -3 ) ) - int( substr( $b, -3 ) ),
	1, 'schema_Create does not reset the sequence' );

# Wrapping: force the counter near the top of the range.
$dbh->do('update edtk_idlot_seq set id_val = 999');
my $wrapped = oEdtk::Outmngr::_get_seqlot($dbh);
is( substr( $wrapped, -3 ), '000', '_get_seqlot: wraps 999 -> 000 (modulo 1000)' );

$dbh->disconnect;
done_testing();
