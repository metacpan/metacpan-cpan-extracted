#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
BEGIN {
	$|  = 1;
}

use Test::More tests => 52;
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use File::Remove          'clear';
use Xtract::Publish;
use IO::Uncompress::Gunzip;
use IO::Uncompress::Bunzip2;

my $input = catfile( 't', 'data', 'Foo-Bar.sqlite' );
ok( -f $input, "Test file '$input' exists" );
my $output = catfile( 't', '04_publish_db' );
my @outputs =  map {
	$_, "$_.gz", "$_.bz2", "$_.lz"
} map {
	$_, "$_.tmp"
}( $output );
clear( @outputs );
foreach ( @outputs ) {
	ok( ! -f $_, "Output file '$_' is cleared" );
}

my $round_gz  = 'round.out';
my $round_bz2 = 'round.bz2';
clear( $round_gz, $round_bz2 );





######################################################################
# Main Tests

# Run the default publish process
SCOPE: {
	my $publish = new_ok( 'Xtract::Publish' => [
		sqlite => $output,
		from   => $input,
	] );
	is( $publish->raw,    1, '->raw is true'     );
	is( $publish->gz,     1, '->gz is true'      );
	is( $publish->bz2,    0, '->bz2 is false'    );
	is( $publish->lz,     0, '->lz is false'     );
	is( $publish->atomic, 0, '->atomic is false' );
	ok( defined $publish->write_sqlite, '->write_sqlite is true' );
	ok( defined $publish->write_gz, '->write_gz is true' );
	ok( ! defined($publish->write_bz2), '->write_bz2 is false' );
	ok( ! defined($publish->write_lz), '->write_lz is false' );

	ok( $publish->run, '->run ok' );
	ok(   -f $publish->sqlite, 'SQLite file exists' );
	ok(   -f $publish->sqlite_gz, 'gzip file exists' );
	ok( ! -f $publish->sqlite_bz2, 'bzip2 file does not exist' );
	ok( ! -f $publish->sqlite_lz, 'lzma file does not exist' );
	ok(   -f $publish->write_sqlite, 'write_sqlite exists' );
	ok(   -f $publish->write_gz, 'write_gz exists' );
	ok( ! defined $publish->write_bz2, 'write_bz2 does not exist' );
	ok( ! defined $publish->write_lz, 'write_lz does not exist' );

	# Extract the Gzip compressed files and make sure they round-trip
	ok( IO::Uncompress::Gunzip::gunzip(
		$publish->sqlite_gz => $round_gz,
		AutoClose          => 1,
		BinModeOut         => 1,
	), 'gunzip ok' );
	is(
		(stat($input))[7],
		(stat($round_gz))[7],
		'Source and round-trip file sizes match for gzip',
	);
}

# Run the opposite to the default
SCOPE: {
	my $publish = new_ok( 'Xtract::Publish' => [
		sqlite => $output,
		from   => $input,
		raw    => 0,
		gz     => 0,
		bz2    => 1,
		lz     => 1,
		atomic => 1,
	] );
	is( $publish->raw,    0, '->raw is false'   );
	is( $publish->gz,     0, '->gz is false'    );
	is( $publish->bz2,    1, '->bz2 is true'    );
	is( $publish->lz,     1, '->lz is true'     );
	is( $publish->atomic, 1, '->atomic is true' );
	ok( defined $publish->write_sqlite, '->write_sqlite is true' );
	ok( ! defined $publish->write_gz, '->write_gz is true' );
	ok( defined($publish->write_bz2), '->write_bz2 is false' );
	ok( defined($publish->write_lz), '->write_lz is false' );

	ok( $publish->run, '->run ok' );
	ok( ! -f $publish->sqlite, 'SQLite file exists' );
	ok( ! -f $publish->sqlite_gz, 'gzip file exists' );
	ok(   -f $publish->sqlite_bz2, 'bzip2 file does not exist' );
	ok(   -f $publish->sqlite_lz, 'lzma file does not exist' );
	ok( ! -f $publish->write_sqlite, 'write_sqlite exists' );
	ok( ! defined $publish->write_gz, 'write_gz exists' );
	ok( ! -f $publish->write_bz2, 'write_bz2 does not exist' );
	ok( ! -f $publish->write_lz, 'write_lz does exist' );

	# Extract the Bzip compress files and make sure they round-trip
	ok( IO::Uncompress::Bunzip2::bunzip2(
		$publish->sqlite_bz2 => $round_bz2,
		AutoClose           => 1,
		BinModeOut          => 1,
	), 'bunzip2 ok' );
	is(
		(stat($input))[7],
		(stat($round_bz2))[7],
		'Source and round-trip file sizes match for bzip2',
	);
}
