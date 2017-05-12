#!/usr/bin/perl

use strict;
use warnings;

use oEdtk::Main;
use oEdtk::Config	qw(config_read);
use oEdtk::DBAdmin	qw(db_connect);
use oEdtk::Outmngr	qw(omgr_depot_poste);

if (@ARGV < 2 or $ARGV[0] =~/-h/i) {
	warn "Usage: $0 <idldoc> <yyyymmdd>\n\n or for a range of values $0 <nnn%> <yyyymmdd>\n\n";
	warn "\tThis loads post date for idldoc.\n";
	exit 1;
}


my $cfg = config_read('EDTK_DB');
my $dbh = db_connect($cfg, 'EDTK_DBI_STATS',
    { AutoCommit => 1, RaiseError => 1 });

omgr_depot_poste($dbh, $ARGV[0], $ARGV[1]);
