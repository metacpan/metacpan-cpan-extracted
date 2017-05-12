#!/usr/bin/perl

use strict;
use warnings;

use Text::CSV;
use oEdtk::Main;
use oEdtk::Config	qw(config_read);
use oEdtk::DBAdmin	qw(db_connect);

if ($#ARGV < 1 or $ARGV[0] =~/-h/i) {
	die "\nUsage: $0 <table> <csv> [INI_SECTION]\n"
		."\n\t\twhere INI_SECTION is a configuration section in edtk.ini\n"
		."\t\t\t(usefull to load params in Prod, Dev, or other environnement)\n\n";
	exit 1;
}

my ($table, $file) = @ARGV;
my $section = shift || "";
my $DBI = 'EDTK_DBI_PARAM';
		$DBI = 'EDTK_DBI_DSN' if ($section ne "");

open(my $fh, "<", $file) or die "ERROR: can't open $file: $!\n";
my $csv = Text::CSV->new({ sep_char => ';', binary => 1 });

my $cfg = config_read('EDTK_DB', $section);
my $dbh = db_connect($cfg, $DBI,
    { AutoCommit => 0, RaiseError => 1 });

# Set the column names.
$csv->column_names($csv->getline($fh));

eval {
	if ($dbh->{'Driver'}->{'Name'} eq 'SQLite') {
		$dbh->do("DELETE FROM $table");
	} else {
		$dbh->do("TRUNCATE TABLE $table");
	}

	while (my $row = $csv->getline_hr($fh)) {
		my $sql = "INSERT INTO $table (" . join(', ', keys(%$row)) 
				. ") VALUES (" . join(', ', ('?') x keys(%$row)) . ")";
		$dbh->do($sql, undef, values(%$row));
	}
	$dbh->commit;
};
if ($@) {
	warn "ERROR: $@\n";
	eval { $dbh->rollback };
}

$dbh->disconnect;
close($fh);
