#!/usr/bin/perl
#
# Unit tests for the PostgreSQL COPY bulk-load helpers of oEdtk::DBAdmin.
#
# These helpers are database-free: _pg_csv_row cleans and serializes a single
# record, and _pg_csv_supplier streams the cleaned file as COPY byte blocks.
# Both are exercised directly, so this file runs without a PostgreSQL server;
# t/test_csv_pg_copy.pl covers the actual PG round-trip when one is available.
#
# The whole file is pure ASCII on purpose: accented values are written as
# "\xE9" (the oEdtk modules expect ISO-8859 bytes), never as \x{...}.
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp qw(tempdir);
use Encode     qw(encode);
use TestOEdtk  qw(quiet_require);

quiet_require('oEdtk::DBAdmin');

# --- fixtures ---------------------------------------------------------------
my @cols          = qw(a b c d e);
my $blank_to_null = [ 0, 1, 0,  0, 0 ];    # b: numeric/date column => '' becomes NULL
my $col_size      = [ 5, 0, 10, 0, 0 ];    # a: text size 5, c: text size 10

my $dir = tempdir( 'oedtk_pg_unit_XXXXXX', CLEANUP => 1 );

sub write_csv {
	my ( $name, @rows ) = @_;
	my $file = "$dir/$name";
	open( my $fh, '>', $file ) or die "write_csv: $file: $!";
	binmode($fh);
	print $fh join( ',', @cols ), "\n";
	print $fh $_ for @rows;
	close($fh);
	return $file;
}

# --- _pg_csv_row : clean_val contract + RFC4180 serialization ----------------
is(
	oEdtk::DBAdmin::_pg_csv_row(
		[ 'LONGVALUE', '', 'x,y', undef, 'He said "hi"' ],
		\@cols, ',', '"', $blank_to_null, $col_size
	),
	'LONGV,,"x,y",,"He said ""hi"""',
	'_pg_csv_row truncates, turns a blank numeric into NULL, quotes sep/quote'
);

is(
	oEdtk::DBAdmin::_pg_csv_row(
		[ 'v', '', 'c', 'd', 'e' ],
		\@cols, ',', '"', $blank_to_null, $col_size
	),
	'v,,c,d,e',
	'_pg_csv_row keeps an empty non-numeric value as an (unquoted) empty field'
);

# --- _pg_csv_supplier : header skip, row count, single-block streaming -------
my $file  = write_csv( 'small.csv', "LONGVALUE,,\"x,y\",,\"He said \"\"hi\"\"\"\n", "v,,,,e\n" );
my $count = 0;
my $next  = oEdtk::DBAdmin::_pg_csv_supplier( $file, { sep_char => ',', quote_char => '"' },
	\@cols, $blank_to_null, $col_size, \$count, 'UTF-8' );
my ( $bytes, $blocks ) = ( '', 0 );
while ( defined( my $chunk = $next->() ) ) { $bytes .= $chunk; $blocks++; }

is( $count, 2, '_pg_csv_supplier counts the data rows (header excluded)' );
is(
	$bytes,
	"LONGV,,\"x,y\",\"\",\"He said \"\"hi\"\"\"\n" . "v,,\"\",\"\",e\n",
	'_pg_csv_supplier emits both cleaned rows and does not re-emit the header'
);
ok( $blocks >= 1, '_pg_csv_supplier yields at least one block' );

# --- multi-block streaming : rows stay intact across block boundaries --------
my $sz_none = [ 0, 0, 0, 0, 0 ];    # no truncation, so the round-trip is identity
my $pad     = 'X' x 180;
my $N       = 7000;                 # ~1.26 MB => more than one 1 MiB block
my @rows    = map { "$_," . join( ',', ($pad) x 4 ) . "\n" } 1 .. $N;
my $big     = write_csv( 'big.csv', @rows );
my $bc      = 0;
my $bnext   = oEdtk::DBAdmin::_pg_csv_supplier( $big, { sep_char => ',', quote_char => '"' },
	\@cols, $blank_to_null, $sz_none, \$bc, undef );
my ( $bb, $bn ) = ( '', 0 );
while ( defined( my $c = $bnext->() ) ) { $bb .= $c; $bn++; }

is( $bc, $N, "multi-block: all $N rows are counted" );
cmp_ok( $bn, '>', 1, 'multi-block: the stream is split into more than one block' );
ok(
	$bb =~ /^1,\Q$pad\E,/ && substr( $bb, -length( $rows[-1] ) ) eq $rows[-1],
	'multi-block: first and last rows are intact across block boundaries'
);

# --- encoding : a decoded accented char is encoded to client_encoding once ---
my $acc   = write_csv( 'acc.csv', encode( 'UTF-8', "caf\x{E9}" ) . ",,,,\n" );
my $ac    = 0;
my $anext = oEdtk::DBAdmin::_pg_csv_supplier( $acc, { sep_char => ',', quote_char => '"' },
	\@cols, $blank_to_null, $sz_none, \$ac, 'UTF-8' );
my $ab = '';
while ( defined( my $c = $anext->() ) ) { $ab .= $c; }
ok( index( $ab, encode( 'UTF-8', "caf\x{E9}" ) ) >= 0,
	'an accented value is UTF-8 encoded exactly once (no double-encode)' );

done_testing();
