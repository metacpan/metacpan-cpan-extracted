#!/usr/bin/perl
use oEdtk;
use oEdtk::Config  qw(config_read);
use oEdtk::DBAdmin qw(db_connect move_table);
use warnings;
use strict;

if ( @ARGV < 2 or $ARGV[0] =~ /-h/i ) {
	die "Usage: $0 table_source table_cible [-create]\n";
}

my $cfg = config_read('EDTK_DB');
my $dbh = db_connect( $cfg, 'EDTK_DBI_DSN' );

warn "INFO: data from $ARGV[0] will be inserted in $ARGV[1]\n";

move_table( $dbh, $ARGV[0], $ARGV[1], $ARGV[2] );

warn "INFO: insert done into $ARGV[1]\n";
