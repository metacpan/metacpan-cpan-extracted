#!/usr/bin/env perl

use strict;
use warnings;

use oEdtk::Config		qw(config_read);
use oEdtk::DBAdmin		qw(db_connect);
use oEdtk::Messenger	qw(oe_send_mail);
use oEdtk::Outmngr		qw(omgr_stats);
use oEdtk::Run			qw(oe_outmngr_output_run_tex);

my $cfg = config_read('EDTK_DB', 'MAIL');

if (@ARGV % 2 != 0 or $ARGV[0] =~/-h/i) {
	warn "Odd number of parameters.\n" if ($ARGV[0] !~/-h/i);
	warn "usage: $0 [<column> <value>]...\n";
	warn "\n\tthis run outmanagement from index table and doclibs\n";
	exit 1;
}


	my @lots =oe_outmngr_output_run_tex({ @ARGV }, 'Mass');
	
	if (@lots == 0) {
		my $sujet = "INFO : Aucun lot en attente de traitement\n";
		my @body = ("traitement de lotissement effectué sur ", $cfg->{'EDTK_TYPE_ENV'}, " ($0), aucun lot en attente.");
		oe_send_mail($cfg->{'EDTK_MAIL_SENDER'} ,$sujet ,@body);
		warn $sujet;
		exit;
	}
	
	# Now, run statistics and send the output by mail.
	my $dbh = db_connect($cfg, 'EDTK_DBI_DSN',
	    { AutoCommit => 1, RaiseError => 1 });
	my $pdbh = db_connect($cfg, 'EDTK_DBI_PARAM');
	
	my $rows = omgr_stats($dbh, $pdbh, 'day', 'idlot');
	my $fmt  = shift (@$rows);
	my $head = shift (@$rows);
	
	my $mailfile = $cfg->{'EDTK_MAIL_OMGR'};
	open(my $fh, '<', $mailfile) or die "ERROR: Cannot open \"$mailfile\": $!\n";
	my @body = <$fh>;
	close($fh);
	
	push(@body, "\n\n\n");
	push(@body, sprintf($$fmt, @$head));
	foreach my $row (@$rows) {
		push(@body, sprintf($$fmt, @$row));
	}
	
	my ($sec,$min,$hour,$day,$month,$year) = localtime();
	my $date = sprintf("%02d/%02d/%d", $day, $month + 1, $year + 1900);
	my $time = sprintf("%02d:%02d:%02d", $hour, $min, $sec);
	
	my $subject .= $cfg->{'EDTK_MAIL_SUBJ'};
	$subject =~ s/%date/$date/;
	$subject =~ s/%time/$time/;

	oe_send_mail($cfg->{'EDTK_MAIL_TO'}, $subject, @body);
