#!/usr/bin/perl
use strict;
use warnings;

use oEdtk::Main;
use oEdtk::Config	qw(config_read);
use oEdtk::DBAdmin	qw(db_connect);
use oEdtk::Tracking	qw(stats_week stats_iddest stats_month);
use List::MoreUtils	qw(uniq);

if (@ARGV < 1 or $ARGV[0] =~/-h/i) {
	warn "Usage : $0 [options]\n\n"
		."\t\tThis edits statistics from tracking table. Options are :\n"
		."\t\t monthly stats:\t month \t<start_date> [end_date] [\"excluded_ed_user, n\"]\n"
		."\t\t weekly stats :\t week \t<start_date> [end_date] [\"excluded_ed_user, n\"]\n"
		."\t\t iddest stats :\t iddest\t<start_date> <end_date> <\"excluded_ed_user, n\"> <ed_app> \n\n"
		."\t\t date are written like YYYYMMDDHHMMSS\n";
	exit 1;
}

my $cfg = config_read('EDTK_DB', 'EDTK_STATS');
my $dbh = db_connect($cfg, 'EDTK_DBI_STATS');

my ($stats, $colname, $colsize); # 

if ($ARGV[0] eq 'month') {
	$stats = stats_month($dbh, $cfg, $ARGV[1], $ARGV[2], $ARGV[3]);
	$colname = 'ED_MONTH';
	$colsize = 6;
} elsif ($ARGV[0] eq 'monthk') {
	$stats = stats_month($dbh, $cfg, $ARGV[1], $ARGV[2], $ARGV[3]);
	$colname = 'ED_MONTH';
	$colsize = 6;
} elsif ($ARGV[0] eq 'iddest') {
	$stats = stats_iddest($dbh, $cfg, $ARGV[1], $ARGV[2], $ARGV[3], $ARGV[4]);
	$colname = 'ED_WEEK';
	$colsize = 6;
} else {
	$stats = stats_week($dbh, $cfg, $ARGV[1], $ARGV[2], $ARGV[3]);
	$colname = 'ED_WEEK';
	$colsize = 6;
}

my @cols = sort(uniq(map { $_->{$colname} } @$stats));
my %week2col = ();
for my $i (0 .. $#cols) {
	$week2col{$cols[$i]} = $i;
}


my %data = ();
foreach my $row (@$stats) {
	my $line="";
	if ($colname eq 'ED_MONTH') {
		my $corp 	= $row->{'ED_CORP'} 	|| "";
		my $emet 	= $row->{'ED_EMET'} 	|| "";
		my $app  	= $row->{'ED_APP'} 		|| "";
		$line 	= "$corp\t$emet\t$app";

	} elsif ($colname eq 'ED_MONTH_K') {
		my $corp	= $row->{'ED_CORP'} 	|| "";
		my $emet	= $row->{'ED_EMET'} 	|| "";
		my $app	= $row->{'ED_APP'} 		|| "";
		my $k2	= $row->{'ED_K2_VAL'} 	|| "";
		my $k3	= $row->{'ED_K3_VAL'} 	|| "";
		$line	= "$corp\t$emet\t$app\t$k2\t$k3";

	} elsif ($ARGV[0] eq 'iddest'){
		my $corp	= $row->{'ED_CORP'} 	|| "";
		my $emet	= $row->{'ED_EMET'} 	|| "";
		my $app	= $row->{'ED_APP'} 		|| "";
		my $dest	= $row->{'ED_IDDEST'}	|| "";
		$line	= "$corp\t$emet\t$app\t$dest";	

	} else {
		my $corp	= $row->{'ED_CORP'} 	|| "";
		my $app	= $row->{'ED_APP'} 		|| "";
		$line	= "$corp\t$app";
	}
	if (!exists($data{$line})) {
		$data{$line} = [(0) x @cols];
	}
	$data{$line}->[$week2col{$row->{$colname}}] = $row->{'ED_COUNT'};
}


my $fmt = "%-${colsize}s\t" . ("%-${colsize}s\t" x @cols) . "\n";
printf($fmt, '', @cols);
foreach my $key (keys(%data)) {
	printf($fmt, $key, @{$data{$key}});
}
