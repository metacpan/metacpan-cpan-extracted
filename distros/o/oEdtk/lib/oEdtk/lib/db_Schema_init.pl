#!/usr/bin/perl
use strict;
use warnings;

use oEdtk::Config	qw(config_read);
use oEdtk::DBAdmin	qw(db_connect schema_Create);

my $cfg = config_read('EDTK_DB');
my $dbh = db_connect($cfg, 'EDTK_DBI_DSN');

if ($ARGV[0] =~/-h/i) {
	die "Usage : $0 \n\n\tThis create edtk database schema.\n";
}
schema_Create($dbh);
