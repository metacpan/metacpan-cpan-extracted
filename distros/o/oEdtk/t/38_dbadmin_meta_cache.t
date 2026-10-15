#!/usr/bin/perl
#
# Tests for db_invalidate_meta_cache(), the public hook that drops the column
# metadata cached by csv_import (via _get_col_meta, keyed by table + driver).
# schema_Create and schema_Upgrade call it so that, after a schema change, the
# next import re-reads the columns instead of reusing a stale description.
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Test::More;
use DBI;
use oEdtk::DBAdmin qw(db_invalidate_meta_cache);

ok( oEdtk::DBAdmin->can('db_invalidate_meta_cache'), 'db_invalidate_meta_cache is exported' );

my $dbh = DBI->connect( 'dbi:SQLite:dbname=:memory:', '', '',
	{ RaiseError => 1, PrintError => 0, AutoCommit => 1 } );
$dbh->do('create table tmeta (a integer, b varchar(10))');

my $norm = sub { uc $_[0] };

# Fresh process: the cache starts empty.
is( scalar( keys(%oEdtk::DBAdmin::_csv_import_type_cache) ), 0, 'cache starts empty' );

# Reading column metadata populates the cache.
my $meta = oEdtk::DBAdmin::_get_col_meta( $dbh, 'tmeta', $norm );
is( ref $meta, 'HASH', '_get_col_meta returns a hash ref' );
cmp_ok( scalar( keys(%oEdtk::DBAdmin::_csv_import_type_cache) ),
	'>', 0, '_get_col_meta populates the cache' );

# Invalidation empties it.
is( db_invalidate_meta_cache(), 1, 'db_invalidate_meta_cache returns true' );
is( scalar( keys(%oEdtk::DBAdmin::_csv_import_type_cache) ), 0, 'cache is emptied' );

# A subsequent read re-populates it (fresh column_info).
oEdtk::DBAdmin::_get_col_meta( $dbh, 'tmeta', $norm );
cmp_ok( scalar( keys(%oEdtk::DBAdmin::_csv_import_type_cache) ),
	'>', 0, 'cache can be repopulated after invalidation' );

$dbh->disconnect;
done_testing();
