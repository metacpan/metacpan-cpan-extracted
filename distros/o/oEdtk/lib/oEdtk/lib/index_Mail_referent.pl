#!/usr/bin/env perl

use strict;
use warnings;

use oEdtk::DBAdmin	qw(db_connect);
use oEdtk::Config	qw(config_read);
use oEdtk::Outmngr	qw(omgr_stats_referent);
use oEdtk::Messenger qw(oe_send_mail);


if ($ARGV[0] =~/-h/i) {
	warn "Usage : $0\n\n";
	warn "\tThis runs statistics and sends mail to referent for approval request.\n";
	exit 1;
}


# run statistics and send the advertissement by mail. 
my $cfg = config_read('EDTK_DB', 'MAIL');
my $dbh = db_connect($cfg, 'EDTK_DBI_DSN',
    { AutoCommit => 1, RaiseError => 1 });
my $pdbh = db_connect($cfg, 'EDTK_DBI_PARAM');

my $rows = omgr_stats_referent($dbh, $pdbh);

if ($#$rows<0) {
	my $subject="INFO : pas de validation de lot prevue dans la base de lotissement.\n";
	oe_send_mail($cfg->{'EDTK_MAIL_SENDER'}, $subject, $subject);
	warn $subject;
	exit;
}

my %hMail;
foreach my $mail (@$rows) {
	my $corp = @$mail[2] || " ";
	$hMail{@$mail[0]} .= @$mail[1]."\t". $corp ."\n " ;	
	warn "INFO : edition(s) en attente \n ". $hMail{@$mail[0]} ."\n";
}


foreach my $MAIL_TO (keys %hMail){
	my $mailfile = $cfg->{'EDTK_MAIL_REFER'};
	open(my $fh, '<', $mailfile) or die "ERROR: Cannot open \"$mailfile\": $!\n";
	my @body = <$fh>;
	close($fh);

	push (@body, $hMail{$MAIL_TO});
	
	if ($MAIL_TO!~/\@/){
		$MAIL_TO = $cfg->{$MAIL_TO};
	}

	my ($sec,$min,$hour,$day,$month,$year) = localtime();
	my $date = sprintf("%02d/%02d/%d", $day, $month + 1, $year + 1900);
	my $time = sprintf("%02d:%02d:%02d", $hour, $min, $sec);

	my $subject = $cfg->{'EDTK_MAIL_SUBJ'};
	$subject =~ s/%date/$date/;
	$subject =~ s/%time/$time/;

	oe_send_mail($MAIL_TO, $subject, @body);
}