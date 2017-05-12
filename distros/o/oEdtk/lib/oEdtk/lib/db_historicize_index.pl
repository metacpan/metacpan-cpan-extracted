#!/usr/bin/perl

use oEdtk::Config	qw(config_read);
use oEdtk::DBAdmin	qw(db_connect historicize_table);
use Term::ReadKey;
use POSIX		qw(strftime);
use warnings;
use strict;

my $cfg = config_read('EDTK_DB');
my $dbh = db_connect($cfg, 'EDTK_DBI_DSN');
my $suffixe =strftime "%Y%m%d%H%M%S", localtime;
my $wait_time =30*$cfg->{'EDTK_WAITRUN'} || 600;

warn "INFO : historicize index table\n";
warn "INFO : table should not be in use\n";
warn "INFO : waiting $wait_time sec... press 'N' or 'S' to stop or any to run\n";

ReadMode('raw');
my $key = ReadKey($wait_time);
if 		($key=~/^[ns]$/i) {
	die "INFO : abort request\n";
}
ReadMode ('restore');

historicize_table($dbh, $cfg->{'EDTK_DBI_OUTMNGR'}, $suffixe);

warn "INFO : backup done for ".$cfg->{'EDTK_DBI_OUTMNGR'}."\n";
