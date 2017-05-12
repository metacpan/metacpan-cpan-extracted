#!/usr/bin/perl

use strict;
use warnings;

use oEdtk::Main;
use oEdtk::Config	qw(config_read);
use oEdtk::DBAdmin	qw(db_connect);
use oEdtk::Outmngr	qw(omgr_check_seqlot_ref);

if (@ARGV < 1 or $ARGV[0] =~/-h/i) {
	warn "Usage: $0 <seqlot_ref|idldoc_ref [idseqpg_ref]>\n\n";
	warn "\tThis looks statitics for checked docs in output manager (index db)\n";
	exit 1;
}

my $cfg = config_read('EDTK_STATS');
my $dbh = db_connect($cfg, 'EDTK_DBI_STATS',
    { AutoCommit => 1, RaiseError => 1 });

my $rows = omgr_check_seqlot_ref($dbh, $ARGV[0], $ARGV[1]);

if ($#$rows<0) {
	warn "INFO : pas de donnees associees.\n";
	exit;
}

my $fmt  = shift (@$rows);
my $head = shift (@$rows);
printf $$fmt . "\n", @$head; 

foreach my $row (@$rows) {
	printf $$fmt . "\n", @$row;
}

