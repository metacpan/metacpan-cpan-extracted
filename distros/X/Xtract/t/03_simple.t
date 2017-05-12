#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 22;
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use File::Remove          'clear';
use Xtract;
use Xtract::LZMA;

use constant LZMA => Xtract::LZMA->available;

# Prepare
my $from = catfile('t', 'data', 'Foo-Bar.sqlite');
my $to   = catfile('t', '03_simple_to');
ok( -f $from, 'Found --from file' );
clear($to, "$to.gz", "$to.bz2", "$to.lz");
ok( ! -f $to,       'Cleared --to file'  );
ok( ! -f "$to.gz",  'Cleared --gz file'  );
ok( ! -f "$to.bz2", 'Cleared --bz2 file' );
ok( ! -f "$to.lz",  'Cleared --lz file'  );





#####################################################################
# Basic Constructor

my $dsn = "DBI:SQLite:$from";
SCOPE: {
	# Constructor call
	my $object = Xtract->new(
		from  => $dsn,
		user  => '',
		pass  => '',
		to    => $to,
		index => 1,
		argv  => [ ],
	);
	isa_ok( $object, 'Xtract' );
	is( $object->from,  $dsn, '->from ok'  );
	is( $object->user,  '',   '->user ok'  );
	is( $object->pass,  '',   '->pass ok'  );
	is( $object->to,    $to,  '->to ok'    );
	is( $object->index, 1,    '->index ok' );
	is( $object->sqlite_cache, undef, '->sqlite_cache ok' );
	is( ref($object->argv), 'ARRAY', '->argv ok' );

	# Get the list of tables
	is_deeply(
		[ map { $_->name } $object->from_tables ],
		[ 'table_one' ],
		'->tables ok',
	);

	# Run the extraction
	ok( $object->run, '->run ok' );

	# Did we create the files we expected?
	my $publish = $object->publish;
	isa_ok( $publish, 'Xtract::Publish' );
	foreach my $file (
		$object->to,
		$publish->sqlite,
		$publish->sqlite_gz,
		$publish->sqlite_bz2,
	) {
		ok( -f $file, "Created '$file'" );
	}
	SKIP: {
		unless ( LZMA ) {
			skip("LZMA support not available", 1);
		}
		ok( -f $publish->sqlite_lz, "Created '" . $publish->sqlite_lz . "'"  );
	}
}
