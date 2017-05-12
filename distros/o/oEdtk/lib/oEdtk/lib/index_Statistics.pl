#!/usr/bin/perl

use strict;
use warnings;

use oEdtk::Main;
use oEdtk::Config 		qw(config_read);
use oEdtk::DBAdmin 		qw(db_connect);
use oEdtk::Outmngr 	0.8011 qw(omgr_stats);
use Text::CSV;

if (@ARGV < 1 or $ARGV[0] =~/-h/i) {
	warn "Usage: $0 <day|week|all|value> <idlot|idgplot> [file]\n";
	warn "\n\t where 'value' has the format ywwd (one or more numbers like 2521 or 252)\n";
	exit 1;
}

my $cfg = config_read('EDTK_STATS');
my $dbh = db_connect($cfg, 'EDTK_DBI_STATS',
    { AutoCommit => 1, RaiseError => 1 });
my $pdbh = db_connect($cfg, 'EDTK_DBI_STATS');

my $rows = omgr_stats($dbh, $pdbh, $ARGV[0], $ARGV[1]||"idlot");
my $fmt  = shift (@$rows);
my $head = shift (@$rows);

if ($#$rows<0) {
	warn "INFO : pas de statistiques pour cette periode.\n";
	exit;
}

#my @cols;
#if (defined($ARGV[1]) && $ARGV[1]!~/idlot/i) {
#	@cols = ("LOT", "CORP", "PLIS", "DOCS", "FEUILLES", "PAGES", "FACES", "MODEDI ");
#} else {
#	@cols = ("LOT", "CORP", "ID_LOT", "PLIS", "DOCS", "FEUILLES", "PAGES", "FACES", "FIL.");
#}

# If an output file was given on the command line, we dump the data in
# the given file in CSV format.
if (defined($ARGV[2]) && length($ARGV[2]) > 0) {
	open(my $fh, ">$ARGV[2]") or die "ERROR: can't open $ARGV[2] : $!";
	my $csv = Text::CSV->new({ binary => 1, eol => "\n" });
	$csv->print($fh, $head);
	foreach my $row (@$rows) {
		$csv->print($fh, $row);
	}
	close($fh);
	exit;
}

# Otherwise, we output in a human-readable way.
printf($$fmt, @$head);
foreach my $row (@$rows) {
	printf($$fmt, @$row);
}
