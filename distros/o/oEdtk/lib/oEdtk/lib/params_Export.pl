#!/usr/bin/perl

use strict;
use warnings;

use Text::CSV;
use oEdtk::Main;
use oEdtk::Config	qw(config_read);
use oEdtk::DBAdmin	qw(db_connect);

if ($#ARGV < 1 or $ARGV[0] =~/-h/i) { 
	warn "Usage: $0 <table> <csv>\n\n";
	warn "\tThis extracts database params into csv file.\n";
	exit 1;
}

my ($table, $file) = @ARGV;

my $cfg = config_read('EDTK_DB');
my $dbh = db_connect($cfg, 'EDTK_DBI_PARAM',
    { AutoCommit => 1, RaiseError => 1 });

open(my $fh, ">", $file) or die "ERROR: can't open $file: $!\n";
my $csv = Text::CSV->new({ sep_char => ";", binary => 1 , eol => "\n" });

eval {
	# Get the column names.
	my $sth = $dbh->column_info(undef, undef, $table, '%'); #bon sous Oracle
	$sth->execute();
	my $cols = $dbh->selectcol_arrayref($sth, { Columns => [4] });

	$csv->print($fh, $cols);

	$sth = $dbh->prepare("SELECT * FROM $table");
	$sth->execute();
	while (my $row = $sth->fetchrow_hashref()) {
		my @vals = map { $row->{$_} } @$cols;
		$csv->print($fh, \@vals);
	}
};
if ($@) {
	warn "ERROR: $@\n";
}

$dbh->disconnect;
close($fh);
