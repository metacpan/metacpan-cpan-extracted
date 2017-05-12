#!/usr/bin/perl

use strict;
use warnings;
use oEdtk;
use oEdtk::Main;
use oEdtk::Config 		qw(config_read);
use oEdtk::DBAdmin 		qw(db_connect csv_import);
my $header='ED_SEQLOT,ED_LOTNAME,ED_DTPRINT,ED_DTPOST,ED_NBFACES,ED_NBPLIS,ED_DTPOST2';


if (@ARGV < 1 or $ARGV[0] =~/-h/i) {
	warn "Usage: $0 <acq_file>\n";
	warn "\n\tThis will import csv acq file into acq table.\n";
	warn "\tcsv import file should have this structure :\n $header\n";
	exit 1;
}

my $cfg = config_read('EDTK_DB');
my $dbh = db_connect($cfg, 'EDTK_DBI_DSN',
    { AutoCommit => 1, RaiseError => 1 });

csv_import($dbh, "EDTK_ACQ", $ARGV[0], 
			{ 	mode => 'merge', 
				header => $header 
			});

1;